import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
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
    Center(child: Text("Home")),
    GrokAIFetchTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grok AI Demo"),
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
        ],
      ),
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
