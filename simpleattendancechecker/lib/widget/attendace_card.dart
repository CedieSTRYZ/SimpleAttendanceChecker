import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/colorpalatte.dart';

class AttendaceCard extends StatelessWidget {
  const AttendaceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      width: MediaQuery.widthOf(context) * 0.95,
      height: MediaQuery.heightOf(context) * 0.1,
      decoration: BoxDecoration(
        color: Colorpalatte.containerColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colorpalatte.presentColor,
            ),
            child: Center(child: Text('CA')),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cedie Adrigado'),
              Text('06-2324-033121')
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('9:37 am'),
              Text('PRESENT'),
            ],
          ),
        ],
      ),
    );
  }
}
