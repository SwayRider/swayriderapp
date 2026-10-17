import 'dart:async';

import 'package:flutter/services.dart';

/// Speaks short guidance phrases aloud.
abstract class SpeechService {
  /// Speaks [text] in [language] (a BCP-47 tag such as `nl-NL`) and
  /// completes once it has been spoken (or failed, or timed out). Calls
  /// should be made one at a time; `PromptQueue` does that. Other audio
  /// (music) is ducked while speaking. Never throws: a failing voice must
  /// not break navigation.
  Future<void> speak(String text, {required String language});

  /// Stops speaking immediately.
  Future<void> stop();
}

/// [SpeechService] on top of the app's own platform channel (`SpeechHandler`
/// on Android, `SpeechHandler` in `AppDelegate.swift` on iOS), using the
/// operating system's text-to-speech voices.
///
/// It is not a package because the common one forces CocoaPods on a Swift
/// Package Manager project (same reason as `CompassServiceChannel`), and the
/// native side needs to control audio focus / ducking for navigation prompts.
class SpeechServiceChannel implements SpeechService {
  SpeechServiceChannel({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.hevanto_it.swayriderapp/speech');

  final MethodChannel _channel;

  /// Longest a single prompt may block the queue.
  static const _speakTimeout = Duration(seconds: 15);

  @override
  Future<void> speak(String text, {required String language}) async {
    try {
      await _channel
          .invokeMethod<void>('speak', {'text': text, 'language': language})
          .timeout(_speakTimeout);
    } on TimeoutException {
      // The voice never reported back; carry on with the next prompt.
    } on PlatformException {
      // Ignore: guidance continues visually.
    } on MissingPluginException {
      // Platform without a speech handler (e.g. desktop tests).
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // Ignore.
    } on MissingPluginException {
      // Ignore.
    }
  }
}
