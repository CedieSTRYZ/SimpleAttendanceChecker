import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/constants/shadow_card.dart';
import 'package:simpleattendancechecker/widget/attendace_card.dart';

class StudentAnalyticsSheet {
  static Future<void> show(
    BuildContext context, {
    required String studentId,
    required String fullName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colorpalatte.maincolor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // FIREBASE CONNECTION {#3ed,5}
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('studentId', isEqualTo: studentId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                // PRESENTATION OF REGULAR STUDENTS STATUS {#9b3,10}
                final present = docs
                    .where((d) => d.data()['attendanceStatus'] == 'Present')
                    .length;
                final late = docs
                    .where((d) => d.data()['attendanceStatus'] == 'Late')
                    .length;
                final absent = docs
                    .where((d) => d.data()['attendanceStatus'] == 'Absent')
                    .length;
                final total = present + late + absent;

                // PRESENTING OF LATE AS PRESENT FOR REGULAR STUDENTS {#ffa,13}
                final attendedCount = present + late;
                final overallPercent = total == 0
                    ? 0.0
                    : (attendedCount / total) * 100;
                final presentPercent = overallPercent;
                final latePercent = total == 0 ? 0.0 : (late / total) * 100;
                final absentPercent = total == 0 ? 0.0 : (absent / total) * 100;

                final overallLabel = overallPercent >= 75
                    ? "Keep going! You're doing GREAT."
                    : overallPercent >= 50
                    ? "Doing okay — try to attend more classes."
                    : "Attendance needs improvement.";

                // PRESENTATION OF OJT/WORKING STUDENT STATUS {#7e2,17}
                final ojtWsDocs = docs.where((d) {
                  final status = d.data()['attendanceStatus'];
                  return status == 'OJT' || status == 'Working Student';
                }).toList();
                final ojtWsTotal = ojtWsDocs.length;
                final inSchoolCount = ojtWsDocs
                    .where((d) => d.data()['selfScanned'] == true)
                    .length;
                final ojtCount = ojtWsTotal - inSchoolCount;
                // final inSchoolPercent = ojtWsTotal == 0
                //     ? 0.0
                //     : (inSchoolCount / ojtWsTotal) * 100;
                // final ojtPercent = ojtWsTotal == 0
                //     ? 0.0
                //     : (ojtCount / ojtWsTotal) * 100;
                final isOjtStatus = ojtWsDocs.any(
                  (d) => d.data()['attendanceStatus'] == 'OJT',
                );

                // ── WIDGETS FOR STUDENT ANALYTICS SHEET ─────────────
                final items = <Widget>[
                  // ── 🔙 Back button ───────────────────────────────
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                    ),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colorpalatte.secondary,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),

                  // ── 🧑‍🎓 Student name and description ───────────────
                  Text(
                    fullName,
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: AppFontSize.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // ── 📊 Description of analytics ─────────────────────
                  Text(
                    'Track attendance performance through present, late, and absent records.',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: Colorpalatte.mutedcolor,
                    ),
                  ),

                  // ── 🔄 Loading, empty state, or analytics ─────────────
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (docs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Text(
                          'No attendance records yet for this student.',
                          style: TextStyle(color: Colorpalatte.mutedcolor),
                        ),
                      ),
                    )
                  else ...[
                    // ── 📊 Present/Late/Absent analytics ─────────────
                    if (total > 0) ...[
                      // ── 📊 Overall attendance percentage ─────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colorpalatte.secondary,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${overallPercent.round()}%',
                                    style: TextStyle(
                                      fontFamily: 'K2D',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colorpalatte.maincolor,
                                    ),
                                  ),

                                  Text(
                                    'Overall Attendance',
                                    style: TextStyle(
                                      fontFamily: 'K2D',
                                      fontWeight: FontWeight.w700,
                                      color: Colorpalatte.maincolor,
                                    ),
                                  ),

                                  Text(
                                    overallLabel,
                                    style: TextStyle(
                                      fontSize: AppFontSize.caption,
                                      color: Colorpalatte.maincolor.withValues(
                                        alpha: .8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── 📊 Circular stat ring (stacked: Present / Late / Absent) ─────
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // ── Outer ring: Present ─────────────────────────
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: CircularProgressIndicator(
                                      value: presentPercent / 100,
                                      strokeWidth: 7,
                                      color: Colorpalatte.sucesscolor,
                                      backgroundColor: Colorpalatte.sucesscolor
                                          .withValues(alpha: .15),
                                    ),
                                  ),

                                  // ── Middle ring: Late ────────────────────────────
                                  SizedBox(
                                    width: 54,
                                    height: 54,
                                    child: CircularProgressIndicator(
                                      value: latePercent / 100,
                                      strokeWidth: 6,
                                      color: Colorpalatte.warningcolor,
                                      backgroundColor: Colorpalatte.warningcolor
                                          .withValues(alpha: .15),
                                    ),
                                  ),

                                  // ── Inner ring: Absent ───────────────────────────
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      value: absentPercent / 100,
                                      strokeWidth: 5,
                                      color: Colorpalatte.errorcolor,
                                      backgroundColor: Colorpalatte.errorcolor
                                          .withValues(alpha: .15),
                                    ),
                                  ),

                                  // ── Center text: overall percent ─────────────────
                                  Text(
                                    '${overallPercent.round()}%',
                                    style: TextStyle(
                                      fontFamily: 'K2D',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colorpalatte.maincolor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // REGULAR STUDENT OVERVIEW {#dea,25}
                      _countStatRow(
                        label: 'Present',
                        description:
                            'Includes late arrivals as attended classes.',
                        count: attendedCount,
                        color: Colorpalatte.sucesscolor,
                        icon: Icons.check_circle_rounded,
                      ),

                      _countStatRow(
                        label: 'Late',
                        description: 'Arrived past the scheduled time.',
                        count: late,
                        color: Colorpalatte.warningcolor,
                        icon: Icons.schedule_rounded,
                      ),

                      _countStatRow(
                        label: 'Absent',
                        description: 'Did not attend the scheduled class.',
                        count: absent,
                        color: Colorpalatte.errorcolor,
                        icon: Icons.cancel_rounded,
                      ),
                    ],

                    // OJT STATS OVERVIEW {#5eb,30}
                    // ── 📊 In-School vs OJT/Work breakdown ───────────
                    if (ojtWsTotal > 0) ...[
                      Text(
                        'Attendance Breakdown',
                        style: TextStyle(
                          fontFamily: 'K2D',
                          fontSize: AppFontSize.title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      _countStatRow(
                        label: 'In-School',
                        description:
                            'Attended school and scanned in for the day.',
                        count: inSchoolCount,
                        color: Colorpalatte.sucesscolor,
                        icon: Icons.school_rounded,
                      ),

                      _countStatRow(
                        label: 'OJT / Work',
                        description: 'Attend in OJT/Woring but not in school.',
                        count: ojtCount,
                        color: isOjtStatus
                            ? Colorpalatte.ojtcolor
                            : Colorpalatte.infocolor,
                        icon: Icons.work_rounded,
                      ),
                    ],

                    // ATTENDACE OVERVIEW FOR ALL STUDENTS {#650,31}
                    // ── 📋 Attendance log — LAHAT ng status ──────────
                    Text(
                      'Attendance Log',
                      style: TextStyle(
                        fontFamily: 'K2D',
                        fontSize: AppFontSize.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    ...docs.map((doc) {
                      final d = doc.data();
                      final rawDate = (d['date'] ?? '').toString();
                      var displayDate = rawDate;
                      try {
                        displayDate = DateFormat(
                          'MMM dd, yyyy',
                        ).format(DateTime.parse(rawDate));
                      } catch (_) {}
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AttendaceCard(
                          fullName: d['fullName'] ?? '',
                          studentId: d['studentId'] ?? '',
                          time: d['time'] ?? '',
                          status: d['attendanceStatus'] ?? '',
                          date: displayDate,
                          selfScanned: d['selfScanned'] ?? false,
                        ),
                      );
                    }),
                  ],
                ];

                // LISTVIEW BUILDER {#92b,9}
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => items[index],
                );
              },
            );
          },
        );
      },
    );
  }

  // ADVANCE STATSCARD HELPER {#8db,76}
  static Widget _countStatRow({
    required String label,
    required String description,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        boxShadow: ShadowCard.card,
        color: Colorpalatte.containercolor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'K2D',
                    fontWeight: FontWeight.w700,
                    fontSize: AppFontSize.body,
                  ),
                ),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: Colorpalatte.mutedcolor,
                  ),
                ),
              ],
            ),
          ),

          Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'K2D',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
