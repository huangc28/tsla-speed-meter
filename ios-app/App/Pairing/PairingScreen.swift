import HUDCore
import SwiftUI
import TeslaBLE

/// The pairing flow on screen, bound to its coordinator. 取消, 稍後再說 and 完成 close it.
struct PairingFlowView: View {
    @Bindable var flow: PairingFlow
    @Environment(\.dismiss) private var dismiss
    @AppStorage("speedUnit") private var unitSetting = SpeedUnit.kilometersPerHour.rawValue

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let screen = CGSize(width: proxy.size.width + insets.leading + insets.trailing,
                                height: proxy.size.height + insets.top + insets.bottom)
            PairingScreen(
                step: flow.step, entry: flow.entry, parkedConfirmed: flow.parkedConfirmed,
                unit: SpeedUnit(rawValue: unitSetting) ?? .kilometersPerHour,
                screen: screen, leftInset: insets.leading, rightInset: insets.trailing, bottomInset: insets.bottom,
                typed: Binding(get: { flow.entry.formatted }, set: { flow.type($0) }),
                actions: actions
            )
            .offset(x: -insets.leading, y: -insets.top)
        }
        // The VIN keyboard covers the lower half; S14 keeps everything above it (01 §7.2).
        .ignoresSafeArea(.keyboard)
        .background(Palette.background)
        .preferredColorScheme(.dark)
        .onDisappear { flow.finish() }
    }

    private var actions: PairingActions {
        PairingActions(
            setParked: { flow.parkedConfirmed = $0 },
            begin: { flow.begin() },
            back: { flow.back() },
            submit: { flow.submitVIN() },
            submitAnyway: { flow.submitVINAnyway() },
            retry: { flow.retry() },
            close: {
                Task {
                    await flow.cancel()
                    dismiss()
                }
            },
            done: {
                flow.finish()
                dismiss()
            }
        )
    }
}

/// What the pairing screens' buttons do.
struct PairingActions {
    var setParked: @MainActor (Bool) -> Void = { _ in }
    var begin: @MainActor () -> Void = {}
    var back: @MainActor () -> Void = {}
    var submit: @MainActor () -> Void = {}
    var submitAnyway: @MainActor () -> Void = {}
    var retry: @MainActor () -> Void = {}
    /// 取消 or 稍後再說: leave the flow, leaving nothing behind.
    var close: @MainActor () -> Void = {}
    var done: @MainActor () -> Void = {}
}

/// S13–S17 in landscape (01 §7.2, DESIGN.md Forms & flows): a title bar, a left column with
/// the step and its picture, a right column with the words, and the buttons fixed at the
/// bottom (secondary left, primary right). S14 is the one keyboard screen: only its header,
/// the field, the message and 下一步, all above the keyboard.
struct PairingScreen: View {
    let step: PairingFlow.Step
    let entry: VINEntry
    let parkedConfirmed: Bool
    let unit: SpeedUnit
    let screen: CGSize
    let side: CGFloat
    let bottom: CGFloat
    @Binding var typed: String
    let actions: PairingActions
    /// S14 opens with the keyboard up (off for render tests: no caret).
    let focusesField: Bool
    @State private var showsGuide = false
    @FocusState private var fieldFocused: Bool

