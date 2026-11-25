import LisdexCore
import SwiftUI

/// Settings → Power: display, battery, and the keep-awake engine (ADR 0002) last.
struct PowerSettingsView: View {
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
      Section("Display") {
        Toggle(isOn: Bindable(model).keepDisplayAwakeSetting) {
          Text("Keep the display awake")
          Text("Off keeps the Mac running but lets the screen turn off.")
        }
        Toggle("Except on battery", isOn: Bindable(model).allowDisplaySleepOnBatterySetting)
          .disabled(!model.settings.keepDisplayAwake)
      }
      Section("Battery") {
        Picker(selection: Bindable(model).batteryStopThresholdSetting) {
          ForEach(BatteryThreshold.allCases, id: \.self) { Text($0.title).tag($0) }
        } label: {
          Text("Turn off below")
          Text("Switches Keep Awake off when the battery runs low.")
        }
      }
      Section("Advanced") {
        Picker(selection: Bindable(model).engineSetting) {
          ForEach(KeepAwakeEngine.allCases, id: \.self) { Text($0.title).tag($0) }
        } label: {
          Text("Keep-awake engine")
          Text("Power assertions are recommended: macOS releases them if Lisdex quits.")
        }
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
