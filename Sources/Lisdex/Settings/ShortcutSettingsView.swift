import LisdexCore
import SwiftUI

/// Settings → Shortcuts: one recorder per action (ADR 0019). None assigned by default.
struct ShortcutSettingsView: View {
  let model: AppModel

  var body: some View {
    Form {
      Section {
        ForEach(ShortcutAction.allCases, id: \.self) { action in
          ShortcutRow(model: model, action: action)
          if action == .startDuration {
            Picker("Duration", selection: Bindable(model).shortcutDurationSetting) {
              ForEach(DurationPreset.all, id: \.seconds) { Text($0.title).tag($0.seconds) }
            }
          }
        }
      } header: {
        Text("Global shortcuts")
      } footer: {
        SectionFooter(
          "Shortcuts work from any app. Click a field and press keys. Delete clears it, Esc cancels."
        )
      }
    }
    .formStyle(.grouped)
  }
}

private struct ShortcutRow: View {
  let model: AppModel
  let action: ShortcutAction
  @State private var problem: KeyComboProblem?

  private var combo: KeyCombo? { model.settings.shortcuts.combos[action] }

  var body: some View {
    LabeledContent {
      HStack(spacing: 6) {
        ShortcutRecorder(
          title: combo.map { $0.displayString(keyName: KeyboardLayout.keyName(for: $0.keyCode)) }
            ?? "Record Shortcut",
          onRecordingChange: { recording in
            model.isRecordingShortcut = recording
            problem = nil
          },
          onRecord: record,
          onClear: { model.setShortcut(nil, for: action) }
        )
        .frame(width: RecorderView.size.width, height: RecorderView.size.height)
        // A hosted NSView has no text baseline; give the form one so the label lines up.
        .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
        .alignmentGuide(.lastTextBaseline) { $0[VerticalAlignment.center] + 4 }
        Button {
          model.setShortcut(nil, for: action)
        } label: {
          Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .opacity(combo == nil ? 0 : 1)
        .disabled(combo == nil)
        .accessibilityLabel("Clear \(action.title) shortcut")
      }
    } label: {
      Text(action.title)
      if let note {
        Text(note).foregroundStyle(.red)
      }
    }
  }

  private var note: String? {
    if let problem { return problem.message }
    if model.shortcutsInUseElsewhere.contains(action) { return "Already in use by another app." }
    return nil
  }

  private func record(_ candidate: KeyCombo) -> KeyComboProblem? {
    let found = candidate.problem(
      keyName: KeyboardLayout.keyName(for: candidate.keyCode), action: action,
      assigned: model.settings.shortcuts.combos)
    problem = found
    if found == nil { model.setShortcut(candidate, for: action) }
    return found
  }
}
