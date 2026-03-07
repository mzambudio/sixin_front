import 'package:flutter/material.dart';

class SixinLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxFit fit;

  const SixinLogo({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/images/sixin_white.png'
        : 'assets/images/sixin_black.png';

    return Image.asset(logoAsset, height: height, width: width, fit: fit);
  }
}
