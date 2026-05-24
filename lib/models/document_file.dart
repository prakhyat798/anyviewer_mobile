class DocumentFile {
  final String name;
  final String path;
  final int size;
  final String extension;
  final DateTime openedAt;
  bool isStarred;
  List<String> tags;

  DocumentFile({
    required this.name,
    required this.path,
    required this.size,
    required this.extension,
    required this.openedAt,
    this.isStarred = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'size': size,
      'extension': extension,
      'openedAt': openedAt.toIso8601String(),
      'isStarred': isStarred,
      'tags': tags,
    };
  }

  factory DocumentFile.fromJson(Map<String, dynamic> json) {
    return DocumentFile(
      name: json['name'] as String,
      path: json['path'] as String,
      size: json['size'] as int,
      extension: json['extension'] as String,
      openedAt: DateTime.parse(json['openedAt'] as String),
      isStarred: json['isStarred'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

