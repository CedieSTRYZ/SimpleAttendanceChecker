import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/colorpalatte.dart';
import 'package:simpleattendancechecker/screen/dashboard/pages/dashboard.dart';
import 'package:simpleattendancechecker/screen/recordlist/pages/record_list.dart';
import 'package:simpleattendancechecker/screen/scanner/pages/scanner.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // ── 🛠️ Functions ───────────────────────────
  int _selectedIndex = 1;

  final List<Widget> _pages = [Scanner(), Dashboard(), RecordList()];

  // ── 🖼️ Builder UI ───────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colorpalatte.white,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colorpalatte.white,
        color: Colorpalatte.primary,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          Icon(Icons.qr_code_scanner_rounded, color: Colorpalatte.white, size: 30),
          Icon(Icons.home_rounded, color: Colorpalatte.white, size: 30),
          Icon(Icons.list_alt_rounded, color: Colorpalatte.white, size: 30),
        ],
      ),
    );
  }
}
