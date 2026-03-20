import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'robot_control.dart';
import 'laser_control.dart';
import 'motor_control.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'All Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AllControl(),
    );
  }
}

class AllControl extends StatefulWidget {
  @override
  _AllControlState createState() => _AllControlState();
}

class _AllControlState extends State<AllControl> {
  int _selectedIndex = 0;
  final String streamUrl = 'http://192.168.4.19:5001/video_feed';
  late Stream<Uint8List> imageStream;

  final List<Widget> _pages = [
    RobotControlPage(),
    LaserControlPage(),
    MotorControlPage(),
  ];

  final List<String> _titles = [
    'Robot Control',
    'Laser Control',
    'Motor Control',
  ];

  final List<IconData> _icons = [
    Icons.directions_car,
    Icons.flash_on,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    imageStream = fetchStream();
  }

  Stream<Uint8List> fetchStream() async* {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(streamUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to connect to stream: ${response.statusCode}');
      }

      List<int> buffer = [];
      final boundary = Uint8List.fromList(utf8.encode('--frame'));

      await for (final chunk in response.stream) {
        buffer.addAll(chunk);

        while (true) {
          final start = _findBoundary(buffer, boundary);
          if (start == -1) break;

          final end = _findBoundary(buffer, boundary, start + boundary.length);
          if (end != -1) {
            final frameData = buffer.sublist(start + boundary.length, end);
            buffer = buffer.sublist(end + boundary.length);

            final imageData = _extractImage(frameData);
            if (imageData != null) {
              yield imageData;
            }
          } else {
            break;
          }
        }
      }
    } catch (e) {
      print('Error fetching stream: $e');
      await Future.delayed(Duration(seconds: 5));
      yield* fetchStream();
    }
  }

  Uint8List? _extractImage(List<int> frameData) {
    final contentTypeMarker = utf8.encode('Content-Type: image/jpeg\r\n\r\n');
    final index = _indexOfSlice(frameData, contentTypeMarker);

    if (index != -1) {
      return Uint8List.fromList(frameData.sublist(index + contentTypeMarker.length));
    }
    return null;
  }

  int _findBoundary(List<int> data, Uint8List boundary, [int start = 0]) {
    for (int i = start; i <= data.length - boundary.length; i++) {
      if (_compareLists(data.sublist(i, i + boundary.length), boundary)) {
        return i;
      }
    }
    return -1;
  }

  int _indexOfSlice(List<int> data, List<int> slice, [int start = 0]) {
    for (int i = start; i <= data.length - slice.length; i++) {
      if (_compareLists(data.sublist(i, i + slice.length), slice)) {
        return i;
      }
    }
    return -1;
  }

  bool _compareLists(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: _buildVideoStream(),
          ),
          Expanded(
            flex: 1,
            child: _pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: List.generate(
          _icons.length,
              (index) => BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _titles[index],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoStream() {
    return Center(
      child: StreamBuilder<Uint8List>(
        stream: imageStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.memory(
                snapshot.data!,
                gaplessPlayback: true,
                fit: BoxFit.contain,
              ),
            );
          } else {
            return Text('No data received');
          }
        },
      ),
    );
  }
}

ButtonStyle getStandardButtonStyle() {
  return ElevatedButton.styleFrom(
    textStyle: const TextStyle(fontSize: 16),
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
  );
}
