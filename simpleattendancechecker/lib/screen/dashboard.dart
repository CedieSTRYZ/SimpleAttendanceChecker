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
          padding: EdgeInsets.all(20),
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

          child: Column(
            children: [
              Text(
                'This font is K2D regular',
                style: TextStyle(fontFamily: 'K2D', fontWeight: FontWeight.w400),
              ),
              Text(
                'This font is K2D bold',
                style: TextStyle(fontFamily: 'K2D', fontWeight: FontWeight.w700),
              ),
              Text(
                'This font is Poppins regular',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
              ),
              Text(
                'This font is Poppins medium',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
              ),
              Text(
                'This font is Poppins semiBold',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
