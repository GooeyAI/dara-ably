package network.dara.dara_ably

import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.ably.lib.realtime.AblyRealtime
import io.ably.lib.rest.Auth
import io.ably.lib.types.ClientOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.CountDownLatch
import kotlin.random.Random

val handler = Handler(Looper.getMainLooper())

/** DaraAblyPlugin */
class DaraAblyPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var methodChannel: MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "network.dara.dara_ably")
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    val instances = mutableMapOf<Int, AblyRealtime>()
    val callbacks = mutableMapOf<String, (MethodCall) -> Unit>()

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (callbacks.containsKey(call.method)) {
            callbacks[call.method]?.let {
                it(call)
            }
            return
        }

        val rtHashCode = call.argument<Int>("rtHashCode")!!

        when (call.method) {
            "Realtime()" -> realtimeInit(call, rtHashCode)
            "Connection()" -> connectionInit(call, rtHashCode)
            "Connection.close()" -> connectionClose(call, rtHashCode)
            "Connection.connect()" -> connectionConnect(call, rtHashCode)
            "Channel()" -> channelInit(call, rtHashCode)
            "Channel.publish()" -> connectionPublish(call, rtHashCode)
            "Channel.subscribe()" -> connectionSubscribe(call, rtHashCode)
            "Channel.unsubscribe()" -> connectionUnsubscribe(call, rtHashCode)
        }
    }

    fun realtimeInit(call: MethodCall, rtHashCode: Int) {
        val clientId = call.argument<String>("clientId")!!
        val authCallback = call.argument<String>("authCallback")!!

        val options = ClientOptions()
        options.clientId = clientId
        options.authCallback = Auth.TokenCallback { _ ->
            val tokenSignal = CountDownLatch(1)
            lateinit var token: String

            handler.post {
                methodChannel.invokeMethod(
                    authCallback, hashMapOf(
                        "tokenCallback" to allowInterop { call ->
                            token = call.argument<String>("token")!!
                            tokenSignal.countDown()
                        }
                    )
                )
            }

            tokenSignal.await()
            token
        }

        val realtime = AblyRealtime(options)
        instances[rtHashCode] = realtime
    }

    fun connectionInit(call: MethodCall, rtHashCode: Int) {
        val stateCallback = call.argument<String>("stateCallback")!!

        instances[rtHashCode]?.let { realtime ->
            realtime.connection.on { stateChange ->
                handler.post {
                    methodChannel.invokeMethod(
                        stateCallback, mapOf(
                            "state" to stateChange.current.name
                        )
                    )
                }
            }
        }
    }

    fun connectionClose(call: MethodCall, rtHashCode: Int) {
        instances[rtHashCode]?.let { realtime ->
            realtime.connection.close()
        }
    }

    fun connectionConnect(call: MethodCall, rtHashCode: Int) {
        instances[rtHashCode]?.let { realtime ->
            realtime.connection.connect()
        }
    }

    fun channelInit(call: MethodCall, rtHashCode: Int) {
        val channelName = call.argument<String>("channelName")!!
        val stateCallback = call.argument<String>("stateCallback")!!

        instances[rtHashCode]?.let { realtime ->
            val channel = realtime.channels.get(channelName)
            channel.on { stateChange ->
                handler.post {
                    methodChannel.invokeMethod(
                        stateCallback, mapOf(
                            "state" to stateChange.current.name
                        )
                    )
                }
            }
        }
    }

    fun connectionPublish(call: MethodCall, rtHashCode: Int) {
        val channelName = call.argument<String>("channelName")!!
        val eventName = call.argument<String>("eventName")!!
        val data = call.argument<ByteArray>("data")!!

        instances[rtHashCode]?.let { realtime ->
            val channel = realtime.channels.get(channelName)
            channel.publish(eventName, data)
        }
    }

    fun connectionSubscribe(call: MethodCall, rtHashCode: Int) {
        val channelName = call.argument<String>("channelName")!!
        val listener = call.argument<String>("listener")!!

        instances[rtHashCode]?.let { realtime ->
            val channel = realtime.channels.get(channelName)
            channel.subscribe { msg ->
                handler.post {
                    methodChannel.invokeMethod(
                        listener, mapOf(
                            "data" to msg.data
                        )
                    )
                }
            }
        }
    }

    fun connectionUnsubscribe(call: MethodCall, rtHashCode: Int) {
        val channelName = call.argument<String>("channelName")!!

        instances[rtHashCode]?.let { realtime ->
            val channel = realtime.channels.get(channelName)
            channel.unsubscribe()
        }
    }

    fun allowInterop(fn: (MethodCall) -> Unit): String {
        val name = "kotlinCallbacks/${Random.nextDouble()}"
        callbacks[name] = fn
        return name
    }
}
