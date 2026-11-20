import Foundation
import os

enum Log {
  static let subsystem = Bundle.main.bundleIdentifier ?? "io.github.pedrol2b.lisdex"
  static let app = Logger(subsystem: subsystem, category: "app")
  static let power = Logger(subsystem: subsystem, category: "power")
}
