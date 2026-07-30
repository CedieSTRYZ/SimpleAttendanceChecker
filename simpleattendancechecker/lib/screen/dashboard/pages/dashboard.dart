import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // ── 🛠️ Local funtions ───────────────────────────
  DateTime date = DateTime.now();
  late String formattedDate = DateFormat('MMMM dd, yyyy').format(date);
  late String formattedTime = DateFormat('hh:mm a').format(date);

  // ── 🎴 UI builder ───────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        spacing: AppSpacing.sm,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontFamily: 'K2D',
              fontSize: AppFontSize.title,
              fontWeight: FontWeight.w700,
            ),
          ),
      
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xm),
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colorpalatte.secondary,
              borderRadius: BorderRadius.circular(AppRadius.xm),
            ),
            child: Row(
              spacing: AppSpacing.xm,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colorpalatte.maincolor,
                          fontFamily: 'K2D',
                          fontSize: AppFontSize.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
      
                      Text(
                        'Time: $formattedTime',
                        style: TextStyle(
                          color: Colorpalatte.maincolor,
                          fontFamily: 'K2D',
                          fontSize: AppFontSize.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      
          // Fix function place all the total of present, absent, late, and ojt {#92e,31}
          SizedBox(
            height: 100,
            child: ListView.builder(
              physics: ScrollPhysics(parent: null),
              shrinkWrap: true,
              padding: EdgeInsets.all(AppSpacing.sm),
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal:  AppSpacing.xs),
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colorpalatte.containercolor,
                      borderRadius: BorderRadius.circular(AppRadius.md)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: AppSpacing.sm,
                      children: [
                        Text('45'),
                        Text('Present'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Text(
            'Sections',
            style: TextStyle(
              fontFamily: 'K2D',
              fontSize: AppFontSize.title,
              fontWeight: FontWeight.w700,
            ),
          ),
      
          // List of all sections {#83d,7}
          // ListView.builder(
          //   scrollDirection: Axis.horizontal,
          //   itemCount: 1,
          //   itemBuilder: (context, index) {
          //     return;
          //   },
          // ),
      
          Container(),

          // List of all student that present today {#bec,7}
          // ListView.builder(
          //   scrollDirection: Axis.verical,
          //   itemCount: 1,
          //   itemBuilder: (context, index) {
          //     return;
          //   },
          // ),
        ],
      ),
    );
  }
}
