import Flutter
import HealthKitReporter

public class SwiftHealthKitReporterPlugin: NSObject, FlutterPlugin {
    var reporter: HealthKitReporter?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftHealthKitReporterPlugin()

        instance.reporter = HealthKitReporter()

        let binaryMessenger = registrar.messenger()
        registerMethodChannel(
            registrar: registrar,
            binaryMessenger: binaryMessenger,
            instance: instance
        )

        do {
            if let reporter = instance.reporter {
                try registerEventChannel(
                    binaryMessenger: binaryMessenger,
                    reporter: reporter
                )
            }
        } catch {
            print(error)
        }
        registrar.addApplicationDelegate(instance)
    }
    private static func registerMethodChannel(
        registrar: FlutterPluginRegistrar,
        binaryMessenger: FlutterBinaryMessenger,
        instance: SwiftHealthKitReporterPlugin
    ) {
        for method in MethodChannel.allCases {
            let methodChannel = FlutterMethodChannel(
                name: method.rawValue,
                binaryMessenger: binaryMessenger
            )
            registrar.addMethodCallDelegate(instance, channel: methodChannel)
        }
    }
    private static func registerEventChannel(
        binaryMessenger: FlutterBinaryMessenger,
        reporter: HealthKitReporter
    ) throws {
        for event in EventChannel.allCases {
            let eventChannel = FlutterEventChannel(
                name: event.rawValue,
                binaryMessenger: binaryMessenger
            )
            let streamHandler = try StreamHandlerFactory.make(with: reporter, for: event)
            eventChannel.setStreamHandler(streamHandler)
        }
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        let items = ["HKQuantityTypeIdentifierHeartRate",     "HKQuantityTypeIdentifierSixMinuteWalkTestDistance",
                     "HKQuantityTypeIdentifierVO2Max",
                     "HKWorkoutTypeIdentifier"
        ].map { $0.objectType }.compactMap { $0 }
        for item in items {
            reporter?.observer.enableBackgroundDelivery(type: item, frequency: .immediate) { status, error in
                print("\(#file): enableBackgroundDelivery \(item) \(status)")
            }
        }
        return true
    }
}