    init(step: PairingFlow.Step, entry: VINEntry, parkedConfirmed: Bool, unit: SpeedUnit = .kilometersPerHour,
         screen: CGSize, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat,
         typed: Binding<String>, actions: PairingActions = PairingActions(), focusesField: Bool = true) {
        self.step = step
        self.entry = entry
        self.parkedConfirmed = parkedConfirmed
        self.unit = unit
        self.screen = screen
        // Both sides use the larger inset, as on the drive screen (01 §7.4).
        side = max(leftInset, rightInset) + 16
        bottom = max(bottomInset, 16)
        _typed = typed
        self.actions = actions
        self.focusesField = focusesField
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RadialGradient(colors: [Palette.backgroundGlow, Palette.background],
                           center: .top, startRadius: 0, endRadius: screen.width * 0.8)
            content
                .padding(.horizontal, side)
                .padding(.top, 16)
                .padding(.bottom, bottom)
                .frame(width: screen.width, height: screen.height, alignment: .topLeading)
            if showsGuide {
                VINGuide { showsGuide = false }
                    .frame(width: screen.width, height: screen.height)
            }
        }
        .frame(width: screen.width, height: screen.height, alignment: .topLeading)
        .background(Palette.background)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .vin:
            vinEntry
        default:
            VStack(alignment: .leading, spacing: 0) {
                Text("Connect your car")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                    .frame(height: 40, alignment: .top)
                HStack(alignment: .top, spacing: 28) {
                    left.frame(maxWidth: .infinity, alignment: .topLeading)
                    right.frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                buttons.padding(.top, 12)
            }
        }
    }

    // MARK: Columns

    @ViewBuilder
    private var left: some View {
        switch step {
        case .start:
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader("Before you start")
                ChecklistItem("You're in the car and it's awake (a door was opened or the brake pressed)")
                ChecklistItem("You have this car's key card")
                ChecklistItem("The car is parked in P")
                ParkedConfirmation(isOn: parkedConfirmed) { actions.setParked(!parkedConfirmed) }
                    .padding(.top, 4)
            }
        case .finding:
            StepColumn(number: 2) { LinkPicture() }
        case .keyCard:
            StepColumn(number: 3) { PicturePlaceholder().frame(width: 200, height: 150) }
        case .reading:
            StepColumn(number: 4) { EmptyView() }
        case .paired:
            StepColumn(number: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Palette.accentText)
                    .frame(width: 64, height: 64)
                    .background(Palette.accentSegActiveBackground, in: RoundedRectangle(cornerRadius: 16))
            }
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Palette.sourceDegraded)
                .padding(.top, 8)
        case .vin:
            EmptyView()
        }
    }

    @ViewBuilder
    private var right: some View {
        switch step {
        case .start:
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader("What we use")
                // Scrolls when it does not fit (the 667-wide phone, large text).
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        UseItem(title: "Your VIN", detail: "Used to find and connect to your car.")
                        Divider().overlay(Palette.divider)
                        UseItem(title: "A new app key",
                                detail: "It's added to your car's key list with \"Driver\" access. This app uses it only to read car data. You can remove it from the car's key list anytime.")
                        Divider().overlay(Palette.divider)
                        UseItem(title: "No carmaker account sign-in needed",
                                detail: "Car data goes straight to your phone over Bluetooth.")
                    }
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.visible)
            }
        case .finding(let matched):
            VStack(alignment: .leading, spacing: 14) {
                Title(matched ? "Connecting…" : "Looking for your car…")
                BodyText("Stay in the car near the center console.")
                VStack(alignment: .leading, spacing: 16) {
                    if matched {
                        ProgressRow(.done) { Text("That's the car next to you") }
                        ProgressRow(.running) { Text("Connecting…") }
                    } else {
                        ProgressRow(.running) { Text("Looking for your car…") }
                        ProgressRow(.next(2)) { Text("Connecting…") }
                    }
                }
                .padding(.top, 6)
            }
        case .keyCard:
            VStack(alignment: .leading, spacing: 14) {
                Title("Tap your key card")
                BodyText("Place this car's key card on the card reader on the center console until the car confirms.")
                Text("The reader's location depends on your model and year. See your owner's manual.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressRow(.running) { Text("Waiting for key card…") }
                    .padding(.top, 6)
            }
        case .reading:
            VStack(alignment: .leading, spacing: 14) {
                ProgressRow(.running) { Text("Key added. Reading car data…") }
            }
        case .paired(let preview):
            VStack(alignment: .leading, spacing: 14) {
                Title("Connected")
                PreviewCard(preview: preview, unit: unit)
                BodyText("When the data is valid, \"Car Bluetooth\" shows in the top-left corner.")
                SourceChip(status: .valid(.carBluetooth))
            }
        case .failed:
            VStack(alignment: .leading, spacing: 14) {
                Title("Pairing didn't finish")
            }
        case .vin:
            EmptyView()
        }
    }

    // MARK: Buttons

    @ViewBuilder
    private var buttons: some View {
        HStack {
            switch step {
            case .start:
                TextButton("Cancel", action: actions.close)
                Spacer()
                PrimaryButton("Start", enabled: parkedConfirmed, action: actions.begin)
            case .finding, .keyCard, .reading:
                Spacer()
                SecondaryButton("Cancel", action: actions.close)
            case .paired:
                Spacer()
                PrimaryButton("Done", action: actions.done)
            case .failed:
                SecondaryButton("Not now", action: actions.close)
                Spacer()
                PrimaryButton("Try again", action: actions.retry)
            case .vin:
                EmptyView()
            }
        }
        .frame(height: 48)
    }

    // MARK: S14

    private var vinEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Button(action: actions.back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Palette.textRow)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Text("Back"))
                Text("Step \(1) of 4")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .monospacedDigit()
                Text("Enter your VIN")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Button { showsGuide = true } label: {
                    Text("Where's my VIN?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.accentText)
                        .lineLimit(1)
                        .frame(minHeight: 44)
                }
                if fieldFocused {
                    Button { fieldFocused = false } label: {
                        Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Palette.textRow)
                            .lineLimit(1)
                            .frame(minHeight: 44)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(height: 44)
            HStack(spacing: 12) {
                vinField
                PrimaryButton("Next", enabled: entry.problem == nil && entry.isComplete, action: actions.submit)
            }
            message
        }
        .onAppear { if focusesField { fieldFocused = true } }
    }

    private var vinField: some View {
        HStack(spacing: 12) {
            TextField(text: $typed, prompt: Text("17 letters and numbers").font(.system(size: 17)).foregroundStyle(Palette.textTertiary)) {
                Text("Enter your VIN")
            }
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.textPrimary)
                .tracking(1)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .submitLabel(.next)
                .focused($fieldFocused)
                .onSubmit(actions.submit)
            Text("\(entry.count) of 17 entered")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.textSecondary)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 18)
        .frame(height: 60)
        .background(Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(entry.problem == nil ? Palette.cardBorder : Palette.sourceDegraded, lineWidth: 2))
    }

    @ViewBuilder
    private var message: some View {
        switch entry.problem {
        case .invalidCharacter?:
            Warning("VINs don't contain I, O, or Q")
        case .wrongLength?:
            Warning("VIN must be 17 characters")
        case .checkDigit?:
            HStack(spacing: 16) {
                Warning("That number doesn't look right. Please check it again.")
                Button(action: actions.submitAnyway) {
                    Text("Continue anyway")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.accentText)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        case nil:
            EmptyView()
        }
    }
}

