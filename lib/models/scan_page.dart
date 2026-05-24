class ScanPage {
  final String id;
  final String imagePath;
  String filter;
  final DateTime timestamp;

  ScanPage({
    required this.id,
    required this.imagePath,
    this.filter = 'original',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'filter': filter,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanPage.fromJson(Map<String, dynamic> json) {
    return ScanPage(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      filter: json['filter'] as String? ?? 'original',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
