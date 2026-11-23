import Foundation

/// The Option-click menu on the status item: quick durations, Until I Stop, and Stop while on.
public enum QuickMenu {
  public static let title = "Keep Awake for…"

  public enum Item: Equatable, Sendable {
    case duration(TimeInterval)
    case indefinitely
    case stop

    public var title: String {
      switch self {
      case .duration(let seconds): DurationText.spoken(seconds).capitalized
      case .indefinitely: "Until I Stop"
      case .stop: "Stop"
      }
    }
  }

  public static func items(isOn: Bool) -> [Item] {
    DurationPreset.all.map { .duration($0.seconds) } + [.indefinitely] + (isOn ? [.stop] : [])
  }
}
