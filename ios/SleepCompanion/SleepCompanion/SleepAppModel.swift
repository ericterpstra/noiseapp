import Foundation
import SwiftUI

@MainActor
final class SleepAppModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var currentDate: Date
    @Published var isPlaying: Bool
    @Published var isWakeActive: Bool
    @Published var isShowingSettings: Bool
    @Published var settingsDraft: SettingsDraft?
    @Published var isPreviewingDraftAudio: Bool

    private let store: AppSettingsStore
    private let audioEngine: SleepAudioEngine
    private var clockTask: Task<Void, Never>?
    private var activeWakeDate: Date?
    private var wasPlayingBeforeDraftPreview = false
    private var parametersBeforeDraftPreview: SoundParameters?

    init(
        store: AppSettingsStore = .appDefault,
        audioEngine: SleepAudioEngine = SleepAudioEngine()
    ) {
        self.store = store
        self.audioEngine = audioEngine
        let loadedSettings = (try? store.load()) ?? .default
        self.settings = loadedSettings
        self.currentDate = Date()
        self.isPlaying = false
        self.isWakeActive = loadedSettings.hasCompletedWakeTransition
        self.isShowingSettings = false
        self.settingsDraft = nil
        self.isPreviewingDraftAudio = false
        self.activeWakeDate = loadedSettings.wakeTime.nextOccurrence(after: Date())
    }

    var currentPreset: SoundPresetDefinition {
        SoundPresetDefinition.bundledPresets.first { $0.id == settings.activeSoundPresetID }
            ?? SoundPresetDefinition.defaultPreset
    }

    var clockText: String {
        Self.clockFormatter.string(from: currentDate).lowercased()
    }

    func startClock() {
        guard clockTask == nil else {
            return
        }

        UIApplication.shared.isIdleTimerDisabled = true
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stopClock() {
        clockTask?.cancel()
        clockTask = nil
    }

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    func startPlayback() {
        do {
            try audioEngine.start(parameters: settings.activeSoundParameters)
            isPlaying = true
        } catch {
            isPlaying = false
            assertionFailure("Unable to start sleep audio: \(error)")
        }
    }

    func stopPlayback() {
        audioEngine.stop()
        isPlaying = false
    }

    func selectPreset(id: String) {
        guard let preset = SoundPresetDefinition.bundledPresets.first(where: { $0.id == id }) else {
            return
        }

        settings.activeSoundPresetID = preset.id
        settings.activeSoundParameters = preset.parameters
        audioEngine.update(parameters: preset.parameters)
        persist()
    }

    func beginSettings() {
        settingsDraft = SettingsDraft(settings: settings)
        isShowingSettings = true
    }

    func cancelSettingsDraft() {
        if isPreviewingDraftAudio {
            stopDraftPreview()
        }

        settingsDraft = nil
        isShowingSettings = false
    }

    func applySettingsDraft() {
        guard let draft = settingsDraft else {
            isShowingSettings = false
            return
        }

        settings = draft.appliedSettings()
        isWakeActive = settings.hasCompletedWakeTransition
        activeWakeDate = settings.wakeTime.nextOccurrence(after: Date())

        if isPreviewingDraftAudio {
            isPreviewingDraftAudio = false
            parametersBeforeDraftPreview = nil
            wasPlayingBeforeDraftPreview = false
            isPlaying = true
            audioEngine.update(parameters: settings.activeSoundParameters)
        } else if isPlaying {
            audioEngine.update(parameters: settings.activeSoundParameters)
        }

        settingsDraft = nil
        persist()
        isShowingSettings = false
    }

    func selectDraftPreset(id: String) {
        guard var draft = settingsDraft else {
            return
        }

        draft.selectSoundPreset(id: id)
        settingsDraft = draft
        updateDraftPreviewIfNeeded()
    }

    func setDraftSoundParameter(_ id: SoundParameterID, value: Double) {
        guard var draft = settingsDraft else {
            return
        }

        draft.setSoundParameter(id, value: value)
        settingsDraft = draft
        updateDraftPreviewIfNeeded()
    }

    func setDraftClockFace(_ clockFace: ClockFaceSettings) {
        guard var draft = settingsDraft else {
            return
        }

        draft.setClockFace(clockFace)
        settingsDraft = draft
    }

    func setDraftWakeTime(_ wakeTime: WakeTime) {
        guard var draft = settingsDraft else {
            return
        }

        draft.setWakeTime(wakeTime)
        settingsDraft = draft
    }

    func toggleDraftPreview() {
        if isPreviewingDraftAudio {
            stopDraftPreview()
        } else {
            startDraftPreview()
        }
    }

    func startDraftPreview() {
        guard let draft = settingsDraft else {
            return
        }

        if !isPreviewingDraftAudio {
            wasPlayingBeforeDraftPreview = isPlaying
            parametersBeforeDraftPreview = settings.activeSoundParameters
        }

        do {
            try audioEngine.start(parameters: draft.settings.activeSoundParameters)
            isPlaying = true
            isPreviewingDraftAudio = true
        } catch {
            isPreviewingDraftAudio = false
            assertionFailure("Unable to start draft preview: \(error)")
        }
    }

    func stopDraftPreview() {
        guard isPreviewingDraftAudio else {
            return
        }

        isPreviewingDraftAudio = false

        if wasPlayingBeforeDraftPreview, let parametersBeforeDraftPreview {
            do {
                try audioEngine.start(parameters: parametersBeforeDraftPreview)
                isPlaying = true
            } catch {
                isPlaying = false
                assertionFailure("Unable to restore sleep audio after preview: \(error)")
            }
        } else {
            stopPlayback()
        }

        wasPlayingBeforeDraftPreview = false
        self.parametersBeforeDraftPreview = nil
    }

    func setWakeTime(_ wakeTime: WakeTime) {
        settings.wakeTime = wakeTime
        settings.hasCompletedWakeTransition = false
        isWakeActive = false
        activeWakeDate = wakeTime.nextOccurrence(after: Date())
        persist()
    }

    func setClockFont(_ fontID: ClockFontID) {
        settings.clockFace.fontID = fontID
        persist()
    }

    func setClockColor(_ colorHex: String) {
        settings.clockFace.colorHex = colorHex
        persist()
    }

    func setClockSize(_ size: Double) {
        settings.clockFace = ClockFaceSettings(
            fontID: settings.clockFace.fontID,
            colorHex: settings.clockFace.colorHex,
            size: size,
            luminosity: settings.clockFace.luminosity
        )
        persist()
    }

    func setLuminosity(_ luminosity: Double) {
        settings.clockFace = ClockFaceSettings(
            fontID: settings.clockFace.fontID,
            colorHex: settings.clockFace.colorHex,
            size: settings.clockFace.size,
            luminosity: luminosity
        )
    }

    func adjustLuminosity(by delta: Double) {
        setWakeActive(false)
        setLuminosity(settings.clockFace.luminosity + delta)
    }

    func setWakeActive(_ isActive: Bool) {
        isWakeActive = isActive
        settings.hasCompletedWakeTransition = isActive

        if isActive {
            settings.clockFace = ClockFaceSettings(
                fontID: settings.clockFace.fontID,
                colorHex: settings.clockFace.colorHex,
                size: settings.clockFace.size,
                luminosity: 1
            )
        }

        persist()
    }

    func persist() {
        try? store.save(settings)
    }

    private func tick() {
        currentDate = Date()

        guard let activeWakeDate else {
            return
        }

        if currentDate >= activeWakeDate, !isWakeActive {
            runWakeTransition()
        }
    }

    private func runWakeTransition() {
        stopPlayback()
        setWakeActive(true)
        activeWakeDate = settings.wakeTime.nextOccurrence(after: currentDate)
    }

    private func updateDraftPreviewIfNeeded() {
        guard isPreviewingDraftAudio, let draft = settingsDraft else {
            return
        }

        audioEngine.update(parameters: draft.settings.activeSoundParameters)
    }

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter
    }()
}

extension AppSettingsStore {
    static var appDefault: AppSettingsStore {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("SleepCompanion", isDirectory: true)
            ?? FileManager.default.temporaryDirectory

        return AppSettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
    }
}
