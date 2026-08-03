import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/services/biometric_service.dart';

class CustomAppbar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppbar({super.key});

  @override
  State<CustomAppbar> createState() => _CustomAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(90);
}

class _CustomAppbarState extends State<CustomAppbar> {
  bool _fingerprintEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final enabled = await BiometricService.isEnabled();
    if (mounted) setState(() => _fingerprintEnabled = enabled);
  }

  Future<void> _toggleFingerprint() async {
    if (!_fingerprintEnabled) {
      final supported = await BiometricService.isDeviceSupported();
      if (!supported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Walang biometric na naka-set up sa device na ito.'),
            ),
          );
        }
        return;
      }
    }
    final newValue = !_fingerprintEnabled;
    await BiometricService.setEnabled(newValue);
    if (mounted) setState(() => _fingerprintEnabled = newValue);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        width: double.infinity,
        height: MediaQuery.heightOf(context) * 0.08,
        decoration: BoxDecoration(color: Colorpalatte.maincolor),
        child: Row(
          spacing: 10,
          children: [
            Container(
              width: MediaQuery.widthOf(context) * 0.11,
              height: MediaQuery.heightOf(context) * 0.11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colorpalatte.secondary, width: 2),
              ),
              child: ClipOval(
                child: Image(
                  image: AssetImage('lib/assets/logo.png'),
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to',
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'Attendance Checker',
                    style: TextStyle(
                      fontFamily: 'K2D',
                      fontSize: AppFontSize.subtitle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: MediaQuery.widthOf(context) * 0.09,
              height: MediaQuery.heightOf(context) * 0.04,
              decoration: BoxDecoration(
                color: Colorpalatte.containercolor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.12),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: PopupMenuButton<void>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.settings_rounded),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: _toggleFingerprint,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enable Fingerprint'),
                        Icon(
                          _fingerprintEnabled
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: Colorpalatte.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}