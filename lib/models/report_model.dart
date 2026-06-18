enum ReportType { incident, counseling, general }

class Report {
  final String id;
  final String title;
  final String description;
  final ReportType type;
  final DateTime date;
  final bool isPrivate;
  final String? studentId;
  final String? studentName;
  final List<String>? imageUrls;

  Report({
    required this.id,
    required this.title,
    required this.description,
    this.type = ReportType.incident,
    DateTime? date,
    this.isPrivate = true,
    this.studentId,
    this.studentName,
    this.imageUrls,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'date': date.toIso8601String(),
        'isPrivate': isPrivate,
        'studentId': studentId,
        'studentName': studentName,
        'imageUrls': imageUrls,
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        type: ReportType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ReportType.incident,
        ),
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        isPrivate: json['isPrivate'] as bool? ?? true,
        studentId: json['studentId'] as String?,
        studentName: json['studentName'] as String?,
        imageUrls: (json['imageUrls'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );
}
