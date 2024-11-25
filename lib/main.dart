import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grok AI Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TabBarHome(),
    );
  }
}

class TabBarHome extends StatefulWidget {
  @override
  _TabBarHomeState createState() => _TabBarHomeState();
}

class _TabBarHomeState extends State<TabBarHome> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    HomeTab(),
    GrokAIFetchTab(),
    TimetableTab(studentId: "1234567"), // Example Student ID
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student App"),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.api),
            label: 'Grok AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Timetable',
          ),
        ],
      ),
    );
  }
}


class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? studentData;
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> timetable = [];

  Future<void> fetchData() async {
    String studentId = "123456"; // Replace with dynamic student ID

    // Fetch student details
    await fetchStudentDetails(studentId);

    // Fetch courses for the student
    List<Map<String, dynamic>> fetchedCourses = await fetchCourses(studentId);

    // Get course IDs
    List<String> courseIds = fetchedCourses.map((course) => course['courseId'] as String).toList();

    // Fetch timetable for courses
    List<Map<String, dynamic>> fetchedTimetable = await fetchTimetable(courseIds);

    setState(() {
      courses = fetchedCourses;
      timetable = fetchedTimetable;
    });
  }

  Future<void> fetchStudentDetails(String studentId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('studentID', isEqualTo: studentId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming studentId is unique, take the first result
        DocumentSnapshot studentDoc = querySnapshot.docs.first;

        setState(() {
          studentData = studentDoc.data() as Map<String, dynamic>?;
        });
        print("Student data fetched: $studentData");
      } else {
        print("No student found with ID: $studentId");
      }
    } catch (e) {
      print("Error fetching student details: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchCourses(String studentId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('studentID', isEqualTo: studentId)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching courses: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchTimetable(List<String> courseIds) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('timetable')
          .where('courseId', whereIn: courseIds)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching timetable: $e");
      return [];
    }
  }
  @override
  void initState() {
    super.initState();
    fetchData();
  }

 @override
  Widget build(BuildContext context) {
    return Center(
      child: studentData == null
          ? CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Email: ${studentData!['email']}"),
                Text("ID: ${studentData!['id']}"),
                Text("Attendance: ${studentData!['attendance']}%"),
                SizedBox(height: 20),
                Text("Courses:"),
                ...courses.map((course) => Text(course['courseName'])).toList(),
                SizedBox(height: 20),
                Text("Timetable:"),
                ...timetable.map((entry) => Text("${entry['day']} at ${entry['time']}")).toList(),
              ],
            ),
    );
  }
}
class TimetableTab extends StatelessWidget {
  final String studentId;

  TimetableTab({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('studentID', isEqualTo: studentId)
          .snapshots(),
      builder: (context, courseSnapshot) {
        if (courseSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
          return Center(child: Text("No courses found for this student."));
        }

        // Extract course IDs from the 'courses' collection
        List<String> courseIds = courseSnapshot.data!.docs
            .map((doc) => doc.data()['courseId'] as String)
            .toList();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('timetable')
              .where('courseId', whereIn: courseIds)
              .snapshots(),
          builder: (context, timetableSnapshot) {
            if (timetableSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!timetableSnapshot.hasData || timetableSnapshot.data!.docs.isEmpty) {
              return Center(child: Text("No timetable found for the selected courses."));
            }

            // Display the timetable data
            return ListView(
              children: timetableSnapshot.data!.docs.map((doc) {
                final data = doc.data();
                return ListTile(
                  title: Text("Course ID: ${data['courseId']}"),
                  subtitle: Text("${data['day']} at ${data['time']}"),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}


class GrokAIFetchTab extends StatefulWidget {
  @override
  _GrokAIFetchTabState createState() => _GrokAIFetchTabState();
}

class _GrokAIFetchTabState extends State<GrokAIFetchTab> {
  String _response = "Press the button to fetch a response.";

  Future<void> fetchGrokAIResponse() async {
    const String apiUrl = 'https://api.x.ai/v1/chat/completions'; // Replace with actual endpoint
    const String apiKey = ''; // Replace with your API Key

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "grok-beta", // Model specified in your example
          "messages": [
            {"role": "user", "content": "Explain Grok AI"}
          ],
          "max_tokens": 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract content from the response
        String assistantMessage = data['choices'][0]['message']['content'] ?? "No content";
        
        setState(() {
          _response = assistantMessage;
        });
      } else {
        setState(() {
          _response = "Error: ${response.statusCode} ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        _response = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _response,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: fetchGrokAIResponse,
            child: Text("Fetch Response"),
          ),
        ],
      ),
    );
  }
}
