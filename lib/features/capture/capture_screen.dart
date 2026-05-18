import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'providers/capture_provider.dart';
import '../../data/services/audio_record_service.dart';
import '../../shared/widgets/recent_notes_list.dart';
import '../../shared/widgets/fullscreen_image.dart';
import '../../features/settings/providers/settings_provider.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _textController = TextEditingController();
  final _audioRecorder = AudioRecordService();
  bool _micReady = false;
  String? _imagePath;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initMic();
  }

  Future<void> _initMic() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (mounted) setState(() => _micReady = hasPermission);
    } catch (_) {
      if (mounted) setState(() => _micReady = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    try {
      _audioRecorder.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _save() async {
    final content = _textController.text;
    final hasAudio = _audioPath != null;
    if (content.trim().isEmpty && _imagePath == null && !hasAudio) return;

    ref.read(isSavingProvider.notifier).state = true;

    if (hasAudio) {
      ref.read(captureNoteTypeProvider.notifier).state = 'voice';
      ref.read(captureAudioPathProvider.notifier).state = _audioPath;
    }

    final saveFn = ref.read(saveNoteAction);
    final success = await saveFn(content);

    if (!mounted) return;
    ref.read(isSavingProvider.notifier).state = false;

    if (success) {
      _textController.clear();
      setState(() {
        _imagePath = null;
        _audioPath = null;
      });
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          title: Text('已保存'),
          content: Text('想法已记录'),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          title: Text('保存失败'),
          content: Text('请重试'),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null && mounted) {
      setState(() => _imagePath = xFile.path);
      ref.read(captureImagePathProvider.notifier).state = xFile.path;
    }
  }

  Future<void> _toggleVoice() async {
    try {
      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stopRecording();
        if (path != null && mounted) {
          setState(() => _audioPath = path);
        }
        ref.read(isRecordingProvider.notifier).state = false;
      } else {
        if (!_micReady) {
          final hasPermission = await _audioRecorder.hasPermission();
          if (!hasPermission) {
            if (mounted) {
              showCupertinoDialog(
                context: context,
                builder: (_) => const CupertinoAlertDialog(
                  title: Text('麦克风不可用'),
                  content: Text('请在系统设置中授予麦克风权限'),
                ),
              );
            }
            return;
          }
          setState(() => _micReady = true);
        }
        ref.read(isRecordingProvider.notifier).state = true;
        final path = await _audioRecorder.startRecording();
        if (path == null && mounted) {
          ref.read(isRecordingProvider.notifier).state = false;
          showCupertinoDialog(
            context: context,
            builder: (_) => const CupertinoAlertDialog(
              title: Text('录音失败'),
              content: Text('无法启动录音，请检查麦克风权限'),
            ),
          );
        }
      }
    } catch (_) {
      ref.read(isRecordingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);
    final isSaving = ref.watch(isSavingProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('闪念笔记')),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoTextField(
                    controller: _textController,
                    placeholder: '记录你的想法...',
                    maxLines: 3,
                    textAlignVertical: TextAlignVertical.top,
                    padding: const EdgeInsets.all(12),
                    style: const TextStyle(fontSize: 17),
                    autofocus: false,
                  ),
                  const SizedBox(height: 8),
                  if (isRecording)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            CupertinoColors.systemRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.waveform,
                              color: CupertinoColors.systemRed, size: 20),
                          SizedBox(width: 8),
                          Text('正在录音...',
                              style: TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  if (_audioPath != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.checkmark_circle_fill,
                              color: CupertinoColors.systemGreen, size: 18),
                          const SizedBox(width: 6),
                          const Text('录音已保存',
                              style: TextStyle(
                                  color: CupertinoColors.systemGreen,
                                  fontSize: 13)),
                          const Spacer(),
                          CupertinoButton(
                            padding: const EdgeInsets.all(4),
                            onPressed: () =>
                                setState(() => _audioPath = null),
                            child: const Icon(CupertinoIcons.xmark,
                                size: 16, color: CupertinoColors.systemGrey),
                          ),
                        ],
                      ),
                    ),
                  if (_imagePath != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(CupertinoPageRoute(
                          builder: (_) =>
                              FullScreenImage(imagePath: _imagePath!),
                        ));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Image.file(File(_imagePath!),
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CupertinoButton(
                                padding: const EdgeInsets.all(4),
                                color: CupertinoColors.black
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                onPressed: () {
                                  setState(() => _imagePath = null);
                                  ref
                                      .read(captureImagePathProvider.notifier)
                                      .state = null;
                                },
                                child: const Icon(CupertinoIcons.xmark,
                                    color: CupertinoColors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(10),
                        onPressed: _toggleVoice,
                        child: Icon(
                          isRecording
                              ? CupertinoIcons.stop_fill
                              : CupertinoIcons.mic,
                          color: isRecording
                              ? CupertinoColors.systemRed
                              : CupertinoDynamicColor.resolve(
                                  CupertinoColors.secondaryLabel, context),
                          size: 24,
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.all(10),
                        onPressed: _pickImage,
                        child: Icon(CupertinoIcons.camera,
                            color: CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel, context),
                            size: 24),
                      ),
                      CupertinoButton.filled(
                        onPressed: isSaving ? null : _save,
                        child: isSaving
                            ? const CupertinoActivityIndicator()
                            : const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: CupertinoColors.separator),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  const Text('最近记录',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  _SortModeLabel(),
                ],
              ),
            ),
            const Expanded(child: RecentNotesList()),
          ],
        ),
      ),
    );
  }
}

class _SortModeLabel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(taskSortModeProvider);
    return GestureDetector(
      onTap: () => _showSortPicker(context, ref, mode),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ref.watch(sortModeLabelProvider),
              style: TextStyle(
                  fontSize: 11, color: CupertinoColors.activeBlue)),
          const Icon(CupertinoIcons.chevron_down,
              size: 12, color: CupertinoColors.activeBlue),
        ],
      ),
    );
  }

  void _showSortPicker(BuildContext context, WidgetRef ref, String mode) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('排序方式'),
        actions: [
          _sortOption(context, ref, 'created', '创建时间'),
          _sortOption(context, ref, 'updated', '编辑时间'),
          _sortOption(context, ref, 'priority', '重要程度'),
          _sortOption(context, ref, 'urgency', '紧急程度'),
          _sortOption(context, ref, 'completed', '完成时间'),
          _sortOption(context, ref, 'manual', '手动排序'),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _sortOption(
      BuildContext context, WidgetRef ref, String value, String label) {
    final current = ref.read(taskSortModeProvider);
    return CupertinoActionSheetAction(
      onPressed: () {
        ref.read(taskSortModeProvider.notifier).setMode(value);
        Navigator.pop(context);
      },
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label),
        if (current == value)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(CupertinoIcons.checkmark_alt, size: 16),
          ),
      ]),
    );
  }
}
