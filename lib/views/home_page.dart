import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/class_type.dart';
import '../models/course.dart';
import '../models/class.dart';
import 'classes_of_course_page.dart';
import 'profile_page.dart';
import 'classes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Map<String, String> classTypes = {};
  String selectedDay = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchClassTypes();
  }

  Future<void> _fetchClassTypes() async {
    CollectionReference classTypeCollection =
        FirebaseFirestore.instance.collection('class_types');
    QuerySnapshot classTypeSnapshot = await classTypeCollection.get();
    Map<String, String> fetchedClassTypes = {};
    for (var doc in classTypeSnapshot.docs) {
      ClassType classType =
          ClassType.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      fetchedClassTypes[classType.id] = classType.name;
    }
    setState(() {
      classTypes = fetchedClassTypes;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      buildCoursesPage(),
      ClassesPage(),
      ProfilePage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget buildCoursesPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Courses'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var day in [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday'
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(day),
                        selected: selectedDay == day,
                        onSelected: (selected) {
                          setState(() {
                            selectedDay = selected ? day : '';
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by time (e.g., 10:00)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('yoga_courses')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No courses available'));
                }

                List<Course> allCourses = snapshot.data!.docs
                    .map((doc) =>
                        Course.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();
                List<Course> filteredCourses = allCourses.where((course) {
                  final matchesDay =
                      selectedDay.isEmpty || course.dayOfWeek == selectedDay;
                  final matchesTime = searchQuery.isEmpty ||
                      course.time.contains(searchQuery) ||
                      course.capacity.toString().contains(searchQuery);
                  return matchesDay && matchesTime;
                }).toList();

                return ListView.builder(
                  itemCount: filteredCourses.length,
                  itemBuilder: (context, index) {
                    final course = filteredCourses[index];
                    final classTypeName =
                        classTypes[course.classTypeId] ?? 'Unknown';
                    final DateFormat timeFormat = DateFormat('HH:mm');
                    final DateTime startTime = timeFormat.parse(course.time);
                    final DateTime endTime =
                        startTime.add(Duration(minutes: course.duration));
                    final DateTime startDate =
                        DateFormat('dd/MM/yyyy').parse(course.startDay);
                    final int daysDifference =
                        DateTime.now().difference(startDate).inDays;
                    final String daysInfo = daysDifference == 0
                        ? 'Today'
                        : daysDifference > 0
                            ? '${daysDifference} days ago'
                            : 'in ${-daysDifference} days';

                    return FutureBuilder<int>(
                        future: _getNumberOfClasses(course.id),
                        builder: (context, snapshot) {

                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          final numberOfClasses = snapshot.data ?? 0;
                          return Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(10),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClassesOfCoursePage(
                                        courseId: course.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (course.imageUrl.isNotEmpty &&
                                        course.imageUrl != 'null')
                                      Align(
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              course.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: Colors.grey[200],
                                                  child: Icon(Icons.image,
                                                      color: Colors.grey),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[200],
                                          child: Icon(Icons.image,
                                              color: Colors.grey),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Text(
                                      classTypeName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Starts on: ${course.startDay} (${course.dayOfWeek})',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Card(
                                            color: daysDifference < 0
                                                ? Colors.green
                                                : Colors.red,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
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
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                'Classes: $numberOfClasses',
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
                                      'Price: £${course.price}',
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
                            ),
                          );
                        }
                        // },
                        );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getNumberOfClasses(String courseId) async {
    try {
      CollectionReference classCollection =
          FirebaseFirestore.instance.collection('yoga_classes');
      QuerySnapshot classSnapshot =
          await classCollection.where('course_id', isEqualTo: courseId).get();
      return classSnapshot.docs.length;
    } catch (e) {
      print('Error fetching number of classes: $e');
      return 0;
    }
  }
}
