class Appointment {
  final String id;
  final String title;
  final String description;
  final String counselorName;
  final String counselorImage;
  final DateTime date;
  final String time;
  final String room;
  final String status;

  Appointment({
    required this.id,
    required this.title,
    required this.description,
    required this.counselorName,
    required this.counselorImage,
    required this.date,
    required this.time,
    required this.room,
    this.status = 'upcoming',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'counselorName': counselorName,
        'counselorImage': counselorImage,
        'date': date.toIso8601String(),
        'time': time,
        'room': room,
        'status': status,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        counselorName: (json['counselorName'] as String?) ?? '',
        counselorImage: (json['counselorImage'] as String?) ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        time: (json['time'] as String?) ?? '',
        room: (json['room'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'upcoming',
      );
}
