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
  // ── 🛠️ Functions ───────────────────────────
  late final MobileScannerController controller;
  bool _isProcessing = false;
  bool _lateMode = false;

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

  // ── 🔎 Firestore lookup + attendance logging ───────────────────────────
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

      // ── ⏳ I-check kung may naka-log na ngayong araw ───────────────────────
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

      // ── ✅ I-determine ang attendance status ───────────────────────────
      // ── ✅ Determine attendance status ───────────────────────────
      final String status;

      if (studentType != 'Student') {
        // OJT / Working Student
        status = studentType;
      } else {
        // Regular students
        status = _lateMode ? 'Late' : 'Present';
      }

      final yearDigits = RegExp(r'^\d+').firstMatch(year)?.group(0) ?? '';
      final yearSection = '$yearDigits-$section';

final docId =
    '${studentId}_${DateFormat('yyyyMMdd_HHmmss').format(now)}';

      await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
        'studentId': studentId,
        'fullName': fullName,
        'attendanceStatus': status,
        'date': todayStr,
        'time': DateFormat('HH:mm').format(now),
        'timestamp': Timestamp.fromDate(now),
      });

      if (!mounted) return;

      await ScannedQrSheet.show(context, {
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
        'timeRecorded': '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      });
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        'Error occurred',
        'The scan could not be processed: $e',
      );
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

  // ── 📱 UI builder ───────────────────────────
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

          // ── 🔍 Scanner area ───────────────────────────
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
                onPressed: () {
                  _isProcessing = false;
                  controller.start();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: CircleBorder(),
                  fixedSize: Size(40, 40),
                  iconColor: Colorpalatte.mutedcolor,
                  iconSize: 30,
                  backgroundColor: Colorpalatte.containercolor,
                ),
                child: Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),

          // ── ⏳ Late toggle button ───────────────────────────
          Center(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _lateMode = !_lateMode),
              icon: Icon(
                _lateMode ? Icons.check_circle : Icons.access_time,
                color: Colorpalatte.maincolor,
              ),
              label: Text(_lateMode ? 'Late Mode: ON' : 'Set Late'),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.widthOf(context) * 0.95, 40),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(5),
                ),
                backgroundColor: _lateMode
                    ? Colorpalatte.errorcolor
                    : Colorpalatte.secondary,
                foregroundColor: Colorpalatte.maincolor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
