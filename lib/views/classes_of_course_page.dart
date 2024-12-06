import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoga_customer/models/class.dart';
import '../models/cart.dart';
import '../models/course.dart';
import '../models/class_type.dart';

class ClassesOfCoursePage extends StatefulWidget {
  final String courseId;

  ClassesOfCoursePage({required this.courseId});

  @override
  _ClassesOfCoursePageState createState() => _ClassesOfCoursePageState();
}

class _ClassesOfCoursePageState extends State<ClassesOfCoursePage> {
  Course? course;
  List<Class> yogaClasses = [];
  Map<String, ClassType> classTypes = {};
  List<String> _orderedClasses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCourseAndClasses();
  }

  Future<void> fetchCourseAndClasses() async {
    try {
      // Fetch course
      DocumentSnapshot courseSnapshot = await FirebaseFirestore.instance
          .collection('yoga_courses')
          .doc(widget.courseId)
          .get();
      if (courseSnapshot.exists) {
        course = Course.fromMap(courseSnapshot.data() as Map<String, dynamic>);
      }

      // Fetch classes
      QuerySnapshot classSnapshot = await FirebaseFirestore.instance
          .collection('yoga_classes')
          .where('course_id', isEqualTo: widget.courseId)
          .get();
      yogaClasses = classSnapshot.docs
          .map((doc) => Class.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      yogaClasses.sort((a, b) {
        DateTime dateA = DateFormat('dd/MM/yyyy HH:mm')
            .parse('${a.date} ${course?.time ?? '00:00'}');
        DateTime dateB = DateFormat('dd/MM/yyyy HH:mm')
            .parse('${b.date} ${course?.time ?? '00:00'}');
        return dateA.compareTo(dateB);
      });

      // Fetch class types
      CollectionReference classTypeCollection =
          FirebaseFirestore.instance.collection('class_types');
      QuerySnapshot classTypeSnapshot = await classTypeCollection.get();
      for (var doc in classTypeSnapshot.docs) {
        ClassType classType =
            ClassType.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        classTypes[classType.id] = classType;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        CollectionReference orderCollection =
            FirebaseFirestore.instance.collection('orders');
        QuerySnapshot orderSnapshot =
            await orderCollection.where('user_id', isEqualTo: userId).get();
        List<String> orderedClasses = [];
        for (var doc in orderSnapshot.docs) {
          orderedClasses.add(doc['class_id']);
        }

        setState(() {
          _orderedClasses = orderedClasses;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching course and classes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes of Selected Course'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (course != null) _buildCourseInfoCard(course!),
                if (yogaClasses.isNotEmpty)
                  Expanded(
                    child: ListView(
                      children: _buildClassList(context, yogaClasses),
                    ),
                  )
                else
                  Center(child: Text('No classes available for this course')),
              ],
            ),
    );
  }

  Widget _buildCourseInfoCard(Course course) {
    final DateFormat timeFormat = DateFormat('HH:mm');
    final DateTime startTime = timeFormat.parse(course.time);
    final DateTime endTime = startTime.add(Duration(minutes: course.duration));
    final DateTime startDate = DateFormat('dd/MM/yyyy').parse(course.startDay);
    final int daysDifference = DateTime.now().difference(startDate).inDays;
    final String daysInfo = daysDifference == 0
        ? 'Today'
        : daysDifference > 0
            ? '${daysDifference} days ago'
            : 'in ${-daysDifference} days';
    final classTypeName = classTypes[course.classTypeId]?.name ?? 'Unknown';

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(10),
      child: ExpansionTile(
        title: Text(
          classTypeName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.imageUrl.isNotEmpty)
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(course.imageUrl, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: Icon(Icons.image, color: Colors.grey),
                          );
                        }),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Starts on: ${course.startDay} (${course.dayOfWeek})',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: daysDifference < 0 ? Colors.green : Colors.red,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            daysInfo,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Card(
                        color: Colors.blue,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Classes: ${course.capacity}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Price: \$${course.price}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  'Time: ${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  'Class Type: $classTypeName',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  'Capacity: ${course.capacity}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  'Description: ${course.description}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildClassList(BuildContext context, List<Class> yogaClasses) {
    return yogaClasses.map((yogaClass) {
      final isInCart = Provider.of<Cart>(context).contains(yogaClass.id);
      final course = this.course;
      final classType =
          course != null ? classTypes[course.classTypeId]?.name : 'Unknown';
      final time = course?.time ?? 'Unknown';
      final duration = course?.duration ?? 0;
      final DateFormat timeFormat = DateFormat('HH:mm');
      final DateTime startTime = timeFormat.parse(time);
      final DateTime endTime = startTime.add(Duration(minutes: duration));
      final isExpired = DateTime.now().isAfter(DateFormat('dd/MM/yyyy HH:mm')
          .parse('${yogaClass.date} ${course?.time ?? '00:00'}'));
      final isOrdered = _orderedClasses.contains(yogaClass.id);

      return Card(
        margin: EdgeInsets.all(10),
        child: ListTile(
          title: Text(yogaClass.teacher),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Class Type: $classType'),
              Text(
                  'Time: ${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}'),
              Text('Date: ${yogaClass.date}'),
            ],
          ),
          trailing: isExpired
              ? Icon(Icons.event_busy,
                  color: Colors.red) // Biểu tượng cho Quá hạn
              : isOrdered
                  ? Icon(Icons.check_circle,
                      color: Colors.green) // Biểu tượng cho Đã mua
                  : isInCart
                      ? IconButton(
                          icon: Icon(Icons.remove_shopping_cart,
                              color: Colors.red),
                          onPressed: () {
                            Provider.of<Cart>(context, listen: false)
                                .removeItem(yogaClass.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Class removed from cart')),
                            );
                          },
                        )
                      : IconButton(
                          icon: Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            Provider.of<Cart>(context, listen: false)
                                .addItem(yogaClass.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Class added to cart')),
                            );
                          },
                        ),
        ),
      );
    }).toList();
  }
}
