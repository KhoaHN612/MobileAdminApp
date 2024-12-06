class Class {
  final String id;
  final String courseId;
  final String comments;
  final String date;
  final String teacher;

  Class({
    required this.id,
    required this.courseId,
    required this.comments,
    required this.date,
    required this.teacher,
  });

  factory Class.fromMap(Map<String, dynamic> data) {
    return Class(
      id: data['id'].toString(),
      courseId: data['course_id'].toString(),
      comments: data['comments'].toString(),
      date: data['date'].toString(),
      teacher: data['teacher'].toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'comments': comments,
      'date': date,
      'teacher': teacher,
    };
  }
}