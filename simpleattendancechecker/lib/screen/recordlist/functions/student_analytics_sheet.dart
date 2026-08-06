import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/widget/attendace_card.dart';
import 'package:simpleattendancechecker/widget/circular_stat_ring.dart';

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
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('studentId', isEqualTo: studentId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                // ── 📊 Present/Late/Absent — para sa regular Students ──────
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

                // Counted parin yung late as present which is akala
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

                // ── 📊 In-School vs OJT/Work breakdown — para sa OJT/WS ────
                // "selfScanned: true"  = mismong nag-scan sa school (In-School)
                // "selfScanned: false" = na-log via Mark as Absent (OJT/Work,
                // hindi ito "kabiguan" — normal lang na araw ng OJT/duty)
                final ojtWsDocs = docs.where((d) {
                  final status = d.data()['attendanceStatus'];
                  return status == 'OJT' || status == 'Working Student';
                }).toList();
                final ojtWsTotal = ojtWsDocs.length;
                final inSchoolCount = ojtWsDocs
                    .where((d) => d.data()['selfScanned'] == true)
                    .length;
                final ojtCount = ojtWsTotal - inSchoolCount;
                final inSchoolPercent = ojtWsTotal == 0
                    ? 0.0
                    : (inSchoolCount / ojtWsTotal) * 100;
                final ojtPercent = ojtWsTotal == 0
                    ? 0.0
                    : (ojtCount / ojtWsTotal) * 100;

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      fullName,
                      style: TextStyle(
                        fontFamily: 'K2D',
                        fontSize: AppFontSize.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Track attendance performance through present, late, and absent records.',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: Colorpalatte.mutedcolor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

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
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      overallLabel,
                                      style: TextStyle(
                                        fontSize: AppFontSize.caption,
                                        color: Colorpalatte.maincolor
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CircularStatRing(
                                percent: overallPercent,
                                color: Colorpalatte.accentcolor,
                                size: 72,
                                strokeWidth: 7,
                                textStyle: TextStyle(
                                  fontFamily: 'K2D',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colorpalatte.maincolor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _statRow(
                          'Present',
                          'Attended $attendedCount time(s) of all recorded classes (includes late arrivals).',
                          presentPercent,
                          Colorpalatte.sucesscolor,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _statRow(
                          'Late',
                          'Arrived late $late time(s) of recorded attendance.',
                          latePercent,
                          Colorpalatte.warningcolor,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _statRow(
                          'Absent',
                          'Missed $absent time(s) of scheduled classes.',
                          absentPercent,
                          Colorpalatte.errorcolor,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

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
                        const SizedBox(height: AppSpacing.sm),
                        _statRow(
                          'In-School',
                          'Scanned in at school $inSchoolCount time(s) of $ojtWsTotal logged day(s).',
                          inSchoolPercent,
                          Colorpalatte.accentcolor,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _statRow(
                          'OJT / Work',
                          'Logged as OJT/Working (no school scan) $ojtCount time(s) of $ojtWsTotal logged day(s).',
                          ojtPercent,
                          Colorpalatte.ojtcolor,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // ── 📋 Attendance log — LAHAT ng status ──────────
                      Text(
                        'Attendance Log',
                        style: TextStyle(
                          fontFamily: 'K2D',
                          fontSize: AppFontSize.title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...docs.map((doc) {
                        final d = doc.data();
                        final rawDate = (d['date'] ?? '').toString();
                        var displayDate = rawDate;
                        try {
                          displayDate = DateFormat(
                            'MMM dd, yyyy',
                          ).format(DateTime.parse(rawDate));
                        } catch (_) {
                          // panatilihin ang raw string kung hindi ma-parse
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: AttendaceCard(
                            fullName: d['fullName'] ?? '',
                            studentId: d['studentId'] ?? '',
                            time: d['time'] ?? '',
                            status: d['attendanceStatus'] ?? '',
                            date: displayDate,
                          ),
                        );
                      }),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  static Widget _statRow(
    String label,
    String description,
    double percent,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colorpalatte.containercolor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
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
          CircularStatRing(
            percent: percent,
            color: color,
            size: 48,
            strokeWidth: 5,
          ),
        ],
      ),
    );
  }
}
