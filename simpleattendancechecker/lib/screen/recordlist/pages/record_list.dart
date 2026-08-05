import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/screen/recordlist/pages/section_student_list.dart';
import 'package:simpleattendancechecker/screen/recordlist/pages/student_attendance_log.dart';

enum _RecordView { masterlist, studentList, studentLog }

class _SectionGroup {
  final String program;
  final String year;
  final String section;
  final String label;
  final int count;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;

  _SectionGroup({
    required this.program,
    required this.year,
    required this.section,
    required this.label,
    required this.count,
    required this.students,
  });
}

class RecordList extends StatefulWidget {
  const RecordList({super.key});

  @override
  State<RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<RecordList> {
  _RecordView _view = _RecordView.masterlist;

  String? _selectedProgram;
  String? _selectedYear;
  String? _selectedSection;

  _SectionGroup? _activeGroup;
  String? _activeStudentId;
  String? _activeStudentName;

  String _yearDigits(String year) =>
      RegExp(r'^\d+').firstMatch(year)?.group(0) ?? '';

  void _openSection(_SectionGroup group) {
    setState(() {
      _activeGroup = group;
      _view = _RecordView.studentList;
    });
  }

  void _openStudent(String studentId, String fullName) {
    setState(() {
      _activeStudentId = studentId;
      _activeStudentName = fullName;
      _view = _RecordView.studentLog;
    });
  }

  void _backToMasterlist() {
    setState(() {
      _view = _RecordView.masterlist;
      _activeGroup = null;
    });
  }

  void _backToStudentList() {
    setState(() {
      _view = _RecordView.studentList;
      _activeStudentId = null;
      _activeStudentName = null;
    });
  }

  Future<void> _showFilterPicker(
    String title,
    List<String> options,
    String? current,
    ValueChanged<String?> onPicked,
  ) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colorpalatte.maincolor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'K2D',
                    fontSize: AppFontSize.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ListTile(
                title: const Text('All'),
                trailing:
                    current == null ? Icon(Icons.check, color: Colorpalatte.secondary) : null,
                onTap: () => Navigator.pop(context, null),
              ),
              ...options.map((o) => ListTile(
                    title: Text(o),
                    trailing: current == o
                        ? Icon(Icons.check, color: Colorpalatte.secondary)
                        : null,
                    onTap: () => Navigator.pop(context, o),
                  )),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
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

        final allStudents = snapshot.data?.docs ?? [];

        final Map<String, _SectionGroup> groupMap = {};
        final programs = <String>{};
        final years = <String>{};
        final sectionsSet = <String>{};

        for (final doc in allStudents) {
          final d = doc.data();
          final program = (d['program'] ?? '').toString().trim();
          final rawYear = (d['year'] ?? '').toString().trim();
          final yearDigits = _yearDigits(rawYear);
          final section = (d['section'] ?? '').toString().trim();
          if (program.isEmpty || yearDigits.isEmpty || section.isEmpty) continue;

          programs.add(program);
          years.add(yearDigits);
          sectionsSet.add(section);

          final key = '$program|$yearDigits|$section';
          final group = groupMap[key];
          if (group == null) {
            groupMap[key] = _SectionGroup(
              program: program,
              year: yearDigits,
              section: section,
              label: '$yearDigits-$section',
              count: 1,
              students: [doc],
            );
          } else {
            groupMap[key] = _SectionGroup(
              program: group.program,
              year: group.year,
              section: group.section,
              label: group.label,
              count: group.count + 1,
              students: [...group.students, doc],
            );
          }
        }

        var groups = groupMap.values.toList()
          ..sort((a, b) {
            final byProgram = a.program.compareTo(b.program);
            if (byProgram != 0) return byProgram;
            final byYear = a.year.compareTo(b.year);
            if (byYear != 0) return byYear;
            return a.section.compareTo(b.section);
          });

        if (_selectedProgram != null) {
          groups = groups.where((g) => g.program == _selectedProgram).toList();
        }
        if (_selectedYear != null) {
          groups = groups.where((g) => g.year == _selectedYear).toList();
        }
        if (_selectedSection != null) {
          groups = groups.where((g) => g.section == _selectedSection).toList();
        }

        switch (_view) {
          case _RecordView.studentList:
            if (_activeGroup == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _backToMasterlist());
              return const SizedBox.shrink();
            }
            final refreshedGroup = groupMap[
                    '${_activeGroup!.program}|${_activeGroup!.year}|${_activeGroup!.section}'] ??
                _activeGroup!;
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: SectionStudentList(
                program: refreshedGroup.program,
                year: refreshedGroup.year,
                section: refreshedGroup.section,
                sectionLabel: '${refreshedGroup.program} ${refreshedGroup.label}',
                students: refreshedGroup.students,
                onBack: _backToMasterlist,
                onSelectStudent: _openStudent,
              ),
            );

