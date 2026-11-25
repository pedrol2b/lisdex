import LisdexCore
import SwiftUI

/// Settings → General: startup, the menu bar click, feedback.
struct GeneralSettingsView: View {
  let model: AppModel

  var body: some View {
    Form {
      Section("Startup") {
        Toggle("Start on login", isOn: Bindable(model).startOnLoginSwitch)
        if model.loginItem == .needsApproval {
          LabeledContent {
            Button("Open System Settings…", action: LoginItem.openSystemSettings)
          } label: {
            Text("Waiting for your approval")
            Text("macOS asks you to allow Lisdex in Login Items.")
          }
        }
        Toggle(
          "Turn on Keep Awake when Lisdex opens", isOn: Bindable(model).activateOnLaunchSetting)
      }
      Section("Menu bar icon") {
        Picker(selection: Bindable(model).clickBehaviorSetting) {
          ForEach(StatusItemClickBehavior.allCases, id: \.self) { Text($0.title).tag($0) }
        } label: {
          Text("Turn Keep Awake on or off with")
          Text("The other click opens the menu. Option-click shows quick durations.")
        }
      }
      Section("Feedback") {
        Toggle(
          "Notify when a timed session ends", isOn: Bindable(model).notifyOnSessionEndSetting)
        Toggle(
          "Play a sound when switched on or off", isOn: Bindable(model).playsToggleSoundSetting)
        Picker("Sound", selection: Bindable(model).toggleSoundSetting) {
          ForEach(ToggleSound.allCases, id: \.self) { Text($0.title).tag($0) }
        }
        .disabled(!model.settings.playsToggleSound)
      }
    }
    .formStyle(.grouped)
  }
}
