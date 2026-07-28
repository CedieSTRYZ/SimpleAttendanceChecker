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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            color: Colorpalatte.errorColor,
          ),
          Container(
            width: 100,
            height: 100,
            color: Colorpalatte.primary,
          )
        ],
      ),
    );
  }
}