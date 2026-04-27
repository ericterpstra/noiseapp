import SwiftUI

struct ClockScreen: View {
    @EnvironmentObject private var model: SleepAppModel
    @State private var previousDragHeight: CGFloat = 0

    var body: some View {
        ZStack {
            ClockFace(
                settings: model.settings,
                clockText: model.clockText,
                isWakeActive: model.isWakeActive,
                isPlaying: model.isPlaying,
                onSettings: model.beginSettings,
                onTogglePlayback: model.togglePlayback
            )
            .gesture(luminosityGesture)
            .opacity(model.isShowingSettings ? 0 : 1)
            .rotation3DEffect(.degrees(model.isShowingSettings ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .allowsHitTesting(!model.isShowingSettings)

            if model.settingsDraft != nil {
                SettingsWorkspace()
                    .environmentObject(model)
                    .opacity(model.isShowingSettings ? 1 : 0)
                    .rotation3DEffect(.degrees(model.isShowingSettings ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                    .allowsHitTesting(model.isShowingSettings)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .animation(.smooth(duration: 0.42), value: model.isShowingSettings)
        .task {
            model.startClock()
        }
        .onDisappear {
            model.stopClock()
        }
    }

    private var luminosityGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                let delta = previousDragHeight - value.translation.height
                previousDragHeight = value.translation.height
                model.adjustLuminosity(by: Double(delta / 420))
            }
            .onEnded { _ in
                previousDragHeight = 0
                model.persist()
            }
    }
}

private struct ClockFace: View {
    var settings: AppSettings
    var clockText: String
    var isWakeActive: Bool
    var isPlaying: Bool
    var onSettings: () -> Void
    var onTogglePlayback: () -> Void

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(controlForeground)
                    .background(Circle().fill(controlFill))
                    .overlay(
                        Circle()
                            .stroke(controlStroke, lineWidth: 1)
                    )
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("settingsFlipButton")
                    .padding(.top, 28)
                    .padding(.trailing, 34)
                }

                Spacer(minLength: 0)

                Text(clockText)
                    .font(clockFont(for: settings.clockFace))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .foregroundStyle(clockForeground)
                    .accessibilityIdentifier("clockTime")
                    .contentTransition(.numericText())
                    .padding(.horizontal, 64)

                Spacer(minLength: 0)

                Button(action: onTogglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .frame(width: 78, height: 58)
                }
                .buttonStyle(.plain)
                .foregroundStyle(controlForeground)
                .background(controlFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(controlStroke, lineWidth: 1)
                )
                .accessibilityLabel(isPlaying ? "Pause sleep noise" : "Start sleep noise")
                .accessibilityIdentifier("playPauseButton")
                .padding(.bottom, 30)
            }
        }
    }

    private var backgroundColor: Color {
        isWakeActive ? Color(hex: settings.clockFace.wakeBackgroundColorHex) : .black
    }

    private var clockForeground: Color {
        if isWakeActive {
            return readableForeground(for: settings.clockFace.wakeBackgroundColorHex).opacity(0.88)
        }

        return Color(hex: settings.clockFace.colorHex)
            .opacity(settings.clockFace.luminosity)
    }

    private var controlForeground: Color {
        controlBaseColor.opacity(isPlaying ? 0.18 : 0.72)
    }

    private var controlFill: Color {
        controlBaseColor.opacity(isPlaying ? 0.025 : 0.1)
    }

    private var controlStroke: Color {
        controlBaseColor.opacity(isPlaying ? 0.035 : 0.12)
    }

    private var controlBaseColor: Color {
        isWakeActive ? readableForeground(for: settings.clockFace.wakeBackgroundColorHex) : .white
    }
}

private struct SettingsWorkspace: View {
    @EnvironmentObject private var model: SleepAppModel

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.065, blue: 0.07).ignoresSafeArea()

            VStack(spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.system(size: 34, weight: .semibold))
                    }

                    Spacer()

                    Button("Cancel") {
                        model.cancelSettingsDraft()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("settingsCancelButton")

                    Button("Apply") {
                        model.applySettingsDraft()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("settingsApplyButton")
                }

                if let draft = model.settingsDraft {
                    HStack(alignment: .top, spacing: 18) {
                        SoundControlsPanel(draft: draft)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        ClockControlsPanel(draft: draft)
                            .frame(width: 380)
                            .frame(maxHeight: .infinity)
                    }
                }
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 28)
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settingsWorkspace")
    }
}

