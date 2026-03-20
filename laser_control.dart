import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LaserControlPage extends StatelessWidget {
  final String baseUrl = 'http://192.168.4.1:5000/laser';

  Future<void> turnLaserOn() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/on'));
      if (response.statusCode == 200) {
        print("Laser turned ON");
      } else {
        print("Failed to turn laser ON");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> turnLaserOff() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/off'));
      if (response.statusCode == 200) {
        print("Laser turned OFF");
      } else {
        print("Failed to turn laser OFF");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: turnLaserOn,
            child: buildButton("Turn Laser ON"),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: turnLaserOff,
            child: buildButton("Turn Laser OFF"),
          ),
        ],
      ),
    );
  }

  Widget buildButton(String text) {
    return Container(
      width: 150,
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
