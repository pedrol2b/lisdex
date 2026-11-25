import AppKit

/// Standard macOS About panel (ADR 0028): a tagline, one line of links, then short fine print —
/// one fact per line, no line breaks inside a sentence.
@MainActor
enum AboutPanel {
  static let repositoryURL = URL(string: "https://github.com/pedrol2b/lisdex")!
  static let newIssueURL = URL(string: "https://github.com/pedrol2b/lisdex/issues/new/choose")!
  /// GitHub Sponsors, the first entry in `.github/FUNDING.yml`.
  static let sponsorURL = URL(string: "https://github.com/sponsors/pedrol2b")!

  private static let tagline = "Keeps your Mac awake."
  private static let finePrint = [
    "Inspired by Amphetamine.",
    "Named after lisdexamfetamine.",
    "Not medical content.",
    "MIT License",
  ]

  static func show() {
    NSApp.activate()
    NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
  }

  private static var credits: NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.paragraphSpacing = 2
    let small: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
      .foregroundColor: NSColor.secondaryLabelColor,
      .paragraphStyle: paragraph,
    ]
    let gap = NSMutableParagraphStyle()
    gap.alignment = .center
    gap.paragraphSpacing = 8
    let lead = small.merging([
      .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
      .foregroundColor: NSColor.labelColor,
      .paragraphStyle: gap,
    ]) { _, new in new }
    let linkLine = small.merging([.paragraphStyle: gap]) { _, new in new }

    let text = NSMutableAttributedString(string: tagline + "\n", attributes: lead)
    let links: [(String, URL)] = [
      ("GitHub", repositoryURL), ("Report an issue", newIssueURL), ("Sponsor", sponsorURL),
    ]
    for (index, (title, url)) in links.enumerated() {
      if index > 0 { text.append(NSAttributedString(string: " · ", attributes: linkLine)) }
      text.append(
        NSAttributedString(
          string: title, attributes: linkLine.merging([.link: url]) { _, new in new }))
    }
    text.append(NSAttributedString(string: "\n", attributes: linkLine))
    text.append(NSAttributedString(string: finePrint.joined(separator: "\n"), attributes: small))
    return text
  }
}
