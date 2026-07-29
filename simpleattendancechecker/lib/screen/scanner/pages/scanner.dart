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

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null) return;
    if (_isProcessing) return;

    _isProcessing = true;
    controller.stop;

    _bottomSheet(rawValue);
  }

  // ── 🔎 Parse "06-2324-033121" into its parts ───────────────────────────
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
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 20,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scanning Attendance'),

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
                child: MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ── 🚨 Reminder text ───────────────────────────
          Center(child: Text("Postion the student's QR code inside the frame")),

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
