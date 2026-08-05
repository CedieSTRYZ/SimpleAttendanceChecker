import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/widget/attendace_card.dart';
import 'package:simpleattendancechecker/widget/date_time_card.dart';
import 'package:simpleattendancechecker/widget/searchbar_card.dart';
import 'package:simpleattendancechecker/widget/section_card.dart';
import 'package:simpleattendancechecker/widget/session_card.dart';

class SummaryReports extends StatefulWidget {
  const SummaryReports({super.key});

  @override
  State<SummaryReports> createState() => _SummaryReportsState();
}

class _SummaryReportsState extends State<SummaryReports> {
  // ── 🛠️ State variables ───────────────────────────
  bool showDetails = false;
  Map<String, dynamic>? selectedSession;
  String selectedSection = 'BSIT 4-1';

  // ── 🛠️ Methods / Functions ───────────────────────────

  // Detail record list
  final List<Map<String, dynamic>> attendanceRecords = [
    {
      'studentId': '06-2423-022994',
      'fullName': 'Lorenzana, Ahllana Mae G.',
      'time': '10:00 AM',
      'status': 'Preeeesent',
    },
    {
      'studentId': '06-2423-032994',
      'fullName': 'Lorenzana, Ahllana Mae G.',
      'time': '10:00 AM',
      'status': 'Late',
    },
    {
      'studentId': '06-2423-032994',
      'fullName': 'Lorenzana, Ahllana Mae G.',
      'time': '10:00 AM',
      'status': 'Absent',
    },
  ];

  // Sections list
  final List<Map<String, dynamic>> sections = [
    {'label': 'BSIT 4-1', 'selected': true},
    {'label': 'BSIT 4-2', 'selected': false},
    {'label': 'BSIT 4-3', 'selected': false},
    {'label': 'BSIT 4-4', 'selected': false},
    {'label': 'BSIT 4-5', 'selected': false},
    {'label': 'BSIT 4-6', 'selected': false},
    {'label': 'BSIT 3-1', 'selected': false},
    {'label': 'BSIT 3-2', 'selected': false},
  ];

  // Session list
  final List<Map<String, dynamic>> sessions = [
    {
      'daydate': 'July 10',
      'sessions': 'Lesson 1: AI Automation Technology f2f Attendance',
    },
    {
      'daydate': 'July 17',
      'sessions': 'Lesson 2: AI Automation Technology f2f Attendance',
    },
    {
      'daydate': 'July 24',
      'sessions': 'Lesson 3: AI Automation Technology f2f Attendance',
    },
    {
      'daydate': 'July 31',
      'sessions': 'Lesson 4: AI Automation Technology f2f Attendance',
    },
    {
      'daydate': 'Aug 07',
      'sessions': 'Lesson 5: AI Automation Technology f2f Attendance',
    },
    {
      'daydate': 'Aug 14',
      'sessions': 'Lesson 6: AI Automation Technology f2f Attendance',
    },
    {
      'daydate': 'Aug 21',
      'sessions': 'Lesson 7: AI Automation Technology f2f Attendance',
    },
    {
      'daydate': 'Aug 28',
      'sessions': 'Lesson 8: AI Automation Technology f2f Attendance',
    },
    {
      'daydate': 'Sep 04',
      'sessions': 'Lesson 9: AI Automation Technology f2f Attendance',
    },
    {
      'daydate': 'Sep 11',
      'sessions': 'Lesson 10: AI Automation Technology f2f Attendance',
    },
  ];

  // ── 🎨 Flutter override ───────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── 🛠️ Switcher module funtion ───────────────────────────
    return PopScope(
      canPop: !showDetails,
      onPopInvokedWithResult: (didPop, result) {
        debugPrint('POP TRIGGERED — didPop: $didPop, showDetail: $showDetails');
        if (didPop) return;
        setState(() => showDetails = false);
      },
      child: Padding(
        padding: EdgeInsetsGeometry.all(AppSpacing.md),
        child: showDetails ? buildDetailsView() : buildSummaryView(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // ── 🛠️ Switching module 1 ───────────────────────────
  // ──────────────────────────────────────────────────────
  Widget buildSummaryView() {
    return Column(
      spacing: AppSpacing.xm,
      children: [
        // ── 🗨️ Summry Report title ───────────────────────────
        Align(
          alignment: AlignmentGeometry.centerLeft,
          child: Text(
            'Summary Report',
            style: TextStyle(
              fontFamily: 'K2D',
              fontSize: AppFontSize.display,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // ── ⌛ Date and timer ───────────────────────────
        DateTimeCard(onDateChanged: (value) {}, selectedDate: DateTime.now()),

        // ── 📊 Section List Card ───────────────────────────
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return SectionCard(
                label: section['label'],
                selected: section['selected'],
                onTap: () {
                  setState(() {
                    for (var s in sections) {
                      s['selected'] = false;
                    }
                    section['selected'] = true;
                    selectedSection = section['label'];
                  });
                },
              );
            },
          ),
        ),

        // ── 🔍 Search bar ───────────────────────────
        SearchbarCard(onChanged: (value) {}),

        // ── 📋 Attendance Session List ───────────────────────────
        Expanded(
          child: ListView.separated(
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            scrollDirection: Axis.vertical,
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return SessionCard(
                onDoubleTap: () {
                  setState(() {
                    showDetails = true;
                    selectedSession = session;
                  });
                },
                daydate: session['daydate'],
                sessions: session['sessions'],
              );
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────
  // ── 🛠️ Switching module 2 ───────────────────────────
  // ──────────────────────────────────────────────────────
  Widget buildDetailsView() {
    return Column(
      spacing: AppSpacing.xm,
      children: [
        // ── 🔙 Header with back button + section title ───────────────────────────
        Row(
          spacing: AppSpacing.sm,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => showDetails = false),
            ),
            Text(
              selectedSection,
              style: TextStyle(
                fontFamily: 'K2D',
                fontSize: AppFontSize.display,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        // ── ⌛ Date and timer (reused) ───────────────────────────
        DateTimeCard(onDateChanged: (value) {}, selectedDate: DateTime.now()),

        // ── 🔍 Search bar + Export button ───────────────────────────
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(child: SearchbarCard(onChanged: (value) {})),
            ElevatedButton(onPressed: () {}, child: const Text('Export')),
          ],
        ),

        // ── 📋 Attendance List ───────────────────────────
        Expanded(
          child: ListView.separated(
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemCount: attendanceRecords.length,
            itemBuilder: (context, index) {
              final record = attendanceRecords[index];
              return AttendaceCard(
                studentId: record['studentId'],
                fullName: record['fullName'],
                time: record['time'],
                status: record['status'],
              );
            },
          ),
        ),
      ],
    );
  }
}
