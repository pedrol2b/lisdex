import LisdexCore
import SwiftUI

/// Settings → Power → "Chat apps": the mouse jiggler (spec mouse-jiggler, ADR 0024).
struct JigglerSection: View {
  static let caption = """
    Teams and Slack mark you Away when the Mac sees no input. While Keep Awake is on, Lisdex \
    moves the mouse by 0 px after you've been idle, so they don't. While it runs, the screen \
    saver and display sleep wait too.
    """
  static let updateNote =
    "After updating Lisdex, macOS may keep showing it as allowed while it isn't: switch Lisdex off and on there."
  /// How often the row re-checks a missing permission while it is on screen.
  private static let permissionRecheck: Duration = .seconds(2)

  let model: AppModel

  private var jiggler: JigglerSettings { model.settings.jiggler }

  var body: some View {
    Section("Chat apps") {
      Toggle(
        "Keep me active in chat apps (mouse jiggler)",
        isOn: Bindable(model).jigglerEnabledSetting)
      Text(Self.caption).font(.caption).foregroundStyle(.secondary)
      sliderRow(
        "Start after", value: Bindable(model).jigglerIdleThresholdSetting,
        range: JigglerSettings.idleThresholdRange, step: JigglerSettings.idleThresholdStep)
      sliderRow(
        "Repeat every", value: Bindable(model).jigglerIntervalSetting,
        range: JigglerSettings.intervalRange, step: JigglerSettings.intervalStep)
      if jiggler.isEnabled { permissionRow }
    }
  }

  private func sliderRow(
    _ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double
  ) -> some View {
    LabeledContent(title) {
      HStack {
        Slider(value: value, in: range, step: step).labelsHidden()
        Text(JigglerSettings.label(seconds: value.wrappedValue))
          .monospacedDigit()
          .frame(width: 80, alignment: .trailing)
      }
    }
    .disabled(!jiggler.isEnabled)
  }

  @ViewBuilder private var permissionRow: some View {
    if model.jigglerPermitted {
      Label {
        Text("Lisdex can keep you active.")
      } icon: {
        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
      }
    } else {
      VStack(alignment: .leading, spacing: 6) {
        Label {
          Text("Lisdex needs Accessibility permission.")
        } icon: {
          Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        }
        Button("Open Accessibility Settings", action: model.requestJigglerPermission)
        Text(Self.updateNote).font(.caption).foregroundStyle(.secondary)
      }
      .task {
        while !Task.isCancelled {
          try? await Task.sleep(for: Self.permissionRecheck)
          model.refreshJigglerPermission()
        }
      }
    }
  }
}
