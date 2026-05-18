import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../../data/database/database.dart';
import '../../../main.dart';

// 剪贴板笔记列表
final notesProvider = StreamProvider<List<NoteData>>((ref) {
  return ref.watch(noteRepoProvider).watchAll();
});

// 捕获页状态
final captureContentProvider = StateProvider<String>((ref) => '');
final isRecordingProvider = StateProvider<bool>((ref) => false);
final captureNoteTypeProvider = StateProvider<String>((ref) => 'text');
final captureAudioPathProvider = StateProvider<String?>((ref) => null);
final captureImagePathProvider = StateProvider<String?>((ref) => null);
final isSavingProvider = StateProvider<bool>((ref) => false);

// 删除笔记（软删除）
final deleteNoteProvider = FutureProvider.family<void, int>((ref, noteId) async {
  await ref.watch(noteRepoProvider).softDelete(noteId);
});

// 保存笔记 — Provider 返回函数，不自动触发
final saveNoteAction = Provider<Future<bool> Function(String)>((ref) {
  return (String content) async {
    final imagePath = ref.read(captureImagePathProvider);
    final audioPath = ref.read(captureAudioPathProvider);
    if (content.trim().isEmpty && imagePath == null && audioPath == null) return false;

    final noteRepo = ref.read(noteRepoProvider);
    final noteType = ref.read(captureNoteTypeProvider);

    try {
      await noteRepo.insert(
        NotesCompanion(
          content: Value(content.trim()),
          type: Value(noteType),
          audioPath: Value(audioPath),
          imagePath: Value(imagePath),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      ref.read(captureContentProvider.notifier).state = '';
      ref.read(captureNoteTypeProvider.notifier).state = 'text';
      ref.read(captureAudioPathProvider.notifier).state = null;
      ref.read(captureImagePathProvider.notifier).state = null;

      return true;
    } catch (e) {
      return false;
    }
  };
});
