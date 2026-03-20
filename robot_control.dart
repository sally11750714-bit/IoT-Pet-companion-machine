import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RobotControlPage extends StatefulWidget {
  @override
  _RobotControlPageState createState() => _RobotControlPageState();
}

class _RobotControlPageState extends State<RobotControlPage> {
  final String baseUrl = "http://192.168.4.1:5000/control";
  bool isAutoMode = false;

  Future<void> sendControl(String direction) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"direction": direction}),
      );
      if (response.statusCode == 200) {
        print("動作：$direction");
      } else {
        print("無法發送指令");
      }
    } catch (e) {
      print("錯誤：$e");
    }
  }

  void toggleAutoMode() {
    setState(() {
      isAutoMode = !isAutoMode;
    });
    sendControl(isAutoMode ? 'auto' : 'stop');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTapDown: (_) => sendControl('forward'),
              onTapUp: (_) => sendControl('stop'),
              child: buildButton('Forward'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTapDown: (_) => sendControl('left'),
                  onTapUp: (_) => sendControl('stop'),
                  child: buildButton('Left'),
                ),
                GestureDetector(
                  onTap: toggleAutoMode,
                  child: buildButton(isAutoMode ? 'Stop Auto' : 'Auto'),
                ),
                GestureDetector(
                  onTapDown: (_) => sendControl('right'),
                  onTapUp: (_) => sendControl('stop'),
                  child: buildButton('Right'),
                ),
              ],
            ),
            GestureDetector(
              onTapDown: (_) => sendControl('backward'),
              onTapUp: (_) => sendControl('stop'),
              child: buildButton('Backward'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String text) {
    return Container(
      width: 100,
      height: 50,
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
