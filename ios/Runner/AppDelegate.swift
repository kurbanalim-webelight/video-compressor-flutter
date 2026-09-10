import BackgroundTasks
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let backgroundTask = BackgroundTaskBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    backgroundTask.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// Lives in AppDelegate.swift rather than its own file so that no Xcode
// project change is needed to compile it.

/// Keeps the app running while `v_video_compressor` encodes.
///
/// iOS 26 added `BGContinuedProcessingTask` for exactly this case: work the
/// user started that ought to finish even after the app leaves the screen. It
/// draws its own system progress UI, which is why there is no Live Activity
/// or widget extension anywhere in here.
///
/// Below iOS 26 nothing equivalent exists. A background task assertion buys
/// roughly thirty seconds and `AVAssetExportSession` frequently gives up when
/// the app suspends regardless, so `supportsBackground` answers false and the
/// Dart side warns the user instead of promising something it cannot do.
final class BackgroundTaskBridge {

    private static let channelName = "com.webelight.poc/background_task"
    private static let taskIdentifier = "com.webelight.poc.compression"

    private var assertion = UIBackgroundTaskIdentifier.invalid
    private var activeTask: AnyObject?
    private var percent: Int64 = 0
    private var loggedTenth: Int64 = -1

    private func log(_ message: String) {
        NSLog("[background_task] \(message)")
    }

    /// Wires up the channel and, on iOS 26+, the launch handler.
    ///
    /// Call this from `didFinishLaunchingWithOptions`: task handlers have to
    /// be registered before launch finishes.
    ///
    /// Takes the registry rather than a messenger because this app is
    /// scene-based (`FlutterSceneDelegate`), so `window` -- and any view
    /// controller hanging off it -- is still nil at launch. The registrar is
    /// the same route every plugin takes, and it works either way.
    func register(with registry: FlutterPluginRegistry) {
        guard let messenger = registry.registrar(forPlugin: "BackgroundTaskBridge")?.messenger() else {
            NSLog("[background_task] no registrar; channel not registered")
            return
        }

        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        log("channel registered")

        if #available(iOS 26.0, *) {
            registerLaunchHandler()
        } else {
            log("iOS \(UIDevice.current.systemVersion): no continued processing task, so no system progress UI")
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "supportsBackground":
            if #available(iOS 26.0, *) {
                result(true)
            } else {
                result(false)
            }

        case "start":
            let arguments = call.arguments as? [String: Any]
            start(
                title: arguments?["title"] as? String ?? "Compressing video",
                subtitle: arguments?["subtitle"] as? String ?? ""
            )
            result(nil)

        case "update":
            let fraction = (call.arguments as? [String: Any])?["progress"] as? Double ?? 0
            update(fraction: fraction)
            result(nil)

        case "stop":
            stop()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func start(title: String, subtitle: String) {
        percent = 0
        loggedTenth = -1
        log("start: \(title) / \(subtitle)")
        beginAssertion()

        if #available(iOS 26.0, *) {
            submitContinuedTask(title: title, subtitle: subtitle)
        } else {
            log("iOS 26 required for the system progress UI; holding a ~30s assertion only")
        }
    }

    private func update(fraction: Double) {
        percent = Int64((min(max(fraction, 0), 1) * 100).rounded())

        if #available(iOS 26.0, *), let task = activeTask as? BGContinuedProcessingTask {
            task.progress.completedUnitCount = percent
        }

        // Every tenth only: this is called for each whole percent.
        let tenth = percent / 10
        if tenth != loggedTenth {
            loggedTenth = tenth
            log("progress \(percent)%\(activeTask == nil ? " (no system UI attached)" : " -> system UI")")
        }
    }

    private func stop() {
        log("stop")
        finishTask(success: true)
        endAssertion()
    }

    // MARK: - Background task assertion (all versions)

    /// Worth about thirty seconds. On iOS 26 it only has to cover the moment
    /// between the app backgrounding and the continued task taking over.
    private func beginAssertion() {
        guard assertion == .invalid else { return }
        assertion = UIApplication.shared.beginBackgroundTask(withName: "video-compression") { [weak self] in
            self?.log("background assertion expired")
            self?.endAssertion()
        }
        log("background assertion held")
    }

    private func endAssertion() {
        guard assertion != .invalid else { return }
        UIApplication.shared.endBackgroundTask(assertion)
        assertion = .invalid
    }

    // MARK: - Continued processing task (iOS 26+)

    /// Registered exactly once, from launch. The system kills the app if the
    /// same identifier is registered twice.
    @available(iOS 26.0, *)
    private func registerLaunchHandler() {
        let registered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self, let task = task as? BGContinuedProcessingTask else { return }

            self.activeTask = task
            task.progress.totalUnitCount = 100
            task.progress.completedUnitCount = self.percent
            task.expirationHandler = { [weak self] in
                self?.log("system expired the task; the encode loses its protection")
                self?.finishTask(success: false)
            }

            // The system UI appears once this runs, not when submit returns.
            self.log("task granted; system progress UI is live")

            // Deliberately returns without completing the task. The encode
            // this is protecting runs on the Dart side, and the task stays
            // alive -- holding the process up with it -- until `stop` lands.
        }

        log(
            registered
                ? "launch handler registered for \(Self.taskIdentifier)"
                : "REGISTRATION FAILED: \(Self.taskIdentifier) missing from BGTaskSchedulerPermittedIdentifiers"
        )
    }

    /// The scheduler force-expires tasks that look stalled, so the progress
    /// arriving through `update` is what keeps this alive -- submitting it is
    /// not enough on its own.
    @available(iOS 26.0, *)
    private func submitContinuedTask(title: String, subtitle: String) {
        let request = BGContinuedProcessingTaskRequest(
            identifier: Self.taskIdentifier,
            title: title,
            subtitle: subtitle
        )

        // The encode is already running, so a slot offered later is no use.
        request.strategy = .fail

        // Hardware encoding leans on the GPU, but asking for it is rejected
        // outright unless the app carries the matching entitlement and the
        // device supports background GPU work. Ask when the device says it
        // can, then fall back rather than losing the task over it.
        let wantsGPU = BGTaskScheduler.supportedResources.contains(.gpu)
        log("device supports background GPU: \(wantsGPU)")
        if wantsGPU {
            request.requiredResources = .gpu
        }

        do {
            try BGTaskScheduler.shared.submit(request)
            log("submitted\(wantsGPU ? " with GPU" : ""); waiting for the system to grant it")
            return
        } catch {
            guard wantsGPU else {
                log("SUBMIT REFUSED: \(error)")
                return
            }
            log("GPU resource refused, retrying without it: \(error)")
        }

        request.requiredResources = []
        do {
            try BGTaskScheduler.shared.submit(request)
            log("submitted without GPU; waiting for the system to grant it")
        } catch {
            log("SUBMIT REFUSED: \(error)")
        }
    }

    private func finishTask(success: Bool) {
        if #available(iOS 26.0, *), let task = activeTask as? BGContinuedProcessingTask {
            task.setTaskCompleted(success: success)
            log("task completed (success: \(success))")
        }
        activeTask = nil
    }
}
