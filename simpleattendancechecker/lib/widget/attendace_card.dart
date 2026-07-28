import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/colorpalatte.dart';

class AttendaceCard extends StatelessWidget {
  final Color color;
  const AttendaceCard({super.key, this.color = Colorpalatte.presentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      width: MediaQuery.widthOf(context) * 0.95,
      height: MediaQuery.heightOf(context) * 0.1,
      decoration: BoxDecoration(
        color: Colorpalatte.containerColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        spacing: 10,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color,
            ),
            //TODO: Make this function call all the first letter of their name (2 letters only) {#2fc,11}
            child: Center(
              child: Text(
                'CA',
                style: TextStyle(
                  color: Colorpalatte.white,
                  fontFamily: 'K2D',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          //TODO: add function that displa all the name, id, and email of student that scanned {#271,9}
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('06-2324-033121'),
              Text('Cedie Adrigado'),
              Text('josa.adrigado.sjc@phinmaed.com'),
            ],
          ),
        ],
      ),
    );
  }
}
