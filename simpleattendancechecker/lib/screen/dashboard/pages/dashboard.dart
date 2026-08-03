import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/widget/attendace_card.dart';

class Dashboard extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const Dashboard({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedSection = 'All';
  String? _selectedStatus;
  bool _sortAscending = true;

  late final Timer _clockTimer;
  DateTime _now = DateTime.now();

  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    Connectivity().checkConnectivity().then((result) {
      if (mounted) {
        setState(
          () => _isOffline = result.every((r) => r == ConnectivityResult.none),
        );
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _clockTimer.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  String _sectionLabel(Map<String, dynamic> d) {
    final program = (d['program'] ?? '').toString();
    final year = (d['year'] ?? '').toString();
    final section = (d['section'] ?? '').toString();
    final yearDigits = RegExp(r'^\d+').firstMatch(year)?.group(0) ?? '';
    if (program.isEmpty && yearDigits.isEmpty && section.isEmpty) return '';
    return '$program $yearDigits-$section'.trim();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) widget.onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final formattedDate = DateFormat(
      'MMMM dd, yyyy',
    ).format(widget.selectedDate);
    final formattedTime = DateFormat('hh:mm:ss a').format(_now);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: dateStr)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Text(
                'An error occurred while fetching data:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colorpalatte.errorcolor),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final sections = <String>{'All'};
        for (final doc in docs) {
          final label = _sectionLabel(doc.data());
          if (label.isNotEmpty) sections.add(label);
        }

        final sectionDocs = docs.where((doc) {
          return _selectedSection == 'All' ||
              _sectionLabel(doc.data()) == _selectedSection;
        }).toList();

        final presentCount = sectionDocs
            .where((d) => d.data()['attendanceStatus'] == 'Present')
            .length;
        final lateCount = sectionDocs
            .where((d) => d.data()['attendanceStatus'] == 'Late')
            .length;
        final absentCount = sectionDocs
            .where((d) => d.data()['attendanceStatus'] == 'Absent')
            .length;
        final ojtCount = sectionDocs
            .where((d) => d.data()['attendanceStatus'] == 'OJT')
            .length;
        final workingCount = sectionDocs
            .where((d) => d.data()['attendanceStatus'] == 'Working Student')
            .length;

        final filteredDocs =
            sectionDocs.where((doc) {
              final d = doc.data();
              final name = (d['fullName'] ?? '').toString().toLowerCase();
              final id = (d['studentId'] ?? '').toString().toLowerCase();
              final query = _searchQuery.toLowerCase();
              final matchesSearch =
                  query.isEmpty || name.contains(query) || id.contains(query);
              final matchesStatus =
                  _selectedStatus == null ||
                  d['attendanceStatus'] == _selectedStatus;
              return matchesSearch && matchesStatus;
            }).toList()..sort((a, b) {
              final nameA = (a.data()['fullName'] ?? '').toString();
              final nameB = (b.data()['fullName'] ?? '').toString();
              return _sortAscending
                  ? nameA.compareTo(nameB)
                  : nameB.compareTo(nameA);
            });

        return CustomScrollView(
          slivers: [
            // ── 📌 Sticky header — Overview + Stats + Sections ──────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                height: 278,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
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
                      const SizedBox(height: AppSpacing.sm),

                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xm,
                          ),
                          width: double.infinity,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colorpalatte.secondary,
                            borderRadius: BorderRadius.circular(AppRadius.xm),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: Colorpalatte.maincolor,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colorpalatte.maincolor,
                                      fontFamily: 'K2D',
                                      fontSize: AppFontSize.body,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                isToday
                                    ? 'Time: $formattedTime'
                                    : 'Tap to change date',
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
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      SizedBox(
                        height: 90,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _statChip(
                              '$presentCount',
                              'Present',
                              Colorpalatte.sucesscolor,
                            ),
                            _statChip(
                              '$lateCount',
                              'Late',
                              Colorpalatte.warningcolor,
                            ),
                            _statChip(
                              '$absentCount',
                              'Absent',
                              Colorpalatte.errorcolor,
                            ),
                            _statChip(
                              '$ojtCount',
                              'OJT',
                              Colorpalatte.ojtcolor,
                            ),
                            _statChip(
                              '$workingCount',
                              'Working',
                              Colorpalatte.infocolor,
                              value: 'Working Student',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        'Sections',
                        style: TextStyle(
                          fontFamily: 'K2D',
                          fontSize: AppFontSize.title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: sections.map((s) {
                            final selected = s == _selectedSection;
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
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
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                  side: BorderSide.none,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isOffline)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colorpalatte.warningcolor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 16,
                          color: Colorpalatte.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Offline mode — showing local data',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: Colorpalatte.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── 🔍 Search + sort + attendance count (gumagalaw sa scroll) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance',
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
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Search by name or student ID',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colorpalatte.containercolor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          decoration: BoxDecoration(
                            color: Colorpalatte.containercolor,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: IconButton(
                            tooltip: _sortAscending ? 'A-Z' : 'Z-A',
                            icon: Icon(
                              _sortAscending
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: Colorpalatte.secondary,
                            ),
                            onPressed: () => setState(
                              () => _sortAscending = !_sortAscending,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (snapshot.connectionState == ConnectionState.waiting &&
                docs.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredDocs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No matching records.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index.isOdd) {
                        return const SizedBox(height: AppSpacing.xs);
                      }
                      final d = filteredDocs[index ~/ 2].data();
                      return AttendaceCard(
                        fullName: d['fullName'] ?? '',
                        studentId: d['studentId'] ?? '',
                        time: d['time'] ?? '',
                        status: d['attendanceStatus'] ?? '',
                      );
                    },
                    childCount: filteredDocs.isEmpty
                        ? 0
                        : filteredDocs.length * 2 - 1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _statChip(String count, String label, Color color, {String? value}) {
    final filterValue = value ?? label;
    final selected = _selectedStatus == filterValue;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: GestureDetector(
        onTap: () =>
            setState(() => _selectedStatus = selected ? null : filterValue),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          width: 100,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colorpalatte.containercolor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: selected ? Border.all(color: color, width: 2) : null,
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
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppFontSize.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 📌 Delegate para sa sticky/pinned header ───────────────────────────
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _PinnedHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(color: Colorpalatte.maincolor, child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return true;
  }
}
