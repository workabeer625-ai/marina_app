import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/marina_theme.dart';

class MarinaWordmark extends StatelessWidget {
  const MarinaWordmark({
    super.key,
    this.dark = true,
    this.compact = false,
    this.markOnly = false,
  });

  final bool dark, compact, markOnly;

  @override
  Widget build(BuildContext context) {
    final color = dark ? MarinaColors.navy : Colors.white;
    return Semantics(
      label: 'MARINA مارينا',
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              dark
                  ? 'assets/branding/marina_mark.svg'
                  : 'assets/branding/marina_mark_light.svg',
              width: compact ? 32 : 54,
              height: compact ? 32 : 54,
            ),
            if (!markOnly) ...[
              SizedBox(width: compact ? 9 : 13),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MARINA',
                    style: TextStyle(
                      fontFamily: 'Marcellus',
                      fontFamilyFallback: ['Tajawal'],
                      fontSize: compact ? 17 : 25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: compact ? 2.6 : 4.5,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  if (!compact)
                    Text(
                      'مــــارينا',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: color.withValues(alpha: .72),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
