import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  String _lastTranscription = '';
  String? lastError;

  bool get isInitialized => _initialized;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onStatus: (status) {},
        onError: (error) {
          lastError = error.errorMsg;
        },
      );
      if (!_initialized) {
        lastError = '语音服务不可用（可能未授权或设备不支持）';
      }
    } catch (e) {
      _initialized = false;
      lastError = e.toString();
    }
    return _initialized;
  }

  Stream<String> startListening() {
    _lastTranscription = '';
    final controller = StreamController<String>.broadcast();

    _speech.listen(
      onResult: (result) {
        _lastTranscription = result.recognizedWords;
        controller.add(_lastTranscription);
      },
      localeId: 'zh_CN',
    );

    return controller.stream;
  }

  Future<String> stopListening() async {
    await _speech.stop();
    return _lastTranscription;
  }

  void dispose() {
    _speech.cancel();
  }
}
