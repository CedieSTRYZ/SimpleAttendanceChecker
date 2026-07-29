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
          padding: const EdgeInsets.all(14.0),
          child: Column(
            spacing: 20,
            children: [
              // ── Text for overview ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Overview',
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  //! No function for now {#3ea,9}
                  Text(
                    'This week',
                    style: TextStyle(
                      color: Colorpalatte.accent,
                      fontFamily: 'K2D',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              //TODO: Adjust this for displaying how many student are present, absent, and late  {#745,42}
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Container(
                      width: 180,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colorpalatte.containerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      width: 180,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colorpalatte.containerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      width: 180,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colorpalatte.containerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      width: 180,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colorpalatte.containerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Text for sections ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Section 4-1',
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'See all',
                    style: TextStyle(
                      color: Colorpalatte.accent,
                      fontFamily: 'K2D',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              //TODO: Make this functionable base on how many student have been scanned for QRcode {#54e,18}
              Column(
                spacing: 10,
                children: [
                  AttendaceCard(),
                  AttendaceCard(color: Colorpalatte.absentColor),
                  AttendaceCard(color: Colorpalatte.lateColor),
                  AttendaceCard(color: Colorpalatte.ojtworkingColor),
                  AttendaceCard(color: Colorpalatte.absentColor),
                  AttendaceCard(),
                  AttendaceCard(),
                  AttendaceCard(color: Colorpalatte.ojtworkingColor),
                  AttendaceCard(color: Colorpalatte.lateColor),
                  AttendaceCard(color: Colorpalatte.lateColor),
                  AttendaceCard(color: Colorpalatte.lateColor),
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
