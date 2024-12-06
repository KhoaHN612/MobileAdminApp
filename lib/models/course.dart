class Course {
  final int duration;
  final String? localImageUri;
  final String startDay;
  final double price;
  final String imageUrl;
  final String description;
  final String time;
  final String id;
  final String classTypeId;
  final int capacity;
  final String dayOfWeek;

  Course({
    required this.duration,
    this.localImageUri,
    required this.startDay,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.time,
    required this.id,
    required this.classTypeId,
    required this.capacity,
    required this.dayOfWeek,
  });

  factory Course.fromMap(Map<String, dynamic> data) {
    return Course(
      duration: data['duration'] as int,
      localImageUri: data['local_image_uri']?.toString(),
      startDay: data['start_day'].toString(),
      price: (data['price'] as num).toDouble(),
      imageUrl: data['image_url'].toString(),
      description: data['description'].toString(),
      time: data['time'].toString(),
      id: data['id'].toString(),
      classTypeId: data['class_type_id'].toString(),
      capacity: data['capacity'] as int,
      dayOfWeek: data['day_of_week'].toString(),
    );
  }
}