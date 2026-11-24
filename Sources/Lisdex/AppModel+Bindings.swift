import Foundation
import LisdexCore

/// Settable views of the model for SwiftUI controls, bound with `Bindable(model).property`.
///
/// Why not `Binding(get:set: model.setX)`: Swift 6.3 (Xcode 26.x) crashes in IRGen converting
/// `@MainActor` methods into the SDK's `@isolated(any) @Sendable` setter. Key-path bindings
/// avoid the conversion. Each setter still goes through its intent, so saving and
/// reconciliation are unchanged.
extension AppModel {
  var keepAwakeSwitch: Bool {
    get { isOn }
    set { switchOn(newValue) }
  }

  var startOnLoginSwitch: Bool {
    get { loginItem != .off }
    set { setStartOnLogin(newValue) }
  }

  var activateOnLaunchSetting: Bool {
    get { settings.activateOnLaunch }
    set { setActivateOnLaunch(newValue) }
  }

  var notifyOnSessionEndSetting: Bool {
    get { settings.notifyOnSessionEnd }
    set { setNotifyOnSessionEnd(newValue) }
  }

  var playsToggleSoundSetting: Bool {
    get { settings.playsToggleSound }
    set { setPlaysToggleSound(newValue) }
  }

  var toggleSoundSetting: ToggleSound {
    get { settings.toggleSound }
    set { setToggleSound(newValue) }
  }

  var clickBehaviorSetting: StatusItemClickBehavior {
    get { settings.clickBehavior }
    set { setClickBehavior(newValue) }
  }

  var shortcutDurationSetting: TimeInterval {
    get { settings.shortcuts.durationSeconds }
    set { setShortcutDuration(newValue) }
  }

  var keepDisplayAwakeSetting: Bool {
    get { settings.keepDisplayAwake }
    set { setKeepDisplayAwake(newValue) }
  }

  var allowDisplaySleepOnBatterySetting: Bool {
    get { settings.allowDisplaySleepOnBattery }
    set { setAllowDisplaySleepOnBattery(newValue) }
  }

  var batteryStopThresholdSetting: BatteryThreshold {
    get { settings.batteryStopThreshold }
    set { setBatteryStopThreshold(newValue) }
  }

  var jigglerEnabledSetting: Bool {
    get { settings.jiggler.isEnabled }
    set { setJiggler(settings.jiggler.with(isEnabled: newValue)) }
  }

  var jigglerIdleThresholdSetting: Double {
    get { settings.jiggler.idleThreshold }
    set { setJiggler(settings.jiggler.with(idleThreshold: newValue)) }
  }

  var jigglerIntervalSetting: Double {
    get { settings.jiggler.interval }
    set { setJiggler(settings.jiggler.with(interval: newValue)) }
  }

  var engineSetting: KeepAwakeEngine {
    get { settings.engine }
    set { setEngine(newValue) }
  }
}
