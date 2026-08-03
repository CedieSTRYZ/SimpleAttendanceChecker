import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';

class SearchbarCard extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final double iconSize;
  final Color iconColor;
  const SearchbarCard({
    super.key,
    required this.onChanged,
    this.hintText = 'Search by Name or Student ID',
    this.iconSize = 20,
    this.iconColor = Colorpalatte.infocolor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.12),
              blurRadius: 3,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.24),
              blurRadius: 2,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(Icons.search, size: iconSize, color: iconColor),
            filled: true,
            contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            fillColor: Colorpalatte.containercolor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
