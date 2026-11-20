// Prints the CGWindowID of the largest on-screen window owned by the given process name.
import CoreGraphics
import Foundation

let owner = CommandLine.arguments.dropFirst().first ?? "Lisdex"
let windows =
  CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let best =
  windows
  .filter { ($0[kCGWindowOwnerName as String] as? String) == owner }
  .compactMap { info -> (id: Int, area: Double)? in
    guard let id = info[kCGWindowNumber as String] as? Int,
      let bounds = info[kCGWindowBounds as String] as? [String: Double]
    else { return nil }
    return (id, (bounds["Width"] ?? 0) * (bounds["Height"] ?? 0))
  }
  .max { $0.area < $1.area }
guard let best else { exit(1) }
print(best.id)
