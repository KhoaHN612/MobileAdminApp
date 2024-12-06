import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class.dart';
import '../models/cart.dart';
import '../models/course.dart';
import '../models/class_type.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({Key? key}) : super(key: key);

  @override
  _ClassesPageState createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  DateTimeRange? _selectedDateRange;
  Map<String, Course> _courses = {};
  Map<String, ClassType> _classTypes = {};
  List<String> _orderedClasses = [];
  String _searchQuery = '';
  String? _selectedClassType = 'All';
  String? _selectedDayOfWeek = 'All';
  String? _userId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(Duration(days: 7)),
    );
    Provider.of<Cart>(context, listen: false).loadCartFromFirestore();
    _loadUserEmail();
    _fetchClassTypes();
    _fetchCourses();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
    _fetchOrders();
  }

  Future<void> _fetchCourses() async {
    CollectionReference courseCollection = FirebaseFirestore.instance.collection('yoga_courses');
    QuerySnapshot courseSnapshot = await courseCollection.get();
    Map<String, Course> fetchedCourses = {};
    for (var doc in courseSnapshot.docs) {
      Course course = Course.fromMap(doc.data() as Map<String, dynamic>);
      fetchedCourses[course.id] = course;
    }
    setState(() {
      _courses = fetchedCourses;
    });
  }

  Future<void> _fetchClassTypes() async {
    CollectionReference classTypeCollection = FirebaseFirestore.instance.collection('class_types');
    QuerySnapshot classTypeSnapshot = await classTypeCollection.get();
    Map<String, ClassType> fetchedClassTypes = {};
    for (var doc in classTypeSnapshot.docs) {
      ClassType classType = ClassType.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      fetchedClassTypes[classType.id] = classType;
    }
    setState(() {
      _classTypes = fetchedClassTypes;
    });
  }

  Future<void> _fetchOrders() async {
    if (_userId == null) return;
    try {
      CollectionReference orderCollection = FirebaseFirestore.instance.collection('orders');
      QuerySnapshot orderSnapshot = await orderCollection.where('user_id', isEqualTo: _userId).get();
      List<String> orderedClasses = [];
      for (var doc in orderSnapshot.docs) {
        orderedClasses.add(doc['class_id']);
      }
      setState(() {
        _orderedClasses = orderedClasses;
      });
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  Future<void> _refreshData() async {
    _fetchOrders();
    _fetchClassTypes();
  }

  void _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          DropdownButton<String>(
            hint: Text('Filter by Class Type'),
            value: _selectedClassType,
            items: ['All', ..._classTypes.values.map((ClassType type) => type.id)].map((value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value == 'All' ? 'All' : _classTypes[value]?.name ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedClassType = value;
              });
            },
          ),
          SizedBox(width: 10),
          DropdownButton<String>(
            hint: Text('Filter by Day of Week'),
            value: _selectedDayOfWeek,
            items: ['All', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                .map((day) {
              return DropdownMenuItem<String>(
                value: day,
                child: Text(day),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDayOfWeek = value;
              });
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildClassList(List<Class> yogaClasses) {
    List<Class> filteredClasses = yogaClasses.where((yogaClass) {
      DateTime classDate;
      try {
        classDate = DateFormat('dd/MM/yyyy').parse(yogaClass.date);
      } catch (e) {
        return false;
      }
      bool withinDateRange = classDate.isAfter(_selectedDateRange!.start.subtract(Duration(days: 1))) &&
          classDate.isBefore(_selectedDateRange!.end.add(Duration(days: 1)));

      bool matchesSearchQuery = _searchQuery.isEmpty ||
          yogaClass.teacher.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (_courses[yogaClass.courseId]?.time.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      bool matchesClassTypeFilter = _selectedClassType == 'All' ||
          (_courses[yogaClass.courseId]?.classTypeId == _selectedClassType);

      bool matchesDayOfWeekFilter = _selectedDayOfWeek == 'All' ||
          (DateFormat('EEEE').format(classDate) == _selectedDayOfWeek);

      return withinDateRange && matchesSearchQuery && matchesClassTypeFilter && matchesDayOfWeekFilter;
    }).toList();

    Map<String, List<Class>> classesByDate = {};
    for (var yogaClass in filteredClasses) {
      if (!classesByDate.containsKey(yogaClass.date)) {
        classesByDate[yogaClass.date] = [];
      }
      classesByDate[yogaClass.date]!.add(yogaClass);
    }

    List<String> sortedDates = classesByDate.keys.toList()
      ..sort((a, b) => DateFormat('dd/MM/yyyy').parse(a).compareTo(DateFormat('dd/MM/yyyy').parse(b)));

    return sortedDates.map((date) {
      List<Class> classes = classesByDate[date]!;
      DateTime classDate = DateFormat('dd/MM/yyyy').parse(date);
      String dayOfWeek = DateFormat('EEEE').format(classDate);

      classes.sort((a, b) {
        final courseA = _courses[a.courseId];
        final courseB = _courses[b.courseId];
        if (courseA == null || courseB == null) return 0;
        final startTimeA = DateFormat('HH:mm').parse(courseA.time);
        final startTimeB = DateFormat('HH:mm').parse(courseB.time);
        return startTimeA.compareTo(startTimeB);
      });

      return Card(
        margin: EdgeInsets.all(10),
        child: ExpansionTile(
          title: Text('$date ($dayOfWeek)'),
          initiallyExpanded: true,
          children: classes.map((yogaClass) {
            final isInCart = Provider.of<Cart>(context).contains(yogaClass.id);
            final course = _courses[yogaClass.courseId];
            print(course.toString());
            final classType = course != null ? _classTypes[course.classTypeId]?.name : 'Unknown';
            final time = course?.time ?? 'Unknown';
            final duration = course?.duration ?? 0;
            final DateFormat timeFormat = DateFormat('HH:mm');
            DateTime startTime, endTime;
            if (time != 'Unknown') {
              startTime = timeFormat.parse(time);
              endTime = startTime.add(Duration(minutes: duration));
            } else {
              startTime = DateTime.now();
              endTime = startTime;
            }
            final isExpired = DateTime.now().isAfter(DateFormat('dd/MM/yyyy HH:mm').parse('${yogaClass.date} ${course?.time ?? '00:00'}'));
            final isOrdered = _orderedClasses.contains(yogaClass.id);

            return Card(
              child: ListTile(
                title: Text(yogaClass.teacher),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price: £${course?.price.toStringAsFixed(2) ?? '0.00'}'),
                    Text('Date: ${yogaClass.date}'),
                    Text('Class Type: $classType'),
                    Text('Time: ${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}'),
                  ],
                ),
                trailing: isExpired
                    ? Icon(Icons.event_busy, color: Colors.red)
                    : isOrdered
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : isInCart
                            ? IconButton(
                                icon: Icon(Icons.remove_shopping_cart, color: Colors.red),
                                onPressed: () {
                                  Provider.of<Cart>(context, listen: false).removeItem(yogaClass.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Class removed from cart')),
                                  );
                                },
                              )
                            : IconButton(
                                icon: Icon(Icons.add_shopping_cart),
                                onPressed: () {
                                  Provider.of<Cart>(context, listen: false).addItem(yogaClass.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Class added to cart')),
                                  );
                                },
                              ),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Yoga Classes'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/cart');
              if (result == true) {
                await _refreshData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by instructor or time...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range),
                  onPressed: _pickDateRange,
                ),
              ],
            ),
          ),
          _buildFilterOptions(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('yoga_classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No classes available'));
                }

                List<Class> yogaClasses = snapshot.data!.docs
                    .map((doc) => Class.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView(
                  children: _buildClassList(yogaClasses),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
