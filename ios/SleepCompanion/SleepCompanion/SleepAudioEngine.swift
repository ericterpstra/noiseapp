import AVFoundation
import Foundation

final class SleepAudioEngine {
    private let engine = AVAudioEngine()
    private let eq = AVAudioUnitEQ(numberOfBands: 4)
    private var sourceNode: AVAudioSourceNode?
    private var renderBox: SleepToneRenderBox?

    func start(parameters: SoundParameters) throws {
        let parameters = parameters.clamped()

        if engine.isRunning {
            update(parameters: parameters)
            return
        }

        try configureAudioSession()
        configureGraphIfNeeded(parameters: parameters)
        update(parameters: parameters)
        try engine.start()
    }

    func stop() {
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func update(parameters: SoundParameters) {
        let parameters = parameters.clamped()
        renderBox?.update(parameters: parameters)
        engine.mainMixerNode.outputVolume = Float(pow(parameters.level, 2) * 0.9)

        eq.bands[0].frequency = Float(FrequencyMapping.logFrequency(value: parameters.lowCut, min: 20, max: 1_500))
        eq.bands[1].frequency = Float(FrequencyMapping.logFrequency(value: parameters.highCut, min: 1_200, max: 20_000))
        eq.bands[2].gain = Float(parameters.warmth * 5)
        eq.bands[3].gain = Float(parameters.warmth * -8)
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    private func configureGraphIfNeeded(parameters: SoundParameters) {
        guard sourceNode == nil else {
            return
        }

        let outputFormat = engine.outputNode.inputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 48_000
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let renderBox = SleepToneRenderBox(sampleRate: sampleRate, parameters: parameters)
        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            renderBox.render(frameCount: frameCount, audioBufferList: audioBufferList)
        }

        configureEQ()
        engine.attach(sourceNode)
        engine.attach(eq)
        engine.connect(sourceNode, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)
        engine.prepare()

        self.renderBox = renderBox
        self.sourceNode = sourceNode
    }

    private func configureEQ() {
        eq.bands[0].filterType = .highPass
        eq.bands[0].bypass = false
        eq.bands[0].bandwidth = 0.707

        eq.bands[1].filterType = .lowPass
        eq.bands[1].bypass = false
        eq.bands[1].bandwidth = 0.707

        eq.bands[2].filterType = .lowShelf
        eq.bands[2].frequency = 220
        eq.bands[2].bypass = false

        eq.bands[3].filterType = .highShelf
        eq.bands[3].frequency = 2_600
        eq.bands[3].bypass = false
    }
}

private final class SleepToneRenderBox {
    private let lock = NSLock()
    private var renderer: SleepToneDSP.ChannelRenderer
    private var parameters: SoundParameters

    init(sampleRate: Double, parameters: SoundParameters) {
        self.renderer = SleepToneDSP.ChannelRenderer(sampleRate: sampleRate)
        self.parameters = parameters.clamped()
    }

    func update(parameters: SoundParameters) {
        lock.lock()
        self.parameters = parameters.clamped()
        lock.unlock()
    }

    func render(
        frameCount: AVAudioFrameCount,
        audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus {
        lock.lock()
        defer { lock.unlock() }

        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let frames = Int(frameCount)

        for frame in 0..<frames {
            let sample = renderer.nextSample(parameters: parameters)

            if buffers.count == 1, buffers[0].mNumberChannels == 2 {
                let data = buffers[0].mData!.assumingMemoryBound(to: Float.self)
                data[frame * 2] = Float(sample.left)
                data[frame * 2 + 1] = Float(sample.right)
                continue
            }

            for bufferIndex in buffers.indices {
                let data = buffers[bufferIndex].mData!.assumingMemoryBound(to: Float.self)
                data[frame] = Float(bufferIndex == 0 ? sample.left : sample.right)
            }
        }

        return noErr
    }
}
