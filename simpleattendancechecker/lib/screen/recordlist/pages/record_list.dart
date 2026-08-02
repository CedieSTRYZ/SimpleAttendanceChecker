import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';

class RecordList extends StatefulWidget {
  const RecordList({super.key});

  @override
  State<RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<RecordList> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 100, height: 100, color: Colorpalatte.sucesscolor),
            Container(
              width: 100,
              height: 100,
              color: Colorpalatte.warningcolor,
            ),
          ],
        ),
      ),
    );
  }
}
