import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

class RelayContent extends StatelessWidget {
  const RelayContent({
    super.key,
    required this.child,
    this.maxWidth = 920,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = AppSizes.screenMargin(width);
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: margin),
          child: child,
        ),
      ),
    );
  }
}

class RelayDivider extends StatelessWidget {
  const RelayDivider({super.key, this.indent = 0, this.endIndent = 0});

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(indent: indent, endIndent: endIndent);
  }
}
