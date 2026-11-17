import Flutter
import HealthKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let healthChanges = HealthKitChangeStreamHandler()
  private var healthChangesChannel: FlutterEventChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    healthChangesChannel = FlutterEventChannel(
      name: "boxer_recovery/health_changes",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    healthChangesChannel?.setStreamHandler(healthChanges)
  }
}

/// Observer queries signal that HealthKit changed; Flutter performs the same
/// authorized 14-day read used by manual sync. No health values cross here.
private final class HealthKitChangeStreamHandler: NSObject, FlutterStreamHandler {
  private let store = HKHealthStore()
  private var queries: [HKObserverQuery] = []
  private var sink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard HKHealthStore.isHealthDataAvailable() else {
      return FlutterError(code: "health_unavailable", message: "HealthKit is unavailable.", details: nil)
    }
    stopObserving()
    sink = events

    var types: [HKSampleType] = [HKObjectType.workoutType()]
    if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
      types.append(sleep)
    }
    for identifier in [
      HKQuantityTypeIdentifier.heartRateVariabilitySDNN,
      .restingHeartRate,
      .heartRate
    ] {
      if let type = HKObjectType.quantityType(forIdentifier: identifier) {
        types.append(type)
      }
    }

    for type in types {
      let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completion, error in
        defer { completion() }
        guard error == nil else { return }
        DispatchQueue.main.async { self?.sink?("changed") }
      }
      queries.append(query)
      store.execute(query)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopObserving()
    return nil
  }

  private func stopObserving() {
    sink = nil
    for query in queries { store.stop(query) }
    queries.removeAll()
  }
}
