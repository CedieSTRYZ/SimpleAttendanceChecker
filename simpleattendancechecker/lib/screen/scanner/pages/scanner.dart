import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:simpleattendancechecker/constants/colorpalatte.dart';

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

    if (mounted) return;
    await _bottomSheet(rawValue);
  }

  //TODO: Make this connected to firebase and replace the parse function {#729,10}
  // ── 🔎 Parse functionss ───────────────────────────
  Map<String, String> _parseQrData(String rawValue) {
    final parts = rawValue.split('-');
    return {
      'raw': rawValue,
      'section': parts.isNotEmpty ? parts[0] : '',
      'schoolYear': parts.length > 1 ? parts[1] : '',
      'studentId': parts.length > 2 ? parts[2] : '',
    };
  }

  // ── 📱 UI builder ───────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        spacing: 20,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan for Attendance',
            style: TextStyle(
              fontFamily: 'K2D',
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),

          // ── 🔍 Scanner area ───────────────────────────
          Center(
            child: Container(
              width: MediaQuery.widthOf(context) * 0.85,
              height: MediaQuery.heightOf(context) * 0.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colorpalatte.ojtworkingColor, Colorpalatte.primary],
                ),
              ),

              // ── 🔎 Scanning point ───────────────────────────
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
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
                          painter: _ScannerOverlayPainter(
                            scanWindow: scanWindow,
                            borderColor: Colorpalatte.accent,
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
                fontSize: 18,
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
                          ? Colorpalatte.accent
                          : Colorpalatte.mutedtextColor,
                      iconSize: 30,
                      backgroundColor: Colorpalatte.containerColor,
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
                  iconColor: Colorpalatte.mutedtextColor,
                  iconSize: 30,
                  backgroundColor: Colorpalatte.containerColor,
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
                backgroundColor: Colorpalatte.primary,
                foregroundColor: Colorpalatte.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────────
  // ── 📦 Widgets builder ──────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────────────
  Future<void> _bottomSheet(String rawValue) {
    final data = _parseQrData(rawValue);

    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return SizedBox(
          height: 400,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  'Scanned QR Code',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                _dataRow('Section', data['section']!),
                _dataRow('School Year', data['schoolYear']!),
                _dataRow('Student ID', data['studentId']!),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _isProcessing = false;
      if (widget.isActive) {
        controller.start();
      }
    });
  }

  Widget _dataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colorpalatte.mutedtextColor)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── 🎨 Overlay painter: dims outside the box, draws corner brackets ───────────
class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color borderColor;

  _ScannerOverlayPainter({required this.scanWindow, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Dim everything outside the scan window
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      );
    final dimPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(
      dimPath,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Corner brackets
    const cornerLength = 28.0;
    const strokeWidth = 5.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final r = scanWindow;

    // top-left
    canvas.drawLine(
      r.topLeft,
      r.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      r.topLeft,
      r.topLeft + const Offset(0, cornerLength),
      cornerPaint,
    );
    // top-right
    canvas.drawLine(
      r.topRight,
      r.topRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      r.topRight,
      r.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );
    // bottom-left
    canvas.drawLine(
      r.bottomLeft,
      r.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      r.bottomLeft,
      r.bottomLeft + const Offset(0, -cornerLength),
      cornerPaint,
    );
    // bottom-right
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight + const Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow ||
        oldDelegate.borderColor != borderColor;
  }
}
