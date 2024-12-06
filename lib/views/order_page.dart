import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as Firestore;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class.dart';
import '../models/course.dart';
import '../models/class_type.dart';
import '../models/order.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Order> _orders = [];
  Map<String, Class> _classes = {};
  Map<String, Course> _courses = {};
  Map<String, ClassType> _classTypes = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchClasses();
    _fetchCourses();
    _fetchClassTypes();
  }

  Future<void> _fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId != null) {
      Firestore.CollectionReference orderCollection = Firestore.FirebaseFirestore.instance.collection('orders');
      Firestore.QuerySnapshot orderSnapshot = await orderCollection.where('user_id', isEqualTo: userId).get();
      List<Order> orders = orderSnapshot.docs.map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>)).toList();
      setState(() {
        _orders = orders;
      });
    }
  }

  Future<void> _fetchClasses() async {
    Firestore.CollectionReference classCollection = Firestore.FirebaseFirestore.instance.collection('yoga_classes');
    Firestore.QuerySnapshot classSnapshot = await classCollection.get();
    Map<String, Class> classes = {};
    for (var doc in classSnapshot.docs) {
      Class yogaClass = Class.fromMap(doc.data() as Map<String, dynamic>);
      classes[yogaClass.id] = yogaClass;
    }
    setState(() {
      _classes = classes;
    });
  }

  Future<void> _fetchCourses() async {
    Firestore.CollectionReference courseCollection = Firestore.FirebaseFirestore.instance.collection('yoga_courses');
    Firestore.QuerySnapshot courseSnapshot = await courseCollection.get();
    Map<String, Course> courses = {};
    for (var doc in courseSnapshot.docs) {
      Course course = Course.fromMap(doc.data() as Map<String, dynamic>);
      courses[course.id] = course;
    }
    setState(() {
      _courses = courses;
    });
  }

  Future<void> _fetchClassTypes() async {
    Firestore.CollectionReference classTypeCollection = Firestore.FirebaseFirestore.instance.collection('class_types');
    Firestore.QuerySnapshot classTypeSnapshot = await classTypeCollection.get();
    Map<String, ClassType> classTypes = {};
    for (var doc in classTypeSnapshot.docs) {
      ClassType classType = ClassType.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      classTypes[classType.id] = classType;
    }
    setState(() {
      _classTypes = classTypes;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Order>> ordersByDate = {};
    for (var order in _orders) {
      if (!ordersByDate.containsKey(order.orderDate)) {
        ordersByDate[order.orderDate] = [];
      }
      ordersByDate[order.orderDate]!.add(order);
    }

    List<String> sortedDates = ordersByDate.keys.toList()
      ..sort((a, b) => DateFormat('yyyy-MM-ddTHH:mm:ss').parse(a).compareTo(DateFormat('yyyy-MM-ddTHH:mm:ss').parse(b)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
      ),
      body: ListView(
        children: sortedDates.map((date) {
          List<Order> orders = ordersByDate[date]!;
          return Card(
            margin: EdgeInsets.all(10),
            child: ExpansionTile(
              title: Text('Order Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateFormat('yyyy-MM-ddTHH:mm:ss').parse(date))}'),
              children: orders.map((order) {
                Class? yogaClass = _classes[order.classId];
                Course? course = yogaClass != null ? _courses[yogaClass.courseId] : null;
                String classType = course != null ? _classTypes[course.classTypeId]?.name ?? 'Unknown' : 'Unknown';
                String time = course?.time ?? 'Unknown';
                int duration = course?.duration ?? 0;
                DateFormat timeFormat = DateFormat('HH:mm');
                DateTime startTime = time != 'Unknown' ? timeFormat.parse(time) : DateTime.now();
                DateTime endTime = startTime.add(Duration(minutes: duration));

                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(yogaClass?.teacher ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${yogaClass?.date ?? 'Unknown'}'),
                        Text('Class Type: $classType'),
                        Text('Time: ${time != 'Unknown' ? '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}' : 'Unknown'}'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}