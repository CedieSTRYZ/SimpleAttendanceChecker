import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/screen/dashboard/pages/dashboard.dart';
import 'package:simpleattendancechecker/screen/scanner/pages/scanner.dart';
import 'package:simpleattendancechecker/screen/summaryreport/pages/summary_reports.dart';
import 'package:simpleattendancechecker/widget/custom_appbar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // ── 🛠️ Method functions ───────────────────────────
  int _selectedIndex = 1;

  // ── 📱 Builder UI ───────────────────────────
  @override
  Widget build(BuildContext context) {
    // ── 🛠️ Local functions ───────────────────────────
    final List<Widget> pages = [
      Scanner(isActive: _selectedIndex == 0),
      Dashboard(),
      SummaryReports(),
    ];

    // ── 🏗️ Main structure ───────────────────────────
    return Scaffold(
      backgroundColor: Colorpalatte.maincolor,
      appBar: CustomAppbar(),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
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

        // ── 🛠️ Bottom Appbar icons ───────────────────────────
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
    );
  }
}
