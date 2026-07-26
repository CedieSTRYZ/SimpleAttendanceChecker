import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/colorpalatte.dart';

class Startinglogo extends StatelessWidget {
  const Startinglogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colorpalatte.white,
      body: Center(
        child: Image(
          image: AssetImage('lib/assets/attendance_logo.png'),
          height: 200,
        ),
      ),
    );
  }
}
