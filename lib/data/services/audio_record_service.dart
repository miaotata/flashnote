import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

class AudioRecordService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> isRecording() => _recorder.isRecording();
  Stream<RecordState> get stateStream => _recorder.onStateChanged();

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<String?> startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentPath = p.join(dir.path, 'voice_$timestamp.m4a');

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _currentPath!,
      );
      return _currentPath;
    }
    return null;
  }

  Future<String?> stopRecording() async {
    if (_currentPath != null && await _recorder.isRecording()) {
      final path = _currentPath;
      await _recorder.stop();
      _currentPath = null;
      // Verify file exists and has content
      final file = File(path!);
      if (await file.exists() && await file.length() > 0) {
        return path;
      }
    }
    return null;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
