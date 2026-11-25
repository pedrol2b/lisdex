import SwiftUI

/// Footer row: symbol · title · shortcut or chevron, with a hover highlight.
struct MenuActionRow: View {
  let symbol: String
  let title: String
  var shortcut: String?
  var showsChevron = false
  let action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: symbol).frame(width: 24)
        Text(title)
        Spacer()
        if let shortcut { Text(shortcut).foregroundStyle(.secondary) }
        if showsChevron { Image(systemName: "chevron.right").foregroundStyle(.secondary) }
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 6)
      .background(isHovered ? Color.primary.opacity(0.08) : .clear, in: .rect(cornerRadius: 6))
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
  }
}
