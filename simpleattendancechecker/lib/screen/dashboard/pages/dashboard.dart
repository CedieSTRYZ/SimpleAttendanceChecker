import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/widget/attendace_card.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _searchQuery = '';
  String _selectedSection = 'All';

  // ── 🏷️ I-buo ang label ng section, hal. "BSIT 4-1" ───────────────────
  String _sectionLabel(Map<String, dynamic> d) {
    final program = (d['program'] ?? '').toString();
    final year = (d['year'] ?? '').toString();
    final section = (d['section'] ?? '').toString();
    final yearDigits = RegExp(r'^\d+').firstMatch(year)?.group(0) ?? '';
    if (program.isEmpty && yearDigits.isEmpty && section.isEmpty) return '';
    return '$program $yearDigits-$section'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    final formattedTime = DateFormat('hh:mm a').format(DateTime.now());

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: todayStr)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        final presentCount =
            docs.where((d) => d['attendanceStatus'] == 'Present').length;
        final lateCount =
            docs.where((d) => d['attendanceStatus'] == 'Late').length;
        final absentCount =
            docs.where((d) => d['attendanceStatus'] == 'Absent').length;
        final ojtCount =
            docs.where((d) => d['attendanceStatus'] == 'OJT').length;
        final workingCount = docs
            .where((d) => d['attendanceStatus'] == 'Working Student')
            .length;

        // ── 🏷️ I-collect ang lahat ng distinct sections ngayong araw ─────
        final sections = <String>{'All'};
        for (final doc in docs) {
          final label = _sectionLabel(doc.data());
          if (label.isNotEmpty) sections.add(label);
        }
        if (!sections.contains(_selectedSection)) {
          _selectedSection = 'All';
        }

        final filteredDocs = docs.where((doc) {
          final d = doc.data();
          final name = (d['fullName'] ?? '').toString().toLowerCase();
          final id = (d['studentId'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          final matchesSearch =
              query.isEmpty || name.contains(query) || id.contains(query);
          final matchesSection = _selectedSection == 'All' ||
              _sectionLabel(d) == _selectedSection;
          return matchesSearch && matchesSection;
        }).toList();

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
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _statCard('$presentCount', 'Present', Colorpalatte.sucesscolor),
                    _statCard('$lateCount', 'Late', Colorpalatte.warningcolor),
                    _statCard('$absentCount', 'Absent', Colorpalatte.errorcolor),
                    _statCard('$ojtCount', 'OJT', Colorpalatte.ojtcolor),
                    _statCard('$workingCount', 'Working', Colorpalatte.infocolor),
                  ],
                ),
              ),

              // ── 🏷️ Sections filter (dating static na lang, gumagana na) ────
              Text(
                'Sections',
                style: TextStyle(
                  fontFamily: 'K2D',
                  fontSize: AppFontSize.title,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: sections.map((s) {
                    final selected = s == _selectedSection;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedSection = s),
                        selectedColor: Colorpalatte.secondary,
                        backgroundColor: Colorpalatte.containercolor,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colorpalatte.maincolor
                              : Colorpalatte.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          side: BorderSide.none,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Attendance",
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: AppFontSize.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${filteredDocs.length} scanned',
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: AppFontSize.caption,
                      color: Colorpalatte.mutedcolor,
                    ),
                  ),
                ],
              ),
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name or student ID',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colorpalatte.containercolor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : filteredDocs.isEmpty
                        ? Center(
                            child: Text(
                              'Wala pang naka-log ngayong araw.',
                              style: TextStyle(color: Colorpalatte.mutedcolor),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredDocs.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.xs),
                            itemBuilder: (context, index) {
                              final d = filteredDocs[index].data();
                              return AttendaceCard(
                                fullName: d['fullName'] ?? '',
                                studentId: d['studentId'] ?? '',
                                time: d['time'] ?? '',
                                status: d['attendanceStatus'] ?? '',
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String count, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.sm),
        width: 100,
        decoration: BoxDecoration(
          color: Colorpalatte.containercolor,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: AppFontSize.title,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: AppFontSize.caption)),
          ],
        ),
      ),
    );
  }
}