// MARK: Pieces

private struct Title: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Palette.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct BodyText: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .lineSpacing(4)
            .foregroundStyle(Palette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct SectionHeader: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Palette.unit)
    }
}

/// A static list mark in `text.secondary`, never cyan (R8-02).
private struct ChecklistItem: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "smallcircle.filled.circle")
                .font(.system(size: 15))
                .foregroundStyle(Palette.textSecondary)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// L67: the user confirms the car is parked; a box that fills and ticks (not only a color).
private struct ParkedConfirmation: View {
    let isOn: Bool
    let toggle: @MainActor () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isOn ? Palette.accent : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(isOn ? Palette.accent : Palette.cardBorder, lineWidth: 2))
                    .overlay {
                        if isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Palette.background)
                        }
                    }
                    .frame(width: 24, height: 24)
                Text("The car is parked (in P)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

private struct UseItem: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.textPrimary)
            Text(detail)
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 步驟 n/4 with its bar, then the step's picture.
private struct StepColumn<Picture: View>: View {
    let number: Int
    @ViewBuilder let picture: Picture

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step \(number) of 4")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)
                .monospacedDigit()
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { index in
                    Capsule()
                        .fill(index <= number ? Palette.accent : Palette.surfaceRaised)
                        .frame(height: 4)
                }
            }
            picture
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
    }
}

/// S15: phone, Bluetooth, car.
private struct LinkPicture: View {
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "iphone")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Palette.textRow)
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Palette.accentText)
            Text(verbatim: "· · ·")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.textTertiary)
            Image(systemName: "car")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Palette.textRow)
        }
        .accessibilityHidden(true)
    }
}

/// The real pictures come with #58.
struct PicturePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Palette.card)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.cardBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
            .overlay {
                Text("Picture coming soon")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
    }
}

