class Note {
  final String id;
  final String title;
  final String content;
  final String category;
  final String color;
  final DateTime createdAt;
  final DateTime? reminderTime;
  final bool isPinned;
  final bool isArchived;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    required this.createdAt,
    this.reminderTime,
    this.isPinned = false,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'color': color,
    'createdAt': createdAt.toIso8601String(),
    'reminderTime': reminderTime?.toIso8601String(),
    'isPinned': isPinned ? 1 : 0,
    'isArchived': isArchived ? 1 : 0,
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'],
    title: map['title'],
    content: map['content'],
    category: map['category'],
    color: map['color'],
    createdAt: DateTime.parse(map['createdAt']),
    reminderTime: map['reminderTime'] != null
        ? DateTime.parse(map['reminderTime'])
        : null,
    isPinned: map['isPinned'] == 1,
    isArchived: map['isArchived'] == 1,
  );

  Note copyWith({
    String? title,
    String? content,
    String? category,
    String? color,
    DateTime? reminderTime,
    bool? isPinned,
    bool? isArchived,
  }) => Note(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    category: category ?? this.category,
    color: color ?? this.color,
    createdAt: createdAt,
    reminderTime: reminderTime ?? this.reminderTime,
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
  );
}
