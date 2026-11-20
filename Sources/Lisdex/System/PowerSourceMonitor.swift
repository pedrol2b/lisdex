import Foundation
import IOKit.ps
import LisdexCore

/// Reports the current `PowerSource` and calls `onChange` whenever macOS posts a power-source
/// change (plugged in, unplugged, battery level).
@MainActor
final class PowerSourceMonitor {
  private let onChange: @MainActor (PowerSource) -> Void
  private var runLoopSource: CFRunLoopSource?
  private(set) var current: PowerSource

  init(onChange: @escaping @MainActor (PowerSource) -> Void) {
    self.onChange = onChange
    self.current = Self.read()
    let context = Unmanaged.passUnretained(self).toOpaque()
    guard
      let source = IOPSNotificationCreateRunLoopSource(
        { context in
          guard let context else { return }
          let monitor = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()
          MainActor.assumeIsolated { monitor.refresh() }
        }, context)?.takeRetainedValue()
    else {
      Log.power.error(
        "Power source notifications unavailable; battery options won't react to changes")
      return
    }
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    runLoopSource = source
  }

  isolated deinit {
    if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
  }

  private func refresh() {
    let next = Self.read()
    guard next != current else { return }
    current = next
    onChange(next)
  }

  static func read() -> PowerSource {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return .mains }
    let providing = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
    let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] ?? []
    let percent = sources.lazy.compactMap { source -> Int? in
      guard
        let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue()
          as? [String: Any],
        description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
        let level = description[kIOPSCurrentCapacityKey] as? Int,
        let capacity = description[kIOPSMaxCapacityKey] as? Int, capacity > 0
      else { return nil }
      return level * 100 / capacity
    }.first
    return PowerSource(isOnBattery: providing == kIOPMBatteryPowerKey, batteryPercent: percent)
  }
}
