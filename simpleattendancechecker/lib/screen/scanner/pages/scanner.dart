import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/colorpalatte.dart';

class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Scanning Attendance'),
        Container(
          width: MediaQuery.widthOf(context) * 0.9,
          height: MediaQuery.heightOf(context) * 0.3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colorpalatte.ojtworkingColor, Colorpalatte.primary],
            ),
          ),
        ),
        Text("Postion the student's QR code inside the frame"),
        Row(
          children: [
            ElevatedButton(onPressed: null, child: Text('flash')),
            ElevatedButton(onPressed: null, child: Text('restart')),
            ElevatedButton(onPressed: null, child: Text('set late')),
          ],
        ),
      ],
    );
  }
}
