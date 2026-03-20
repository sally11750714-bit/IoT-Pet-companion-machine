import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MotorControlPage extends StatelessWidget {
  final String baseUrl = 'http://192.168.4.1:5000/move';

  Future<void> moveMotor() async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"direction": "forward", "steps": 512}),
      );

      if (response.statusCode == 200) {
        print("Motor moved forward");
      } else {
        print("Failed to move motor");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: moveMotor,
        child: buildButton("Move Motor Forward"),
      ),
    );
  }

  Widget buildButton(String text) {
    return Container(
      width: 200,
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 10),
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