/// One line of S15–S17 progress: running (a turning ring), done (✓) or still to come (its number).
private struct ProgressRow<Label: View>: View {
    enum Phase {
        case running, done
        case next(Int)
    }

    let state: Phase
    @ViewBuilder let label: Label

    init(_ state: Phase, @ViewBuilder label: () -> Label) {
        self.state = state
        self.label = label()
    }

    var body: some View {
        HStack(spacing: 14) {
            switch state {
            case .running:
                Spinner()
            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Palette.sourceOK)
                    .frame(width: 26, height: 26)
            case .next(let number):
                Text(verbatim: "\(number)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().strokeBorder(Palette.cardBorder, lineWidth: 1.5))
            }
            label
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle({ if case .next = state { Palette.textSecondary } else { Palette.textPrimary } }())
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A turning ring. It stands still where animations are off (reduced motion, render tests).
private struct Spinner: View {
    @State private var turned = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(Palette.surfaceRaised, lineWidth: 4)
            Circle().trim(from: 0, to: 0.3)
                .stroke(Palette.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(turned ? 270 : -90))
        }
        .frame(width: 24, height: 24)
        .padding(1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) { turned = true }
        }
        .accessibilityHidden(true)
    }
}

/// S17: speed, gear and battery in one row.
private struct PreviewCard: View {
    let preview: PairingPreview
    let unit: SpeedUnit

    var body: some View {
        HStack(spacing: 0) {
            cell("Speed", value: speed, unit: unit == .milesPerHour ? "mph" : "km/h")
            Divider().overlay(Palette.divider).padding(.vertical, 12)
            cell("Gear", value: gear, unit: nil)
            Divider().overlay(Palette.divider).padding(.vertical, 12)
            cell("Battery", value: preview.batteryPercent.map(String.init) ?? "—", unit: "%")
        }
        .frame(height: 84)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.divider))
    }

    private var speed: String {
        guard let kmh = preview.speedKilometersPerHour else { return "—" }
        let value = unit == .milesPerHour ? kmh / 1.609344 : kmh
        return String(Int(value.rounded()))
    }

    private var gear: String {
        switch preview.gear {
        case .park?: "P"
        case .reverse?: "R"
        case .neutral?: "N"
        case .drive?: "D"
        case .unknown?, nil: "—"
        }
    }

    private func cell(_ label: LocalizedStringKey, value: String, unit: String?) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.unit)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: value)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                    .monospacedDigit()
                if let unit, value != "—" {
                    Text(verbatim: unit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.unit)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct Warning: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "exclamationmark.triangle")
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Palette.sourceDegraded)
    }
}

/// 「在哪裡找到 VIN？」: a placeholder until #58 draws the guide.
private struct VINGuide: View {
    let close: @MainActor () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            VStack(alignment: .leading, spacing: 14) {
                Text("Where's my VIN?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                PicturePlaceholder().frame(height: 120)
                Text("Find it on the car's vehicle info screen, at the lower-left corner of the windshield, or on your registration.")
                    .font(.system(size: 15))
                    .lineSpacing(4)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    PrimaryButton("Got it", action: close)
                }
            }
            .padding(20)
            .frame(maxWidth: 460)
            .background(Palette.dialFace, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: Buttons (DESIGN.md Component states)

private struct PrimaryButton: View {
    let title: LocalizedStringKey
    var enabled = true
    let action: @MainActor () -> Void

    init(_ title: LocalizedStringKey, enabled: Bool = true, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.enabled = enabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(enabled ? Palette.background : Palette.textInactive)
                .frame(minWidth: 150, minHeight: 48)
                .padding(.horizontal, 12)
                .background(enabled ? Palette.accent : Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 16))
                .fixedSize()
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private struct SecondaryButton: View {
    let title: LocalizedStringKey
    let action: @MainActor () -> Void

    init(_ title: LocalizedStringKey, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.textRow)
                .frame(minWidth: 150, minHeight: 48)
                .padding(.horizontal, 12)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.cardBorder, lineWidth: 1.5))
                .fixedSize()
        }
        .buttonStyle(.plain)
    }
}

private struct TextButton: View {
    let title: LocalizedStringKey
    let action: @MainActor () -> Void

    init(_ title: LocalizedStringKey, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.accentText)
                .frame(minWidth: 44, minHeight: 48)
                .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}
