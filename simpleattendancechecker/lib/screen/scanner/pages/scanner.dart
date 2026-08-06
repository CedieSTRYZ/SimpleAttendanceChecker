import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/screen/scanner/functions/scanned_qr_sheet.dart';
import 'package:simpleattendancechecker/screen/scanner/functions/scanner_overlay_painter.dart';
import 'package:simpleattendancechecker/services/biometric_service.dart';

class Scanner extends StatefulWidget {
  final bool isActive;
  const Scanner({super.key, required this.isActive});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  late final MobileScannerController controller;
  final TextEditingController _manualIdController = TextEditingController();
  final FocusNode _manualIdFocusNode = FocusNode();

  bool _isProcessing = false;
  bool _lateMode = false;
  bool _isMarkingAbsent = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      autoStart: widget.isActive,
    );
    _manualIdController.addListener(_onManualIdChanged);
  }

  @override
  void didUpdateWidget(covariant Scanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      controller.start();
    } else {
      controller.stop();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _manualIdController.dispose();
    _manualIdFocusNode.dispose();
    super.dispose();
  }

  // ── ⌨️ Manual entry — auto-submits once it reaches 14 characters ──────
  void _onManualIdChanged() {
    final value = _manualIdController.text.trim();
    if (value.length == 14 && !_isProcessing) {
      _manualIdController.clear();
      _handleScan(value);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    // ── 🩹 Black screen fix: we no longer stop/start the camera ──────
    // we just flag _isProcessing so further detections are ignored
    // while the confirmation sheet is open.
    _isProcessing = true;

    if (mounted) {
      await _handleScan(rawValue);
    }

    _isProcessing = false;
  }

  // ── 🔎 Firestore lookup — preview only, nothing written yet ───────────
  Future<void> _handleScan(String studentId) async {
    _isProcessing = true;
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (!mounted) return;

      if (!studentDoc.exists) {
        await _showInfoDialog(
          'Student ID Not Found',
          'No record found for Student ID "$studentId". Please check if the QR code is correct or contact the administrator.',
        );
        return;
      }

      final data = studentDoc.data()!;
      final fullName = (data['fullName'] as String?) ?? 'Unknown student';
      final program = (data['program'] as String?) ?? '';
      final year = (data['year'] as String?) ?? '';
      final section = (data['section'] as String?) ?? '';
      final email = (data['email'] as String?) ?? '';
      final studentType = (data['studentType'] as String?) ?? 'Student';

      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      final existing = await FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .where('date', isEqualTo: todayStr)
          .limit(1)
          .get();

      if (!mounted) return;

      if (existing.docs.isNotEmpty) {
        await _showInfoDialog(
          'Already Logged',
          '$fullName has already been recorded for attendance today.',
        );
        return;
      }

      final String status;
      if (studentType != 'Student') {
        status = studentType;
      } else {
        status = _lateMode ? 'Late' : 'Present';
      }

      final yearDigits = RegExp(r'^\d+').firstMatch(year)?.group(0) ?? '';
      final yearSection = '$yearDigits-$section';

      if (!mounted) return;

      await ScannedQrSheet.show(
        context,
        {
          'studentId': studentId,
          'name': fullName,
          'program': program,
          'year': year,
          'section': section,
          'yearSection': yearSection,
          'email': email,
          'studentType': studentType,
          'status': status,
          'dateToday': '${now.month}/${now.day}/${now.year}',
          'timeRecorded':
              '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        },
        onConfirm: () async {
          final docId =
              '${studentId}_${DateFormat('yyyyMMdd_HHmmss').format(now)}';
          await FirebaseFirestore.instance
              .collection('attendance')
              .doc(docId)
              .set({
                'studentId': studentId,
                'fullName': fullName,
                'attendanceStatus': status,
                'program': program,
                'year': year,
                'section': section,
                'date': todayStr,
                'time': DateFormat('HH:mm').format(now),
                'timestamp': Timestamp.fromDate(now),
                'selfScanned': true,
              });
        },
      );

      if (mounted) {
        try {
          await controller.stop();
          await controller.start();
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        'Error occurred',
        'The scan could not be processed: $e',
      );
    } finally {
      _isProcessing = false;
      // if (mounted) {
      //   _manualIdFocusNode.requestFocus();
      // }
    }
  }

  // ── 🚫 Mark absent — with a section dropdown + biometric confirmation ──
  // MAKING ALL STUDENT AS ABSENT IF NOT ATTEND TO THE CLASS {#77f,167}
  Future<void> _markAbsentees() async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allStudents;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .get();
      allStudents = snap.docs;
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        'Error occurred',
        'Could not retrieve the student list: $e',
      );
      return;
    }

    if (!mounted) return;

    const allStudentsOption = 'All Students (All Programs/Sections)';

    final sections = <String>{};
    for (final doc in allStudents) {
      final label = _studentSectionLabel(doc.data());
      if (label.isNotEmpty) sections.add(label);
    }
    final sortedSections = <String>[
      allStudentsOption,
      ...sections.toList()..sort(),
    ];

    String? selectedSection;

    // LAST AUTHENTICATION FOR MARKING AS ABSENT {#9b2,43}
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colorpalatte.maincolor,
              title: const Text('Mark as Absent'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select the Program - Year & Section, or mark all students:',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSection,
                    isExpanded: true,
                    hint: const Text('Select an option'),
                    items: sortedSections
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedSection = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: selectedSection == null
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedSection == null) return;

    final isAllStudents = selectedSection == allStudentsOption;

    final verified = await BiometricService.authenticate();
    if (!mounted) return;
    if (!verified) {
      await _showInfoDialog(
        'Not Confirmed',
        'Mark as Absent was cancelled because biometric verification failed.',
      );
      return;
    }

    setState(() => _isMarkingAbsent = true);

    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      final attendanceToday = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: todayStr)
          .get();

      final loggedIds = attendanceToday.docs
          .map((doc) => doc.data()['studentId'] as String?)
          .whereType<String>()
          .toSet();

      final batch = FirebaseFirestore.instance.batch();
      int markedCount = 0;

      for (final doc in allStudents) {
        final data = doc.data();
        final label = _studentSectionLabel(data);

        // ── skip if a specific section was chosen and this student isn't in it ──
        if (!isAllStudents && label != selectedSection) {
          continue;
        }

        final studentId = doc.id;
        if (loggedIds.contains(studentId)) continue; // already logged

        final studentType = (data['studentType'] as String?) ?? 'Student';
        // ── If OJT/Working Student, use studentType itself as the status ──
        final status = studentType == 'Student' ? 'Absent' : studentType;

        final docId =
            '${studentId}_${DateFormat('yyyyMMdd_HHmmss').format(now)}';
        final ref = FirebaseFirestore.instance
            .collection('attendance')
            .doc(docId);

        batch.set(ref, {
          'studentId': studentId,
          'fullName': data['fullName'] ?? '',
          'attendanceStatus': status,
          'program': data['program'] ?? '',
          'year': data['year'] ?? '',
          'section': data['section'] ?? '',
          'date': todayStr,
          'time': DateFormat('HH:mm').format(now),
          'timestamp': Timestamp.fromDate(now),
          'selfScanned': false,
        });
        markedCount++;
      }

      if (markedCount > 0) {
        await batch.commit();
      }

      if (!mounted) return;
      final scopeLabel = isAllStudents ? 'all students' : '"$selectedSection"';
      await _showInfoDialog(
        'Done',
        markedCount > 0
            ? '$markedCount student(s) from $scopeLabel were logged.'
            : 'No unlogged students remain for $scopeLabel today.',
      );
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog('Error occurred', 'Could not process: $e');
    } finally {
      if (mounted) setState(() => _isMarkingAbsent = false);
    }
  }

  // ── 🏷️ Section label from the student profile (students collection) ──
  String _studentSectionLabel(Map<String, dynamic> d) {
    final program = (d['program'] ?? '').toString();
    final year = (d['year'] ?? '').toString();
    final section = (d['section'] ?? '').toString();
    final yearDigits = RegExp(r'^\d+').firstMatch(year)?.group(0) ?? '';
    if (program.isEmpty && yearDigits.isEmpty && section.isEmpty) return '';
    return '$program $yearDigits-$section'.trim();
  }

  // SHOWDIALOG IF STUDENT IS ALREADY SCANNED {#14b,16}
  Future<void> _showInfoDialog(String title, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colorpalatte.maincolor,
        title: Text(title, style: const TextStyle(fontFamily: 'K2D')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        spacing: AppSpacing.sm,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 📝 HEADER ───────────────────────────
          Text(
            'Attendance Scanner',
            style: TextStyle(
              fontFamily: 'K2D',
              fontSize: AppFontSize.display,
              fontWeight: FontWeight.w700,
            ),
          ),

          // ── 📷 Scanner viewfinder ───────────────────────────
          // SCANNER AREA {#03b,47}
          Center(
            child: Container(
              width: MediaQuery.widthOf(context) * 0.85,
              height: MediaQuery.heightOf(context) * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: LinearGradient(
                  colors: [Colorpalatte.ojtcolor, Colorpalatte.secondary],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final cutoutSize = size.shortestSide * 0.6;
                    final scanWindow = Rect.fromCenter(
                      center: Offset(size.width / 2, size.height / 2),
                      width: cutoutSize,
                      height: cutoutSize,
                    );

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: controller,
                          onDetect: _onDetect,
                          fit: BoxFit.cover,
                        ),
                        CustomPaint(
                          size: size,
                          painter: ScannerOverlayPainter(
                            scanWindow: scanWindow,
                            borderColor: Colorpalatte.accentcolor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          Center(
            child: Text(
              "Point your camera at QR Code to scan",
              style: TextStyle(
                fontFamily: 'K2D',
                fontSize: AppFontSize.subtitle,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // ── 🎛️ Control panel — clean and organized ─────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colorpalatte.containercolor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // PHONE FLASH {#ef9,34}
                    ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, state, child) {
                        final torchOn = state.torchState == TorchState.on;
                        return Row(
                          children: [
                            IconButton(
                              onPressed: () => controller.toggleTorch(),
                              icon: Icon(
                                torchOn
                                    ? Icons.bolt_rounded
                                    : Icons.bolt_outlined,
                              ),
                              color: torchOn
                                  ? Colorpalatte.accentcolor
                                  : Colorpalatte.mutedcolor,
                              style: IconButton.styleFrom(
                                backgroundColor: Colorpalatte.maincolor,
                                shape: const CircleBorder(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Flash',
                              style: TextStyle(
                                fontFamily: 'K2D',
                                fontSize: AppFontSize.caption,
                                color: Colorpalatte.mutedcolor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // LATE SWITCH BUTTON {#2e8,23}
                    Row(
                      spacing: AppSpacing.xs,
                      children: [
                        Text(
                          'Late Mode',
                          style: TextStyle(
                            fontFamily: 'K2D',
                            fontSize: AppFontSize.caption,
                            fontWeight: _lateMode
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: _lateMode
                                ? Colorpalatte.errorcolor
                                : Colorpalatte.mutedcolor,
                          ),
                        ),
                        Switch(
                          value: _lateMode,
                          activeThumbColor: Colorpalatte.errorcolor,
                          onChanged: (v) => setState(() => _lateMode = v),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(height: AppSpacing.lg),

                // ── ⌨️ Manual Student ID entry ────────
                // MANUAL ENTRY OF STUDENT ID {#f0b,18}
                TextField(
                  controller: _manualIdController,
                  focusNode: _manualIdFocusNode,
                  maxLength: 14,
                  inputFormatters: [LengthLimitingTextInputFormatter(14)],
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '06-1234-567890',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: Colorpalatte.maincolor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── 🚫 Mark as Absent ───────────────────────────
                // BUTTON FOR MARKING ABSENT ALL STUDENT {#d08,33}
                ElevatedButton.icon(
                  onPressed: _isMarkingAbsent ? null : _markAbsentees,
                  icon: _isMarkingAbsent
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colorpalatte.errorcolor,
                          ),
                        )
                      : Icon(
                          Icons.person_off_rounded,
                          color: Colorpalatte.errorcolor,
                        ),
                  label: Text(
                    _isMarkingAbsent ? 'Marking...' : 'Mark as Absent',
                    style: TextStyle(color: Colorpalatte.errorcolor),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colorpalatte.errorcolor.withValues(
                      alpha: 0.1,
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(color: Colorpalatte.errorcolor),
                    ),
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
