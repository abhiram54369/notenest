// A note is a small data object. JSON makes it easy to save locally.
class Note {
  final String id;
  final String title;
  final String body;
  final String category;
  final bool pinned;
  final DateTime updated;
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.updated,
    this.pinned = false,
  });

  Note withPin(bool value) => Note(
    id: id,
    title: title,
    body: body,
    category: category,
    updated: updated,
    pinned: value,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'category': category,
    'pinned': pinned,
    'updated': updated.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    category: json['category'] as String,
    pinned: json['pinned'] as bool,
    updated: DateTime.parse(json['updated'] as String),
  );
}
