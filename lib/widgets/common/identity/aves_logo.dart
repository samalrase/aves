import 'dart:math' as math;

import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/borders.dart';
import 'package:aves/widgets/common/fx/colors.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class const AvesLogo({
  super.key,
  required final double size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget child = CustomPaint(
      size: Size(size / 1.4, size / 1.4),
      painter: AvesLogoPainter(),
    );
    if (context.select<Settings, bool>((v) => v.themeColorMode == AvesThemeColorMode.monochrome)) {
      final tint = Color.lerp(theme.colorScheme.primary, Colors.white, .5)!;
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
        child: ColorFiltered(
          colorFilter: MatrixColorFilters.greyscale,
          child: child,
        ),
      );
    }

    return Transform.flip(
      flipX: context.isRtl,
      child: CircleAvatar(
        backgroundColor: theme.dividerColor,
        radius: size / 2,
        child: CircleAvatar(
          backgroundColor: Colors.white,
          radius: size / 2 - AvesBorder.curvedBorderWidth(context),
          child: child,
        ),
      ),
    );
  }
}

class AvesLogoPainter extends CustomPainter {
  static const _colors = [
    Color(0xFFFF5A5F),
    Color(0xFFFF9F0A),
    Color(0xFFFFD60A),
    Color(0xFFA8D52F),
    Color(0xFF34C759),
    Color(0xFF32ADE6),
    Color(0xFF5E5CE6),
    Color(0xFFBF5AF2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // petals extend 32 units from the center in a 108-unit design
    final k = size.width / 2 * 0.95 / 32;
    final petal = Rect.fromCenter(center: Offset(0, -15 * k), width: 22 * k, height: 34 * k);

    for (var i = 0; i < _colors.length; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 4);
      canvas.drawOval(
        petal,
        Paint()
          ..style = PaintingStyle.fill
          ..color = _colors[i].withValues(alpha: .85),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
