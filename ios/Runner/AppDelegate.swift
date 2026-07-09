import Flutter
import UIKit
import CoreMotion

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var baselineAngle: Double = 0
    private var lastAngle: Double = 0
    private let threshold: Double = 15.0

    private var totalSeconds = 0
    private var badTotalSeconds = 0
    private var badContinuousSeconds = 0

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "jjibudung/posture_service",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {
            case "startService":
                if let args = call.arguments as? [String: Any],
                   let baseline = args["baselineAngle"] as? Double {
                    self.startMonitoring(baseline: baseline)
                }
                result(true)
            case "stopService":
                self.stopMonitoring()
                result(true)
            case "getTimes":
                result([
                    "total": self.totalSeconds,
                    "badTotal": self.badTotalSeconds,
                    "badContinuous": self.badContinuousSeconds
                ])
            case "resetTimes":
                self.totalSeconds = 0
                self.badTotalSeconds = 0
                self.badContinuousSeconds = 0
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func startMonitoring(baseline: Double) {
        baselineAngle = baseline
        totalSeconds = 0
        badTotalSeconds = 0
        badContinuousSeconds = 0

        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                if let data = data {
                    self?.lastAngle = data.acceleration.y * 10
                }
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.totalSeconds += 1
            let diff = abs(self.lastAngle - self.baselineAngle)
            if diff >= self.threshold {
                self.badTotalSeconds += 1
                self.badContinuousSeconds += 1
            } else {
                self.badContinuousSeconds = 0
            }
        }
    }

    private func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        timer?.invalidate()
        timer = nil
    }
}
