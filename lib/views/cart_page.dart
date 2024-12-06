import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/class.dart';
import '../models/course.dart';
import 'order_page.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<String> selectedItems = [];
  double totalPrice = 0.0;

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<Course?> _fetchCourse(String courseId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('yoga_courses')
        .doc(courseId)
        .get();
    if (snapshot.exists) {
      return Course.fromMap(snapshot.data() as Map<String, dynamic>);
    }
    return null;
  }

  void _toggleSelection(String classId, double classPrice) {
    setState(() {
      if (selectedItems.contains(classId)) {
        selectedItems.remove(classId);
        totalPrice -= classPrice;
      } else {
        selectedItems.add(classId);
        totalPrice += classPrice;
      }
    });
  }

  Future<void> _checkout() async {
    final timeCheckout = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    final orderCollection = FirebaseFirestore.instance.collection('orders');
    List<String> checkedOutItems = List.from(selectedItems);

    for (String classId in selectedItems) {
      final id = Uuid().v4();
      await orderCollection.doc(id).set({
        'id': id,
        'user_id': userId,
        'class_id': classId,
        'order_date': timeCheckout,
      });
      await _removeItemFromCart(classId);
    }

    setState(() {
      selectedItems.clear();
      totalPrice = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checked out successfully')),
    );
  }

  Future<void> _removeItemFromCart(String classId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
        .collection('carts')
        .where('user_id', isEqualTo: userId)
        .get();

    if (cartSnapshot.docs.isNotEmpty) {
      final cartId = cartSnapshot.docs.first['id'];
      List<String> items = List<String>.from(cartSnapshot.docs.first['items']);
      items.remove(classId);
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(cartSnapshot.docs.first.id)
          .set({'id': cartId, 'user_id': userId, 'items': items});
    }
  }

  Future<void> _removeSelectedItems() async {
    for (String classId in selectedItems) {
      await _removeItemFromCart(classId);
    }
    setState(() {
      selectedItems.clear();
      totalPrice = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected classes removed from cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        actions: [
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _removeSelectedItems,
            ),
          IconButton(
            icon: Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _getUserId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No user logged in'));
          }
          final userId = snapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('carts')
                .where('user_id', isEqualTo: userId)
                .snapshots(),
            builder: (context, cartSnapshot) {
              if (cartSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!cartSnapshot.hasData || cartSnapshot.data!.docs.isEmpty) {
                return Center(child: Text('No classes in cart'));
              }

              List<String> classIds = List<String>.from(cartSnapshot.data!.docs.first['items']);
              return FutureBuilder<List<Class>>(
                future: _loadYogaClasses(classIds),
                builder: (context, classSnapshot) {
                  if (classSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!classSnapshot.hasData || classSnapshot.data!.isEmpty) {
                    return Center(child: Text('No classes found'));
                  }
                  final yogaClasses = classSnapshot.data!;
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: yogaClasses.length,
                          itemBuilder: (context, index) {
                            final yogaClass = yogaClasses[index];
                            return FutureBuilder<Course?>(
                              future: _fetchCourse(yogaClass.courseId),
                              builder: (context, courseSnapshot) {
                                final course = courseSnapshot.data;
                                final price = course?.price ?? 0.0;
                                final time = course?.time ?? 'Unknown';
                                final duration = course?.duration ?? 0;
                                final DateFormat timeFormat = DateFormat('HH:mm');
                                DateTime startTime;
                                DateTime endTime;
                                bool isExpired = false;
                                if (time != 'Unknown') {
                                  startTime = timeFormat.parse(time);
                                  endTime = startTime.add(Duration(minutes: duration));
                                  isExpired = DateTime.now().isAfter(
                                    DateFormat('dd/MM/yyyy HH:mm').parse('${yogaClass.date} $time'),
                                  );
                                } else {
                                  startTime = DateTime.now();
                                  endTime = DateTime.now();
                                }
                                return Card(
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: selectedItems.contains(yogaClass.id),
                                      onChanged: (bool? value) {
                                        _toggleSelection(yogaClass.id, price);
                                      },
                                    ),
                                    title: Text(yogaClass.teacher),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Date: ${yogaClass.date}'),
                                        Text('Price: £${price.toStringAsFixed(2)}'),
                                        Text('Time: ${time != 'Unknown' ? '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}' : 'Unknown'}'),
                                      ],
                                    ),
                                    trailing: isExpired
                                        ? Icon(Icons.event_busy, color: Colors.red)
                                        : IconButton(
                                            icon: Icon(Icons.remove_shopping_cart, color: Colors.red),
                                            onPressed: () {
                                              _removeItemFromCart(yogaClass.id);
                                              setState(() {
                                                yogaClasses.removeAt(index);
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Class removed from cart')),
                                              );
                                            },
                                          ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Total: £${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: selectedItems.isEmpty ? null : _checkout,
                        child: Text('Checkout'),
                      ),
                      SizedBox(height: 40),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Class>> _loadYogaClasses(List<String> classIds) async {
    List<Class> loadedClasses = [];
    for (String classId in classIds) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('yoga_classes').doc(classId).get();
      if (snapshot.exists) {
        loadedClasses.add(Class.fromMap(snapshot.data() as Map<String, dynamic>));
      }
    }
    return loadedClasses;
  }
}
