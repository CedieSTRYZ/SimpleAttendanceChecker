import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';

class AttendaceCard extends StatelessWidget {
  final String fullName;
  final String studentId;
  final String time;
  final String status;

  const AttendaceCard({
    super.key,
    required this.fullName,
    required this.studentId,
    required this.time,
    required this.status,
  });

  Color get _statusColor {
    switch (status) {
      case 'Present':
        return Colorpalatte.sucesscolor;
      case 'Late':
        return Colorpalatte.warningcolor;
      case 'Absent':
        return Colorpalatte.errorcolor;
      case 'OJT':
      case 'Working Student':
        return Colorpalatte.ojtcolor;
      default:
        return Colorpalatte.mutedcolor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colorpalatte.containercolor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        spacing: AppSpacing.xm,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: _statusColor),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentId,
                  style: TextStyle(
                    fontFamily: 'K2D',
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  fullName,
                  style: TextStyle(
                    fontFamily: 'K2D',
                    fontSize: AppFontSize.caption,
                    color: Colorpalatte.mutedcolor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: TextStyle(fontFamily: 'K2D', fontSize: AppFontSize.body)),
              Text(
                status,
                style: TextStyle(
                  fontFamily: 'K2D',
                  fontSize: AppFontSize.caption,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}