import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/colorpalatte.dart';
import 'package:simpleattendancechecker/widget/attendace_card.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('data'), Text('hahahaha')],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: MediaQuery.widthOf(context) * 0.3,
                    height: MediaQuery.heightOf(context) * 0.3,
                    color: Colorpalatte.accent,
                  ),
                  Container(
                    width: MediaQuery.widthOf(context) * 0.3,
                    height: MediaQuery.heightOf(context) * 0.3,
                    color: Colorpalatte.infoColor,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('data'), Text('hahahaha')],
              ),
              Column(
                spacing: 10,
                children: [
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
