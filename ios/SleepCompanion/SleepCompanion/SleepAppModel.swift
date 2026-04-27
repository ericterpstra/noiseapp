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
    @Published var savedPresetLibrary: SavedPresetLibrary

    private let store: AppSettingsStore
    private let savedPresetStore: SavedPresetStore
    private let audioEngine: SleepAudioEngine
    private var clockTask: Task<Void, Never>?
    private var activeWakeDate: Date?
    private var wasPlayingWhenSettingsOpened = false

    init(
        store: AppSettingsStore = .appDefault,
        savedPresetStore: SavedPresetStore = .appDefault,
        audioEngine: SleepAudioEngine = SleepAudioEngine()
    ) {
        self.store = store
        self.savedPresetStore = savedPresetStore
        self.audioEngine = audioEngine
        let loadedSavedPresetLibrary = (try? savedPresetStore.load()) ?? SavedPresetLibrary()
        var loadedSettings = (try? store.load()) ?? .default
        if let activeSavedPresetID = loadedSettings.activeSavedPresetID,
           !Self.savedPreset(activeSavedPresetID, matches: loadedSettings, in: loadedSavedPresetLibrary) {
            loadedSettings.activeSavedPresetID = nil
        }
        self.settings = loadedSettings
        self.currentDate = Date()
        self.isPlaying = false
        self.isWakeActive = loadedSettings.hasCompletedWakeTransition
        self.isShowingSettings = false
        self.settingsDraft = nil
        self.savedPresetLibrary = loadedSavedPresetLibrary
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
        settings.activeSavedPresetID = nil
        settings.activeSoundParameters = preset.parameters
        audioEngine.update(parameters: preset.parameters)
        persist()
    }

    func beginSettings() {
        wasPlayingWhenSettingsOpened = isPlaying
        settingsDraft = SettingsDraft(settings: settings)
        isShowingSettings = true
    }

    func cancelSettingsDraft() {
        if wasPlayingWhenSettingsOpened, isPlaying {
            audioEngine.update(parameters: settings.activeSoundParameters)
        }

        wasPlayingWhenSettingsOpened = false
        settingsDraft = nil
        isShowingSettings = false
    }

    func applySettingsDraft() {
        guard let draft = settingsDraft else {
            isShowingSettings = false
            return
        }

        settings = draft.appliedSettings()
        if let activeSavedPresetID = settings.activeSavedPresetID,
           !Self.savedPreset(activeSavedPresetID, matches: settings, in: savedPresetLibrary) {
            settings.activeSavedPresetID = nil
        }
        isWakeActive = settings.hasCompletedWakeTransition
        activeWakeDate = settings.wakeTime.nextOccurrence(after: Date())

        if isPlaying {
            audioEngine.update(parameters: settings.activeSoundParameters)
        }

        wasPlayingWhenSettingsOpened = false
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
        updateDraftPlaybackIfNeeded()
    }

    func loadSavedPresetIntoDraft(id: String) {
        guard var draft = settingsDraft,
              let preset = savedPresetLibrary.preset(id: id) else {
            return
        }

        draft.loadSavedPreset(preset)
        settingsDraft = draft
        updateDraftPlaybackIfNeeded()
    }

    @discardableResult
    func saveDraftAsPreset(title: String, description: String) -> SavedPresetDefinition? {
        guard var draft = settingsDraft else {
            return nil
        }

        let preset = savedPresetLibrary.create(
            title: normalizedPresetTitle(title),
            description: normalizedPresetDescription(description),
            from: draft.settings
        )
        draft.loadSavedPreset(preset)
        settingsDraft = draft
        persistSavedPresetLibrary()
        updateDraftPlaybackIfNeeded()
        return preset
    }

    @discardableResult
    func updateSavedPreset(id: String) -> SavedPresetDefinition? {
        guard var draft = settingsDraft,
              let preset = savedPresetLibrary.update(id: id, from: draft.settings) else {
            return nil
        }

        draft.loadSavedPreset(preset)
        settingsDraft = draft
        persistSavedPresetLibrary()
        updateDraftPlaybackIfNeeded()
        return preset
    }

    @discardableResult
    func renameSavedPreset(id: String, title: String, description: String) -> SavedPresetDefinition? {
        let preset = savedPresetLibrary.rename(
            id: id,
            title: normalizedPresetTitle(title),
            description: normalizedPresetDescription(description)
        )
        persistSavedPresetLibrary()
        return preset
    }

    @discardableResult
    func duplicateSavedPreset(id: String) -> SavedPresetDefinition? {
        let preset = savedPresetLibrary.duplicate(id: id)
        persistSavedPresetLibrary()
        return preset
    }

    @discardableResult
    func deleteSavedPreset(id: String) -> SavedPresetDefinition? {
        let deleted = savedPresetLibrary.delete(id: id)
        guard deleted != nil else {
            return nil
        }

        if settings.activeSavedPresetID == id {
            settings.activeSavedPresetID = nil
            persist()
        }

        if var draft = settingsDraft, draft.settings.activeSavedPresetID == id {
            draft.clearSavedPresetAssociation()
            settingsDraft = draft
        }

        persistSavedPresetLibrary()
        return deleted
    }

    func setDraftSoundParameter(_ id: SoundParameterID, value: Double) {
        guard var draft = settingsDraft else {
            return
        }

        draft.setSoundParameter(id, value: value)
        settingsDraft = draft
        updateDraftPlaybackIfNeeded()
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

    private func persistSavedPresetLibrary() {
        try? savedPresetStore.save(savedPresetLibrary)
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

    private func updateDraftPlaybackIfNeeded() {
        guard wasPlayingWhenSettingsOpened, isPlaying, let draft = settingsDraft else {
            return
        }

        audioEngine.update(parameters: draft.settings.activeSoundParameters)
    }

    private func normalizedPresetTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Saved Noise" : trimmed
    }

    private func normalizedPresetDescription(_ description: String) -> String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func savedPreset(
        _ id: String,
        matches settings: AppSettings,
        in library: SavedPresetLibrary
    ) -> Bool {
        guard let preset = library.preset(id: id) else {
            return false
        }

        return preset.soundParameters == settings.activeSoundParameters
    }

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter
    }()
}

private enum SleepCompanionStorage {
    static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("SleepCompanion", isDirectory: true)
            ?? FileManager.default.temporaryDirectory
    }
}

extension AppSettingsStore {
    static var appDefault: AppSettingsStore {
        AppSettingsStore(fileURL: SleepCompanionStorage.directory.appendingPathComponent("settings.json"))
    }
}

extension SavedPresetStore {
    static var appDefault: SavedPresetStore {
        SavedPresetStore(fileURL: SleepCompanionStorage.directory.appendingPathComponent("presets.json"))
    }
}
