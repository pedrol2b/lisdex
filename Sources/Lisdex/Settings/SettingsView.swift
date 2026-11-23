import LisdexCore
import SwiftUI

enum SettingsTab: String {
  case general, power, appearance
}

/// Settings → General · Power · Appearance (spec "Settings window").
struct SettingsView: View {
  static let width: CGFloat = 480

  let model: AppModel
  @State private var tab: SettingsTab

  init(model: AppModel, tab: SettingsTab = .general) {
    self.model = model
    _tab = State(initialValue: tab)
  }

  var body: some View {
    TabView(selection: $tab) {
      GeneralSettings(model: model)
        .tabItem { Label("General", systemImage: "gearshape") }
        .tag(SettingsTab.general)
      PowerSettings(model: model)
        .tabItem { Label("Power", systemImage: "bolt") }
        .tag(SettingsTab.power)
      AppearanceSettings(model: model)
        .tabItem { Label("Appearance", systemImage: "paintpalette") }
        .tag(SettingsTab.appearance)
    }
    .frame(width: Self.width)
    .fixedSize(horizontal: false, vertical: true)
    .accent(model.settings.accent)
  }
}

private struct GeneralSettings: View {
  let model: AppModel

  var body: some View {
    Form {
      Section {
        Toggle(
          "Start on Login",
          isOn: Bindable(model).startOnLoginSwitch)
        if model.loginItem == .needsApproval {
          LabeledContent("Waiting for your approval in Login Items.") {
            Button("Open System Settings…", action: LoginItem.openSystemSettings)
          }
          .font(.caption)
        }
        Toggle(
          "Activate Keep Awake when Lisdex launches",
          isOn: Bindable(model).activateOnLaunchSetting)
        Toggle(
          "Notify when a timed session ends",
          isOn: Bindable(model).notifyOnSessionEndSetting)
      }
      Section {
        Picker(
          "Quick-Start a Session",
          selection: Bindable(model).clickBehaviorSetting
        ) {
          ForEach(StatusItemClickBehavior.allCases, id: \.self) { Text($0.title).tag($0) }
        }
      }
      Section("Sound") {
        Toggle(
          "Play a sound when Keep Awake is switched on or off",
          isOn: Bindable(model).playsToggleSoundSetting)
        Picker(
          "Sound",
          selection: Bindable(model).toggleSoundSetting
        ) {
          ForEach(ToggleSound.allCases, id: \.self) { Text($0.title).tag($0) }
        }
        .disabled(!model.settings.playsToggleSound)
      }
    }
    .formStyle(.grouped)
  }
}

private struct PowerSettings: View {
  /// ADR 0002: shown under the engine picker when `caffeinate` is selected.
  static let caffeinateWarning = """
    Lisdex uses macOS power assertions (IOKit) by default. They live inside the app, show up as \
    "Lisdex" in pmset -g assertions, and macOS clears them automatically if the app quits or crashes.

    caffeinate runs as a separate background process. Lisdex ties it to its own lifetime, but it is \
    one more process to manage, shows up only as "caffeinate", and may be blocked or killed by \
    device-management tools. Use it only if you specifically prefer the system command.
    """

  let model: AppModel

  var body: some View {
    Form {
      Section {
        Toggle(
          "Keep the display awake",
          isOn: Bindable(model).keepDisplayAwakeSetting)
        Toggle(
          "Allow display sleep on battery",
          isOn: Bindable(model).allowDisplaySleepOnBatterySetting
        )
        .disabled(!model.settings.keepDisplayAwake)
        Picker(
          "Stop below battery",
          selection: Bindable(model).batteryStopThresholdSetting
        ) {
          ForEach(BatteryThreshold.allCases, id: \.self) { Text($0.title).tag($0) }
        }
      }
      Section("Keep-awake engine") {
        Picker("Engine", selection: Bindable(model).engineSetting) {
          ForEach(KeepAwakeEngine.allCases, id: \.self) { Text($0.title).tag($0) }
        }
        .pickerStyle(.radioGroup)
        .labelsHidden()
        if model.settings.engine == .caffeinate {
          Label {
            Text(Self.caffeinateWarning).font(.caption).foregroundStyle(.secondary)
          } icon: {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
          }
        }
      }
    }
    .formStyle(.grouped)
  }
}

private struct AppearanceSettings: View {
  let model: AppModel

  var body: some View {
    Form {
      Section("Menu bar icon") {
        HStack(spacing: 12) {
          ForEach(MenuBarIconVariant.allCases, id: \.self) { variant in
            IconVariantCard(
              variant: variant, isSelected: model.settings.iconVariant == variant,
              select: { model.setIconVariant(variant) })
          }
        }
      }
      Section("Accent colour") {
        HStack(spacing: 10) {
          ForEach(AccentChoice.allCases, id: \.self) { choice in
            AccentSwatch(choice: choice, isSelected: model.settings.accent == choice) {
              model.setAccent(choice)
            }
          }
        }
      }
    }
    .formStyle(.grouped)
  }
}

/// Both states of one icon variant, as they appear in the menu bar.
private struct IconVariantCard: View {
  @Environment(\.accent) private var accent
  let variant: MenuBarIconVariant
  let isSelected: Bool
  let select: () -> Void

  var body: some View {
    Button(action: select) {
      VStack(spacing: 8) {
        HStack(spacing: 14) {
          ForEach([false, true], id: \.self) { active in
            Image(
              nsImage: MenuBarImages.image(for: MenuBarIcon(variant: variant, isActive: active))
            )
            .renderingMode(.template)
          }
        }
        .frame(height: 28)
        Text(variant.title).font(.caption)
      }
      .frame(maxWidth: .infinity)
      .padding(10)
      .background(Color.primary.opacity(0.05), in: .rect(cornerRadius: 8))
      .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? accent : .clear, lineWidth: 2))
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(variant.title) icon")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(isSelected ? "Selected" : "")
  }
}

private struct AccentSwatch: View {
  let choice: AccentChoice
  let isSelected: Bool
  let select: () -> Void

  var body: some View {
    Button(action: select) {
      Circle()
        .fill(choice.color)
        .frame(width: 22, height: 22)
        .overlay(
          Circle().stroke(Color.primary.opacity(isSelected ? 0.9 : 0), lineWidth: 2).padding(-3)
        )
        .contentShape(.circle)
    }
    .buttonStyle(.plain)
    .help(choice.title)
    .accessibilityLabel(choice.title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(isSelected ? "Selected" : "")
  }
}