private struct SoundControlsPanel: View {
    @EnvironmentObject private var model: SleepAppModel
    @State private var hasEditedSound = false
    @State private var isShowingSaveAsAlert = false
    @State private var isShowingDeleteConfirmation = false
    @State private var saveAsTitle = ""
    @State private var saveAsDescription = ""
    var draft: SettingsDraft

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep Noise")
                        .font(.title2.weight(.semibold))
                    Text(currentNoiseDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                noiseSelector

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(SoundControlGroup.allCases, id: \.self) { group in
                            let definitions = SoundControlDefinition.definitions(in: group)
                            if !definitions.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(group.title)
                                        .font(.headline)
                                        .foregroundStyle(.white.opacity(0.86))

                                    ForEach(definitions) { definition in
                                        SoundControlRow(
                                            definition: definition,
                                            parameters: draft.settings.activeSoundParameters,
                                            onEdit: {
                                                hasEditedSound = true
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.trailing, 8)
                }

                HStack(spacing: 12) {
                    Button {
                        saveSelectedNoise()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedSavedPresetID == nil || !hasEditedSound)
                    .accessibilityIdentifier("noisePresetSaveButton")

                    Button {
                        openSaveAsAlert()
                    } label: {
                        Label("Save As", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasEditedSound)
                    .accessibilityIdentifier("noisePresetSaveAsButton")

                    Spacer()

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedSavedPresetID == nil)
                    .accessibilityIdentifier("noisePresetDeleteButton")
                }
            }
        }
        .alert("Save as new noise", isPresented: $isShowingSaveAsAlert) {
            TextField("Name", text: $saveAsTitle)
                .accessibilityIdentifier("noisePresetNameField")
            TextField("Description", text: $saveAsDescription)
                .accessibilityIdentifier("noisePresetDescriptionField")
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                saveAsNewNoise()
            }
        } message: {
            Text("This saves the current sound controls as a local noise preset.")
        }
        .alert("Delete noise?", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSelectedNoise()
            }
        } message: {
            Text("The current sound values will stay in this draft.")
        }
    }

    private var noiseSelector: some View {
        Menu {
            if isCustomNoiseSelected {
                Button {
                } label: {
                    Label("Custom", systemImage: "checkmark")
                }
                .disabled(true)
            }

            Section("Built-in") {
                ForEach(SoundPresetDefinition.bundledPresets) { preset in
                    Button {
                        model.selectDraftPreset(id: preset.id)
                        hasEditedSound = false
                    } label: {
                        noiseMenuLabel(preset.title, isSelected: isBundledPresetSelected(preset.id))
                    }
                }
            }

            if !model.savedPresetLibrary.presets.isEmpty {
                Section("Saved") {
                    ForEach(model.savedPresetLibrary.presets) { preset in
                        Button {
                            model.loadSavedPresetIntoDraft(id: preset.id)
                            hasEditedSound = false
                        } label: {
                            noiseMenuLabel(preset.title, isSelected: selectedSavedPresetID == preset.id)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                Text(currentNoiseTitle)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Noise preset")
        .accessibilityIdentifier("noisePresetPicker")
    }

    @ViewBuilder
    private func noiseMenuLabel(_ title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

    private var currentNoiseTitle: String {
        if let selectedSavedPreset {
            return selectedSavedPreset.title
        }

        return SoundPresetDefinition.bundledPresets.first { $0.id == draft.settings.activeSoundPresetID }?.title
            ?? "Custom"
    }

    private var currentNoiseDescription: String {
        if let selectedSavedPreset {
            return selectedSavedPreset.description.isEmpty ? "User-created noise." : selectedSavedPreset.description
        }

        return SoundPresetDefinition.bundledPresets.first { $0.id == draft.settings.activeSoundPresetID }?.description
            ?? "Custom sound shaped from the current controls."
    }

    private var selectedSavedPresetID: String? {
        guard let activeSavedPresetID = draft.settings.activeSavedPresetID,
              model.savedPresetLibrary.preset(id: activeSavedPresetID) != nil else {
            return nil
        }

        return activeSavedPresetID
    }

    private var selectedSavedPreset: SavedPresetDefinition? {
        guard let selectedSavedPresetID else {
            return nil
        }

        return model.savedPresetLibrary.preset(id: selectedSavedPresetID)
    }

    private var isCustomNoiseSelected: Bool {
        selectedSavedPresetID == nil
            && draft.settings.activeSoundPresetID == SoundPresetDefinition.customDraftPresetID
    }

    private func isBundledPresetSelected(_ id: String) -> Bool {
        selectedSavedPresetID == nil && draft.settings.activeSoundPresetID == id
    }

    private func openSaveAsAlert() {
        saveAsTitle = ""
        saveAsDescription = ""
        isShowingSaveAsAlert = true
    }

    private func saveSelectedNoise() {
        guard let selectedSavedPresetID else {
            return
        }

        _ = model.updateSavedPreset(id: selectedSavedPresetID)
        hasEditedSound = false
    }

    private func saveAsNewNoise() {
        guard let preset = model.saveDraftAsPreset(title: saveAsTitle, description: saveAsDescription) else {
            return
        }

        saveAsTitle = preset.title
        saveAsDescription = preset.description
        hasEditedSound = false
    }

    private func deleteSelectedNoise() {
        guard let selectedSavedPresetID else {
            return
        }

        _ = model.deleteSavedPreset(id: selectedSavedPresetID)
        hasEditedSound = false
    }
}

private struct SoundControlRow: View {
    @EnvironmentObject private var model: SleepAppModel
    var definition: SoundControlDefinition
    var parameters: SoundParameters
    var onEdit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(definition.label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(definition.formatValue(parameters[definition.id]))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { parameters[definition.id] },
                    set: {
                        onEdit()
                        model.setDraftSoundParameter(definition.id, value: $0)
                    }
                ),
                in: definition.minValue...definition.maxValue,
                step: definition.step
            )
            .accessibilityIdentifier("soundControl.\(definition.id.rawValue)")
        }
    }
}

private struct ClockControlsPanel: View {
    @EnvironmentObject private var model: SleepAppModel
    var draft: SettingsDraft

    var body: some View {
        Panel {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Clock Face")
                        .font(.title2.weight(.semibold))

                    clockPreview

                    Picker("Font", selection: Binding(
                        get: { draft.settings.clockFace.fontID },
                        set: { updateClockFace(fontID: $0) }
                    )) {
                        ForEach(ClockFontID.allCases, id: \.self) { fontID in
                            Text(fontID.displayName).tag(fontID)
                        }
                    }
                    .accessibilityIdentifier("clockFontPicker")

                    ClockColorControl(
                        title: "Color",
                        colorHex: draft.settings.clockFace.colorHex,
                        fallbackHex: ClockColorHex.defaultText,
                        accessibilityIdentifier: "clockTextColorPicker",
                        onChange: { updateClockFace(colorHex: $0) }
                    )

                    ClockSlider(
                        title: "Size",
                        valueText: "\(Int(draft.settings.clockFace.size.rounded()))",
                        value: Binding(
                            get: { draft.settings.clockFace.size },
                            set: { updateClockFace(size: $0) }
                        ),
                        range: 72...220,
                        step: 1
                    )

                    ClockSlider(
                        title: "Luminosity",
                        valueText: "\(Int((draft.settings.clockFace.luminosity * 100).rounded()))%",
                        value: Binding(
                            get: { draft.settings.clockFace.luminosity },
                            set: { updateClockFace(luminosity: $0) }
                        ),
                        range: 0.04...1,
                        step: 0.01
                    )

                    Divider()
                        .overlay(.white.opacity(0.18))

                    DatePicker("Wake Time", selection: wakeDateBinding, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.compact)

                    ClockColorControl(
                        title: "Wake Background",
                        colorHex: draft.settings.clockFace.wakeBackgroundColorHex,
                        fallbackHex: ClockColorHex.defaultWakeBackground,
                        accessibilityIdentifier: "wakeBackgroundColorPicker",
                        onChange: { updateClockFace(wakeBackgroundColorHex: $0) }
                    )
                }
                .padding(.trailing, 4)
            }
        }
    }

    private var clockPreview: some View {
        ZStack {
            Color.black
            Text(model.clockText)
                .font(clockFont(for: draft.settings.clockFace, scale: 0.46))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(Color(hex: draft.settings.clockFace.colorHex).opacity(draft.settings.clockFace.luminosity))
                .accessibilityIdentifier("clockPreviewTime")
                .padding(.horizontal, 20)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var wakeDateBinding: Binding<Date> {
        Binding(
            get: {
                var calendar = Calendar.current
                calendar.locale = Locale.autoupdatingCurrent
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                components.hour = draft.settings.wakeTime.hour
                components.minute = draft.settings.wakeTime.minute
                return calendar.date(from: components) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                model.setDraftWakeTime(WakeTime(hour: components.hour ?? 7, minute: components.minute ?? 0))
            }
        )
    }

    private func updateClockFace(
        fontID: ClockFontID? = nil,
        colorHex: String? = nil,
        size: Double? = nil,
        luminosity: Double? = nil,
        wakeBackgroundColorHex: String? = nil
    ) {
        let current = draft.settings.clockFace
        model.setDraftClockFace(
            ClockFaceSettings(
                fontID: fontID ?? current.fontID,
                colorHex: colorHex ?? current.colorHex,
                size: size ?? current.size,
                luminosity: luminosity ?? current.luminosity,
                wakeBackgroundColorHex: wakeBackgroundColorHex ?? current.wakeBackgroundColorHex
            )
        )
    }
}

private struct ClockColorControl: View {
    private let swatchColumns = Array(repeating: GridItem(.fixed(30), spacing: 10), count: 8)
    var title: String
    var colorHex: String
    var fallbackHex: String
    var accessibilityIdentifier: String
    var onChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ColorPicker(
                selection: Binding(
                    get: { Color(hex: colorHex) },
                    set: { onChange($0.hexString(fallback: fallbackHex)) }
                ),
                supportsOpacity: false
            ) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(colorHex)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier(accessibilityIdentifier)

            LazyVGrid(columns: swatchColumns, alignment: .leading, spacing: 10) {
                ForEach(ClockColorChoice.all, id: \.hex) { choice in
                    Button {
                        onChange(choice.hex)
                    } label: {
                        Circle()
                            .fill(Color(hex: choice.hex))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(
                                        .white.opacity(choice.hex == colorHex ? 0.9 : 0.18),
                                        lineWidth: choice.hex == colorHex ? 3 : 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(choice.name)
                }
            }
        }
    }
}

private struct ClockSlider: View {
    var title: String
    var valueText: String
    var value: Binding<Double>
    var range: ClosedRange<Double>
    var step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(valueText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: range, step: step)
        }
    }
}

