class Order {
  final String id;
  final String userId;
  final String classId;
  final String orderDate;

  Order({
    required this.id,
    required this.userId,
    required this.classId,
    required this.orderDate,
  });

  factory Order.fromMap(Map<String, dynamic> data) {
    return Order(
      id: data['id'],
      userId: data['user_id'],
      classId: data['class_id'],
      orderDate: data['order_date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'class_id': classId,
      'order_date': orderDate,
    };
  }
}