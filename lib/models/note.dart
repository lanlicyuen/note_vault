import 'note_type.dart';
import 'command_group.dart';

/// Note 数据模型
class Note {
  final String id;
  final String title;
  final NoteType type;
  final String content;
  final String? value;
  final String? url;
  final List<String> tags;
  final bool isFavorite;
  final bool isArchived;
  final CommandGroup? commandGroup;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    this.value,
    this.url,
    List<String>? tags,
    this.isFavorite = false,
    this.isArchived = false,
    this.commandGroup,
    required this.createdAt,
    required this.updatedAt,
  }) : tags = tags ?? [];

  /// 复制并修改
  Note copyWith({
    String? id,
    String? title,
    NoteType? type,
    String? content,
    String? value,
    String? url,
    List<String>? tags,
    bool? isFavorite,
    bool? isArchived,
    CommandGroup? commandGroup,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      value: value ?? this.value,
      url: url ?? this.url,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      commandGroup: commandGroup ?? this.commandGroup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.value,
      'content': content,
      'value': value,
      'url': url,
      'tags': tags,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'commandGroup': commandGroup?.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 从 JSON 创建
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      type: NoteType.fromValue(json['type'] as String),
      content: json['content'] as String,
      value: json['value'] as String?,
      url: json['url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      commandGroup: CommandGroup.fromValue(json['commandGroup'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}