private struct Panel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
    }
}

private func clockFont(for clockFace: ClockFaceSettings, scale: Double = 1) -> Font {
    let size = clockFace.size * scale

    switch clockFace.fontID {
    case .rounded:
        return .system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
    case .monospaced:
        return .system(size: size, weight: .medium, design: .monospaced).monospacedDigit()
    case .system:
        return .system(size: size, weight: .medium, design: .default).monospacedDigit()
    case .serif:
        return .system(size: size, weight: .regular, design: .serif).monospacedDigit()
    case .avenirNextCondensed:
        return .custom("AvenirNextCondensed-DemiBold", size: size).monospacedDigit()
    case .dinAlternate:
        return .custom("DINAlternate-Bold", size: size).monospacedDigit()
    case .futura:
        return .custom("Futura-Medium", size: size).monospacedDigit()
    case .gillSans:
        return .custom("GillSans-Light", size: size).monospacedDigit()
    case .georgia:
        return .custom("Georgia", size: size).monospacedDigit()
    }
}

private func readableForeground(for backgroundHex: String) -> Color {
    ClockColorHex.isLight(backgroundHex) ? .black : .white
}

private extension ClockFontID {
    var displayName: String {
        switch self {
        case .rounded: "Rounded"
        case .monospaced: "Monospaced"
        case .system: "System"
        case .serif: "Serif"
        case .avenirNextCondensed: "Avenir Condensed"
        case .dinAlternate: "DIN Alternate"
        case .futura: "Futura"
        case .gillSans: "Gill Sans"
        case .georgia: "Georgia"
        }
    }
}
