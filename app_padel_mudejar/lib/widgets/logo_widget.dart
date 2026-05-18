import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  const LogoWidget({super.key, this.size = 130});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logoclean.png',
      width: size,
      height: size,
    );
  }
}