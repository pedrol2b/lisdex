import AppKit

/// Opens the system colour panel beside the window it was opened from and streams picked
/// colours (0xRRGGBB) to a callback.
@MainActor
final class ColorPanelPresenter: NSObject {
  static let shared = ColorPanelPresenter()
  /// Gap between the Settings window and the panel.
  private static let gap: CGFloat = 12

  private var onChange: ((UInt32) -> Void)?

  func show(initial rgb: UInt32, onChange: @escaping (UInt32) -> Void) {
    self.onChange = onChange
    let panel = NSColorPanel.shared
    panel.showsAlpha = false
    panel.isContinuous = true
    panel.color = RGB.nsColor(rgb)
    panel.setTarget(self)
    panel.setAction(#selector(colorChanged(_:)))
    NSApp.activate()
    if let anchor = NSApp.keyWindow, anchor !== panel { place(panel, beside: anchor) }
    panel.makeKeyAndOrderFront(nil)
  }

  /// To the right of `anchor`, top edges aligned; to its left when there's no room on the right.
  private func place(_ panel: NSPanel, beside anchor: NSWindow) {
    guard let screen = (anchor.screen ?? NSScreen.main)?.visibleFrame else { return }
    let size = panel.frame.size
    let right = anchor.frame.maxX + Self.gap
    let x = right + size.width <= screen.maxX ? right : anchor.frame.minX - Self.gap - size.width
    let y = min(anchor.frame.maxY, screen.maxY) - size.height
    panel.setFrameOrigin(
      NSPoint(
        x: min(max(x, screen.minX), screen.maxX - size.width),
        y: max(y, screen.minY)))
  }

  @objc private func colorChanged(_ panel: NSColorPanel) {
    onChange?(RGB.value(of: panel.color))
  }
}
