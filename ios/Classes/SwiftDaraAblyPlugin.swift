import Ably
import Flutter
import UIKit

public typealias Args = [String: Any?]

public class SwiftDaraAblyPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        _ = SwiftDaraAblyPlugin(registrar)
    }
    
    var channel: FlutterMethodChannel
    var registrar: FlutterPluginRegistrar
    
    var instances: [Int: ARTRealtime] = [:]
    var callbacks: [String: (Args) -> Void] = [:]

    init(_ registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        channel = FlutterMethodChannel(name: "network.dara.dara_ably", binaryMessenger: registrar.messenger())
        super.init()
        registrar.addMethodCallDelegate(self, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! Args
        if let callback = callbacks[call.method] {
            callback(args)
            return
        }
        
        let rtHashCode = args["rtHashCode"] as! Int
    
        switch call.method {
        case "Realtime()":
            realtimeInit(args, rtHashCode)
        case "Connection()":
            connectionInit(args, rtHashCode)
        case "Connection.close()":
            connectionClose(args, rtHashCode)
        case "Channel()":
            channelInit(args, rtHashCode)
        case "Channel.publish()":
            channelPublish(args, rtHashCode)
        case "Channel.subscribe()":
            channelSubscribe(args, rtHashCode)
        case "Channel.unsubscribe()":
            channelUnsubscribe(args, rtHashCode)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func realtimeInit(_ args: Args, _ rtHashCode: Int) {
        let clientId = args["clientId"] as? String
        let authCallback = args["authCallback"] as! String
        
        let options = ARTClientOptions()
        options.clientId = clientId
        options.authCallback = { _, callback in
            self.channel.invokeMethod(authCallback, arguments: [
                "tokenCallback": self.allowInterop { args in
                    let token = args["token"] as! String
                    callback(token as ARTTokenDetailsCompatible, nil)
                },
            ])
        }

        let realtime = ARTRealtime(options: options)
        instances[rtHashCode] = realtime
    }
    
    func connectionInit(_ args: Args, _ rtHashCode: Int) {
        let stateCallback = args["stateCallback"] as! String
        
        if let realtime = instances[rtHashCode] {
            realtime.connection.on { _stateChange in
                if let stateChange = _stateChange {
                    self.channel.invokeMethod(stateCallback, arguments: [
                        "state": connectionStateName(stateChange.current),
                    ])
                }
            }
        }
    }
    
    func connectionClose(_ args: Args, _ rtHashCode: Int) {
        if let realtime = instances[rtHashCode] {
            realtime.connection.close()
        }
    }

    func channelPublish(_ args: Args, _ rtHashCode: Int) {
        let channelName = args["channelName"] as! String
        let eventName = args["eventName"] as! String
        let data = args["data"] as! FlutterStandardTypedData
        
        if let realtime = instances[rtHashCode] {
            let channel = realtime.channels.get(channelName)
            channel.publish(eventName, data: data.data)
        }
    }
    
    func channelInit(_ args: Args, _ rtHashCode: Int) {
        let channelName = args["channelName"] as! String
        let stateCallback = args["stateCallback"] as! String
        
        if let realtime = instances[rtHashCode] {
            let channel = realtime.channels.get(channelName)
            channel.on { _stateChange in
                if let stateChange = _stateChange {
                    self.channel.invokeMethod(stateCallback, arguments: [
                        "state": channelStateName(stateChange.current),
                    ])
                }
            }
        }
    }
    
    func channelSubscribe(_ args: Args, _ rtHashCode: Int) {
        let channelName = args["channelName"] as! String
        let listener = args["listener"] as! String
        
        if let realtime = instances[rtHashCode] {
            let channel = realtime.channels.get(channelName)
            channel.subscribe { msg in
                self.channel.invokeMethod(listener, arguments: [
                    "data": msg.data,
                ])
            }
        }
    }

    func channelUnsubscribe(_ args: Args, _ rtHashCode: Int) {
        let channelName = args["channelName"] as! String
        
        if let realtime = instances[rtHashCode] {
            let channel = realtime.channels.get(channelName)
            channel.unsubscribe()
        }
    }

    func allowInterop(_ fn: @escaping (Args) -> Void) -> String {
        let name = "swiftCallbacks/\(Double.random(in: 0 ... 1))"
        callbacks[name] = fn
        return name
    }
}

func connectionStateName(_ state: ARTRealtimeConnectionState) -> String {
    switch state {
    case .initialized: return "initialized"
    case .connecting: return "connecting"
    case .connected: return "connected"
    case .disconnected: return "disconnected"
    case .suspended: return "disconnected"
    case .closing: return "closing"
    case .closed: return "closed"
    case .failed: return "failed"
    @unknown default: return ""
    }
}

func channelStateName(_ state: ARTRealtimeChannelState) -> String {
    switch state {
    case .initialized: return "initialized"
    case .attaching: return "attaching"
    case .attached: return "attached"
    case .detaching: return "detaching"
    case .detached: return "detached"
    case .suspended: return "suspended"
    case .failed: return "failed"
    @unknown default: return ""
    }
}
