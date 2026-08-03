import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';

class DateTimeCard extends StatefulWidget {
  const DateTimeCard({super.key});

  @override
  State<DateTimeCard> createState() => _DateTimeCardState();
}

class _DateTimeCardState extends State<DateTimeCard> {
  // ── 📝 Class methods ───────────────────────────
  DateTime datetime = DateTime.now();
  Timer? timer;

  // ── Flutter override ───────────────────────────
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        datetime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── 🛠️ Local Functions ───────────────────────────
    final formattedDate = DateFormat('MMMM dd, yyyy').format(datetime);
    final formattedTimer = DateFormat('hh:mm a').format(datetime);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xm),
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: Colorpalatte.secondary,
        borderRadius: BorderRadius.circular(AppRadius.xm),
      ),

      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Image.asset('lib/assets/png/calendar.png', width: 20, height: 20),
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
                  formattedTimer,
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
    );
  }
}
