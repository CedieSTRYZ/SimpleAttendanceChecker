import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/colorpalatte.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 300,
          height: 500,
          decoration: BoxDecoration(
            color: Colorpalatte.infoColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.19),
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.23),
                blurRadius: 6,
                spreadRadius: 0,
                offset: Offset(0, 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
