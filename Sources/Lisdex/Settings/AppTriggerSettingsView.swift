import AppKit
import LisdexCore
import SwiftUI
import UniformTypeIdentifiers

/// Settings → Apps: while any of these apps is open, Keep Awake stays on (spec app-trigger).
/// Empty by default; the user picks every app.
struct AppTriggerSettingsView: View {
  let model: AppModel

  private var apps: [AppTrigger] { model.settings.appTriggers.apps }

  var body: some View {
    Form {
      Section {
        if apps.isEmpty {
          Text("No apps yet.").foregroundStyle(.secondary)
        }
        ForEach(apps, id: \.bundleID) { app in
          AppTriggerRow(app: app) { model.removeAppTrigger(bundleID: app.bundleID) }
        }
        Button("Add App…", action: pickApp)
      } header: {
        Text("Keep awake while these apps are open")
      } footer: {
        Text(
          "Keep Awake turns on when one of these apps opens and off when the last one quits. "
            + "If you turn it on or off yourself, Lisdex leaves it that way."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .formStyle(.grouped)
  }

  private func pickApp() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.application]
    panel.directoryURL = URL(filePath: "/Applications")
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.prompt = "Add"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    guard let bundleID = Bundle(url: url)?.bundleIdentifier else {
      Log.app.error("Picked app has no bundle identifier: \(url.path, privacy: .public)")
      return
    }
    let name = FileManager.default.displayName(atPath: url.path)
    let trimmed = name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    model.addAppTrigger(AppTrigger(bundleID: bundleID, name: trimmed))
  }
}

private struct AppTriggerRow: View {
  let app: AppTrigger
  let remove: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Image(nsImage: Self.icon(for: app.bundleID))
        .resizable()
        .frame(width: 20, height: 20)
        .accessibilityHidden(true)
      Text(app.name)
      Spacer()
      Button(action: remove) {
        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
      }
      .buttonStyle(.borderless)
      .help("Remove \(app.name)")
      .accessibilityLabel("Remove \(app.name)")
    }
  }

  /// The app's own icon, or the generic app icon when it is no longer installed.
  private static func icon(for bundleID: String) -> NSImage {
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
      return NSWorkspace.shared.icon(for: .application)
    }
    return NSWorkspace.shared.icon(forFile: url.path)
  }
}