          case _RecordView.studentLog:
            if (_activeStudentId == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _backToMasterlist());
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: StudentAttendanceLog(
                studentId: _activeStudentId!,
                fullName: _activeStudentName ?? '',
                onBack: _backToStudentList,
              ),
            );

          case _RecordView.masterlist:
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masterlist',
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: AppFontSize.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xm),
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
                            Icon(Icons.calendar_today_rounded,
                                size: 16, color: Colorpalatte.maincolor),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                              style: TextStyle(
                                color: Colorpalatte.maincolor,
                                fontFamily: 'K2D',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Time: ${DateFormat('hh:mm a').format(DateTime.now())}',
                          style: TextStyle(
                            color: Colorpalatte.maincolor,
                            fontFamily: 'K2D',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _filterChip(
                          label: 'All',
                          selected: _selectedProgram == null &&
                              _selectedYear == null &&
                              _selectedSection == null,
                          onTap: () => setState(() {
                            _selectedProgram = null;
                            _selectedYear = null;
                            _selectedSection = null;
                          }),
                        ),
                        _dropdownChip(
                          label: _selectedProgram ?? 'Program',
                          active: _selectedProgram != null,
                          onTap: () => _showFilterPicker(
                            'Select Program',
                            programs.toList()..sort(),
                            _selectedProgram,
                            (v) => setState(() => _selectedProgram = v),
                          ),
                        ),
                        _dropdownChip(
                          label:
                              _selectedSection != null ? 'Section $_selectedSection' : 'Section',
                          active: _selectedSection != null,
                          onTap: () => _showFilterPicker(
                            'Select Section',
                            sectionsSet.toList()..sort(),
                            _selectedSection,
                            (v) => setState(() => _selectedSection = v),
                          ),
                        ),
                        _dropdownChip(
                          label: _selectedYear != null ? 'Year $_selectedYear' : 'Year',
                          active: _selectedYear != null,
                          onTap: () => _showFilterPicker(
                            'Select Year',
                            years.toList()..sort(),
                            _selectedYear,
                            (v) => setState(() => _selectedYear = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting &&
                            allStudents.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : groups.isEmpty
                            ? Center(
                                child: Text(
                                  'No sections found.',
                                  style: TextStyle(color: Colorpalatte.mutedcolor),
                                ),
                              )
                            : ListView.separated(
                                itemCount: groups.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.xs),
                                itemBuilder: (context, index) {
                                  final g = groups[index];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    onTap: () => _openSection(g),
                                    child: Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: Colorpalatte.containercolor,
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: AppSpacing.xs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colorpalatte.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(AppRadius.sm),
                                            ),
                                            child: Text(
                                              g.label,
                                              style: TextStyle(
                                                fontFamily: 'K2D',
                                                fontWeight: FontWeight.w700,
                                                color: Colorpalatte.maincolor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              g.program,
                                              style: TextStyle(
                                                fontFamily: 'K2D',
                                                fontWeight: FontWeight.w700,
                                                fontSize: AppFontSize.body,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${g.count} Students',
                                            style: TextStyle(
                                              fontSize: AppFontSize.caption,
                                              color: Colorpalatte.mutedcolor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colorpalatte.secondary,
        backgroundColor: Colorpalatte.containercolor,
        labelStyle: TextStyle(
          color: selected ? Colorpalatte.maincolor : Colorpalatte.secondary,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdownChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ActionChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          ],
        ),
        onPressed: onTap,
        backgroundColor:
            active ? Colorpalatte.secondary.withOpacity(0.15) : Colorpalatte.containercolor,
        labelStyle: TextStyle(
          color: active ? Colorpalatte.secondary : Colorpalatte.mutedcolor,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide.none,
        ),
      ),
    );
  }
}