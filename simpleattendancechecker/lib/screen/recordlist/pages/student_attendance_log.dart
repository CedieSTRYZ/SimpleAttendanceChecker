import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/widget/attendace_card.dart';

class StudentAttendanceLog extends StatelessWidget {
  final String studentId;
  final String fullName;
  final VoidCallback onBack;

  const StudentAttendanceLog({
    super.key,
    required this.studentId,
    required this.fullName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: Colorpalatte.secondary,
            ),
            Expanded(
              child: Text(
                fullName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'K2D',
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Text(
            'Attendance Log',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: Colorpalatte.mutedcolor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('attendance')
                .where('studentId', isEqualTo: studentId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'An error occurred while fetching data:\n${snapshot.error}',
                    style: TextStyle(color: Colorpalatte.errorcolor),
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (snapshot.connectionState == ConnectionState.waiting &&
                  docs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No attendance records yet for this student.',
                    style: TextStyle(color: Colorpalatte.mutedcolor),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final d = docs[index].data();
                  final rawDate = (d['date'] ?? '').toString();
                  var displayDate = rawDate;
                  try {
                    displayDate =
                        DateFormat('MMM dd, yyyy').format(DateTime.parse(rawDate));
                  } catch (_) {
                    // panatilihin ang raw string kung hindi ma-parse
                  }
                  return AttendaceCard(
                    fullName: d['fullName'] ?? '',
                    studentId: d['studentId'] ?? '',
                    time: d['time'] ?? '',
                    status: d['attendanceStatus'] ?? '',
                    date: displayDate,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}