package com.hevanto_it.swayriderapp

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * Speaks navigation prompts with the system text-to-speech engine.
 *
 * Channel methods: `speak {text, language}` (queued behind whatever is being
 * spoken; the call returns once the phrase has been spoken) and `stop`
 * (silences everything and completes all waiting calls). Other audio is
 * ducked while prompts are spoken, via audio focus with the
 * navigation-guidance usage.
 */
class SpeechHandler(context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.hevanto_it.swayriderapp/speech"
    }

    private class Request(val text: String, val language: String, val result: MethodChannel.Result)

    private val audioManager =
        context.applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()
    private val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        .setAudioAttributes(attributes)
        .build()
    private val main = Handler(Looper.getMainLooper())

    private var ready = false
    private var initFinished = false
    private val beforeReady = mutableListOf<Request>()

    /** Calls waiting for their utterance to finish. Main thread only. */
    private val waiting = mutableMapOf<String, MethodChannel.Result>()
    private var utteranceCounter = 0

    private val tts: TextToSpeech = TextToSpeech(context.applicationContext) { status ->
        ready = status == TextToSpeech.SUCCESS
        initFinished = true
        main.post {
            val queued = beforeReady.toList()
            beforeReady.clear()
            for (request in queued) {
                if (ready) enqueue(request) else request.result.success(null)
            }
        }
    }.also { engine ->
        engine.setAudioAttributes(attributes)
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) = finish(utteranceId)
            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) = finish(utteranceId)
            override fun onStop(utteranceId: String?, interrupted: Boolean) = finish(utteranceId)
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "speak" -> {
                val text = call.argument<String>("text")
                val language = call.argument<String>("language") ?: "en-US"
                if (text.isNullOrBlank()) {
                    result.success(null)
                    return
                }
                val request = Request(text, language, result)
                when {
                    ready -> enqueue(request)
                    initFinished -> result.success(null)
                    else -> beforeReady.add(request)
                }
            }
            "stop" -> {
                silence()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun enqueue(request: Request) {
        val id = "nav-${utteranceCounter++}"
        waiting[id] = request.result
        tts.language = Locale.forLanguageTag(request.language)
        audioManager.requestAudioFocus(focusRequest)
        if (tts.speak(request.text, TextToSpeech.QUEUE_ADD, null, id) != TextToSpeech.SUCCESS) {
            finish(id)
        }
    }

    /** Completes the call for [id]; audio focus is released with the last one. */
    private fun finish(id: String?) {
        main.post {
            id?.let { waiting.remove(it)?.success(null) }
            if (waiting.isEmpty()) abandonFocus()
        }
    }

    private fun silence() {
        val queued = beforeReady.toList()
        beforeReady.clear()
        queued.forEach { it.result.success(null) }
        tts.stop()
        val open = waiting.values.toList()
        waiting.clear()
        open.forEach { it.success(null) }
        abandonFocus()
    }

    private fun abandonFocus() {
        audioManager.abandonAudioFocusRequest(focusRequest)
    }

    fun dispose() {
        silence()
        tts.shutdown()
    }
}
