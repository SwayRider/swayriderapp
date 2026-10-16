package com.hevanto_it.swayriderapp

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * Speaks navigation prompts with the system text-to-speech engine.
 *
 * Channel methods: `speak {text, language}` (flushes whatever is being spoken)
 * and `stop`. Other audio is ducked while a prompt is spoken, via audio focus
 * with the navigation-guidance usage.
 */
class SpeechHandler(context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.hevanto_it.swayriderapp/speech"
    }

    private val audioManager =
        context.applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()
    private val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        .setAudioAttributes(attributes)
        .build()

    private var ready = false
    private var pending: Pair<String, String>? = null
    private var utteranceCounter = 0

    private val tts: TextToSpeech = TextToSpeech(context.applicationContext) { status ->
        ready = status == TextToSpeech.SUCCESS
        if (ready) {
            pending?.let { (text, language) -> speak(text, language) }
        }
        pending = null
    }.also { engine ->
        engine.setAudioAttributes(attributes)
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) = abandonFocus()
            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) = abandonFocus()
            override fun onStop(utteranceId: String?, interrupted: Boolean) = abandonFocus()
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
                if (ready) speak(text, language) else pending = text to language
                result.success(null)
            }
            "stop" -> {
                pending = null
                tts.stop()
                abandonFocus()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun speak(text: String, language: String) {
        tts.language = Locale.forLanguageTag(language)
        audioManager.requestAudioFocus(focusRequest)
        tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "nav-${utteranceCounter++}")
    }

    private fun abandonFocus() {
        audioManager.abandonAudioFocusRequest(focusRequest)
    }

    fun dispose() {
        tts.stop()
        tts.shutdown()
        abandonFocus()
    }
}
