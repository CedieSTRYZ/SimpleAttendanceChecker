import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/screen/dashboard/pages/dashboard.dart';
import 'package:simpleattendancechecker/screen/recordlist/pages/record_list.dart';
import 'package:simpleattendancechecker/screen/scanner/pages/scanner.dart';
import 'package:simpleattendancechecker/widget/custom_appbar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // ── 🛠️ Global functions ───────────────────────────
  int _selectedIndex = 1;

  // ── 📱 Builder UI ───────────────────────────
  @override
  Widget build(BuildContext context) {
    // ── 🛠️ Local functions ───────────────────────────
    final List<Widget> pages = [
      Scanner(isActive: _selectedIndex == 0),
      Dashboard(),
      RecordList(),
    ];

    // ── 🏗️ Main structure ───────────────────────────
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colorpalatte.maincolor,
        appBar: CustomAppbar(),
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: CurvedNavigationBar(
          index: _selectedIndex,
          backgroundColor: Colorpalatte.maincolor,
          color: Colorpalatte.secondary,
          animationDuration: Duration(milliseconds: 400),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            Icon(
              Icons.qr_code_scanner_rounded,
              color: Colorpalatte.maincolor,
              size: 30,
            ),
            Icon(Icons.home_rounded, color: Colorpalatte.maincolor, size: 30),
            Icon(Icons.list_alt_rounded, color: Colorpalatte.maincolor, size: 30),
          ],
        ),
      ),
    );
  }
}
