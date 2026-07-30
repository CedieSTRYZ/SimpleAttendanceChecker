import 'package:flutter/material.dart';
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
    final rawValue = barcode?.rawValue;
    if (rawValue == null) return;

    _isProcessing = true;
    await controller.stop();

    if (!mounted) return;
    final data = _parseQrData(rawValue);
    await ScannedQrSheet.show(context, data);

    _isProcessing = false;
    if (widget.isActive) {
      controller.start();
    }
  }

  // ── 🔎 Parse functionss ───────────────────────────
  Map<String, String> _parseQrData(String rawValue) {
    const labels = [
      'ID',
      'Name',
      'Program',
      'Year',
      'Section',
      'Email',
      'Status',
    ];

    final pattern = RegExp(
      r'(' +
          labels.join('|') +
          r'):\s*(.*?)(?=,\s*(?:' +
          labels.join('|') +
          r'):|$)',
    );

    final matches = pattern.allMatches(rawValue);
    final parsed = <String, String>{};
    for (final m in matches) {
      final key = m.group(1)!;
      final value = m.group(2)!.trim();
      parsed[key] = value;
    }

    final yearDigits =
        RegExp(r'^\d+').firstMatch(parsed['Year'] ?? '')?.group(0) ?? '';
    final yearSection = '$yearDigits-${parsed['Section'] ?? ''}';

    final now = DateTime.now();
    return {
      'raw': rawValue,
      'studentId': parsed['ID'] ?? '',
      'name': parsed['Name'] ?? '',
      'program': parsed['Program'] ?? '',
      'year': parsed['Year'] ?? '',
      'section': parsed['Section'] ?? '',
      'yearSection': yearSection,
      'email': parsed['Email'] ?? '',
      'studentType': parsed['Status'] ?? '',
      'status': 'Present',
      'dateToday': '${now.month}/${now.day}/${now.year}',
      'timeRecorded': '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    };
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

              // ── 🔎 Scanning point ───────────────────────────
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

          // ── 🚨 Reminder text ───────────────────────────
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
              // ── 🔄️ Flash button ───────────────────────────
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

              // ── 🔄️ Rerstart button ───────────────────────────
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

          // ── ⏳ Late button ───────────────────────────
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              label: Text('Set Late'),
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
