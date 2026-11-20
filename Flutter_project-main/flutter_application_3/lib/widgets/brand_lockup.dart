import 'package:flutter/material.dart';

import '../theme/koltsevaya_theme.dart';

class BrandLockup extends StatelessWidget {
  final bool compact;

  const BrandLockup({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: KoltsevayaColors.text,
      fontSize: compact ? 13 : 17,
      fontWeight: FontWeight.w800,
      letterSpacing: compact ? 1.2 : 1.7,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            border: Border.all(color: KoltsevayaColors.orange),
            borderRadius: BorderRadius.circular(9),
            color: KoltsevayaColors.orange.withValues(alpha: .1),
          ),
          child: Icon(
            Icons.train_outlined,
            size: compact ? 19 : 23,
            color: KoltsevayaColors.amber,
          ),
        ),
        const SizedBox(width: 11),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KOLTSEVAYA LINE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              const SizedBox(height: 3),
              Text(
                'Línea circular / Archivo subterráneo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: KoltsevayaColors.muted,
                  fontSize: compact ? 10 : 11,
                  letterSpacing: .25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
