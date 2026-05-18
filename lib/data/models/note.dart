/// 笔记领域模型（非 Drift 生成的 DataClassName）
class Note {
  final int id;
  final String content;
  final String type; // 'text' | 'voice'
  final String? audioPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.content,
    required this.type,
    this.audioPath,
    required this.createdAt,
    required this.updatedAt,
  });
}
