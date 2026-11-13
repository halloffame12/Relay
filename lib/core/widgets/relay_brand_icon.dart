import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// The official Relay brand mark.
///
/// Every in-app surface uses this widget so headers, empty states, transfer
/// panels and About screens show exactly the same artwork as the launcher icon.
/// The asset is derived from `store/brand/relay-icon.png` by
/// `tool/generate_brand_assets.py`.
class RelayBrandIcon extends StatelessWidget {
  const RelayBrandIcon({
    super.key,
    this.size = 40,
    this.borderRadius = AppRadii.md,
    this.semanticLabel = 'Relay',
  });

  final double size;
  final double borderRadius;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/brand/relay-icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
