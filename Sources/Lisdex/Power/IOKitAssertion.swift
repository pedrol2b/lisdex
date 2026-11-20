import IOKit.pwr_mgt
import LisdexCore

/// Default engine (ADR 0002): named IOKit power assertions held by this process. macOS drops
/// them automatically if Lisdex quits or crashes, so nothing can be left behind.
@MainActor
final class IOKitAssertion: PowerHold {
  struct Failure: Error, CustomStringConvertible {
    let type: String
    let code: IOReturn
    var description: String { "IOPMAssertionCreateWithName(\(type)) failed: \(code)" }
  }

  private var ids: [IOPMAssertionID]

  init(_ request: PowerRequest) throws {
    let types =
      [kIOPMAssertPreventUserIdleSystemSleep]
      + (request.keepsDisplayAwake ? [kIOPMAssertPreventUserIdleDisplaySleep] : [])
    var created: [IOPMAssertionID] = []
    for type in types {
      var id = IOPMAssertionID(0)
      let result = IOPMAssertionCreateWithName(
        type as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), request.reason as CFString, &id
      )
      guard result == kIOReturnSuccess else {
        for id in created { IOPMAssertionRelease(id) }
        throw Failure(type: type, code: result)
      }
      created.append(id)
    }
    ids = created
    Log.power.notice(
      "IOKit assertions held (\(created.count, privacy: .public)): \(request.reason, privacy: .public)"
    )
  }

  func release() {
    for id in ids { IOPMAssertionRelease(id) }
    ids = []
    Log.power.notice("IOKit assertions released")
  }
}
