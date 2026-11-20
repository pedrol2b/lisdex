/// Something currently keeping the Mac awake (an IOKit assertion, a caffeinate process).
@MainActor
public protocol PowerHold: AnyObject {
  /// Stop holding. Called exactly once.
  func release()
}

/// Reconciles the desired `PowerRequest` with what is actually held. Engine-agnostic: the
/// app injects `acquire`, tests inject a fake. A change starts the new hold *before*
/// releasing the old one, so the Mac never gets a window to fall asleep (ADR 0002).
@MainActor
public final class PowerCoordinator {
  public typealias Acquire = @MainActor (PowerRequest) throws -> any PowerHold

  private let acquire: Acquire
  private var held: (request: PowerRequest, hold: any PowerHold)?

  public init(acquire: @escaping Acquire) {
    self.acquire = acquire
  }

  /// The request being held, if any.
  public var current: PowerRequest? { held?.request }

  /// Makes `request` the held state. On failure the previous hold is kept and the error rethrown.
  public func apply(_ request: PowerRequest?) throws {
    guard request != current else { return }
    let next = try request.map { (request: $0, hold: try acquire($0)) }
    held?.hold.release()
    held = next
  }
}
