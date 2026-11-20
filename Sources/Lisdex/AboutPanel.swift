import AppKit

/// Standard macOS About panel with one fact per line in the credits area.
@MainActor
enum AboutPanel {
  static let repositoryURL = URL(string: "https://github.com/pedrol2b/lisdex")!

  static func show() {
    NSApp.activate()
    NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
  }

  private static var credits: NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.paragraphSpacing = 2
    let base: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
      .foregroundColor: NSColor.secondaryLabelColor,
      .paragraphStyle: paragraph,
    ]
    let lines = [
      NSAttributedString(string: "MIT License\n", attributes: base),
      NSAttributedString(string: "Lisdex is short for lisdexamfetamine.\n", attributes: base),
      NSAttributedString(
        string: "github.com/pedrol2b/lisdex",
        attributes: base.merging([.link: repositoryURL]) { _, new in new }),
    ]
    return lines.reduce(into: NSMutableAttributedString()) { $0.append($1) }
  }
}
