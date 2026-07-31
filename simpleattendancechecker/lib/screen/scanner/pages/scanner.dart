import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/screen/scanner/functions/scanned_qr_sheet.dart';
import 'package:simpleattendancechecker/screen/scanner/functions/scanner_overlay_painter.dart';

class Scanner extends StatefulWidget {
  final bool isActive;
  const Scanner({super.key, required this.isActive});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  late final MobileScannerController controller;
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
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    _isProcessing = true;
    await controller.stop();

    if (mounted) {
      await _handleScan(rawValue);
    }

    _isProcessing = false;
    if (mounted && widget.isActive) {
      controller.start();
    }
  }

  // ── 🔎 Firestore lookup — preview lang, walang isusulat pa ────────────
  Future<void> _handleScan(String studentId) async {
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
                'program': program, // ← bago
                'year': year, // ← bago
                'section': section, // ← bago
                'date': todayStr,
                'time': DateFormat('HH:mm').format(now),
                'timestamp': Timestamp.fromDate(now),
              });
        },
      );
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        'Error occurred',
        'The scan could not be processed: $e',
      );
    }
  }

  // ── 🚫 Mark absent para sa mga hindi na-scan ngayong araw ─────────────
  Future<void> _markAbsentees() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Absent'),
        content: const Text(
          'I-mamark na "Absent" ang lahat ng regular na estudyante na hindi na-scan ngayong araw. Hindi kasama ang OJT at Working Student. Sigurado ka ba?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int markedCount = 0;

      for (final doc in studentsSnapshot.docs) {
        final data = doc.data();
        final studentType = (data['studentType'] as String?) ?? 'Student';
        final studentId = doc.id;

        if (studentType != 'Student') continue;
        if (loggedIds.contains(studentId)) continue;

        final docId =
            '${studentId}_${DateFormat('yyyyMMdd_HHmmss').format(now)}';
        final ref = FirebaseFirestore.instance
            .collection('attendance')
            .doc(docId);

        batch.set(ref, {
          'studentId': studentId,
          'fullName': data['fullName'] ?? '',
          'attendanceStatus': 'Absent',
          'program': data['program'] ?? '', 
          'year': data['year'] ?? '', 
          'section': data['section'] ?? '',
          'date': todayStr,
          'time': DateFormat('HH:mm').format(now),
          'timestamp': Timestamp.fromDate(now),
        });
        markedCount++;
      }

      if (markedCount > 0) {
        await batch.commit();
      }

      if (!mounted) return;
      await _showInfoDialog(
        'Done',
        markedCount > 0
            ? '$markedCount na estudyante ang na-mark na "Absent".'
            : 'Wala nang estudyanteng hindi pa naka-log ngayong araw.',
      );
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog('Error occurred', 'Hindi na-process: $e');
    } finally {
      if (mounted) setState(() => _isMarkingAbsent = false);
    }
  }

  Future<void> _showInfoDialog(String title, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        spacing: AppSpacing.xs,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan for Attendance',
            style: TextStyle(
              fontFamily: 'K2D',
              fontSize: AppFontSize.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.widthOf(context) * 0.85,
              height: MediaQuery.heightOf(context) * 0.45,
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

          // ── 🔦 Flash + ⏳ Late toggle ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, state, child) {
                  final torchOn = state.torchState == TorchState.on;
                  return ElevatedButton(
                    onPressed: () => controller.toggleTorch(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: CircleBorder(),
                      fixedSize: Size(40, 40),
                      iconColor: torchOn
                          ? Colorpalatte.accentcolor
                          : Colorpalatte.mutedcolor,
                      iconSize: 30,
                      backgroundColor: Colorpalatte.containercolor,
                    ),
                    child: Center(
                      child: Icon(
                        torchOn ? Icons.bolt_rounded : Icons.bolt_outlined,
                      ),
                    ),
                  );
                },
              ),
              ElevatedButton(
                onPressed: () => setState(() => _lateMode = !_lateMode),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: CircleBorder(),
                  fixedSize: Size(40, 40),
                  iconColor: _lateMode
                      ? Colorpalatte.errorcolor
                      : Colorpalatte.mutedcolor,
                  iconSize: 30,
                  backgroundColor: Colorpalatte.containercolor,
                ),
                child: Icon(
                  _lateMode ? Icons.watch_later_rounded : Icons.access_time,
                ),
              ),
            ],
          ),

          // ── 🚫 Mark as Absent ───────────────────────────
          Center(
            child: ElevatedButton.icon(
              onPressed: _isMarkingAbsent ? null : _markAbsentees,
              icon: _isMarkingAbsent
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colorpalatte.maincolor,
                      ),
                    )
                  : Icon(
                      Icons.person_off_rounded,
                      color: Colorpalatte.maincolor,
                    ),
              label: Text(_isMarkingAbsent ? 'Marking...' : 'Mark as Absent'),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.widthOf(context) * 0.95, 40),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(5),
                ),
                backgroundColor: Colorpalatte.secondary,
                foregroundColor: Colorpalatte.maincolor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
