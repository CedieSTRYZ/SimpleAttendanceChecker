import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/colorpalatte.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppbar({super.key});

  // ── 📱 UI builder ───────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.0),
      width: double.infinity,
      height: MediaQuery.heightOf(context) * 0.08,
      decoration: BoxDecoration(color: Colorpalatte.white),
      child: Row(
        spacing: 10,
        children: [
          // ── 🖼️ Appbar logo ───────────────────────────
          Container(
            width: MediaQuery.widthOf(context) * 0.11,
            height: MediaQuery.heightOf(context) * 0.11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colorpalatte.primary, width: 2),
            ),
            child: ClipOval(
              child: Image(
                image: AssetImage('lib/assets/logo.png'),
                fit: BoxFit.scaleDown,
              ),
            ),
          ),

          // ── 📜 Welcome text ───────────────────────────
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to',
                  style: TextStyle(
                    fontFamily: 'K2D',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Attendance Checker',
                  style: TextStyle(
                    fontFamily: 'K2D',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ── ⚙️ Setting button ───────────────────────────
          Container(
            width: MediaQuery.widthOf(context) * 0.09,
            height: MediaQuery.heightOf(context) * 0.04,
            decoration: BoxDecoration(
              color: Colorpalatte.containerColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.12),
                  blurRadius: 2,
                  spreadRadius: 0,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.12),
                  blurRadius: 2,
                  spreadRadius: 0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {},
              alignment: Alignment.center,
              icon: Icon(Icons.settings_rounded),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90);
}
