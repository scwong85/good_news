import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The sunrise mark: a rising sun with rays over a green hill. Drawn in code (original artwork)
/// so it is crisp at any size, themes with light and dark, and needs no image files.
class SunriseMark extends StatelessWidget {
  const SunriseMark({super.key, this.size = 72, this.semanticLabel});
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: SunrisePainter(sun: sunColor(context), hill: scheme.primary)),
      ),
    );
  }
}

/// A little sprout, for quiet empty states ("something good will grow here").
class SproutMark extends StatelessWidget {
  const SproutMark({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: SproutPainter(leaf: Theme.of(context).colorScheme.primary, soil: sunColor(context))),
        ),
      );
}

/// The sun's amber, slightly deeper in light mode so it stays visible on cream.
Color sunColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFFB454) : const Color(0xFFF09A2C);

class SunrisePainter extends CustomPainter {
  const SunrisePainter({required this.sun, required this.hill});
  final Color sun;
  final Color hill;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(w * 0.22)));
    final horizon = h * 0.66;
    final centre = Offset(w / 2, horizon + h * 0.03); // the hill covers the sun's flat base
    final r = w * 0.22;
    final ray = Paint()
      ..color = sun
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < 6; i++) {
      final a = math.pi + i * math.pi / 6;
      final o = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(centre + o * (r + w * 0.07), centre + o * (r + w * (i.isEven ? 0.21 : 0.16)), ray);
    }
    canvas.drawArc(Rect.fromCircle(center: centre, radius: r), math.pi, math.pi, true, Paint()..color = sun);
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, horizon + h * 0.06)
      ..quadraticBezierTo(w * 0.3, horizon - h * 0.06, w * 0.55, horizon)
      ..quadraticBezierTo(w * 0.8, horizon + h * 0.06, w, horizon + h * 0.02)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = hill);
  }

  @override
  bool shouldRepaint(SunrisePainter old) => old.sun != sun || old.hill != hill;
}

class SproutPainter extends CustomPainter {
  const SproutPainter({required this.leaf, required this.soil});
  final Color leaf;
  final Color soil;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final stem = Paint()
      ..color = leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, s.height * 0.85), Offset(w * 0.5, s.height * 0.45), stem);
    final fill = Paint()..color = leaf;
    Path leafPath(bool left) {
      final dir = left ? -1.0 : 1.0;
      return Path()
        ..moveTo(w * 0.5, s.height * 0.52)
        ..quadraticBezierTo(w * (0.5 + 0.12 * dir), s.height * 0.18, w * (0.5 + 0.36 * dir), s.height * 0.26)
        ..quadraticBezierTo(w * (0.5 + 0.36 * dir), s.height * 0.5, w * 0.5, s.height * 0.52)
        ..close();
    }

    canvas.drawPath(leafPath(true), fill);
    canvas.drawPath(leafPath(false), fill);
    canvas.drawLine(Offset(w * 0.22, s.height * 0.88), Offset(w * 0.78, s.height * 0.88), Paint()
      ..color = soil
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(SproutPainter old) => old.leaf != leaf || old.soil != soil;
}

/// Gentle fade and rise on first appearance. Shows the child immediately when the system asks
/// for reduced motion.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320) + delay,
      curve: Interval(delay.inMilliseconds / (320 + delay.inMilliseconds), 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}

/// Colour and icon per topic. Topics are never shown by colour alone: the label stays.
class TopicStyle {
  const TopicStyle(this.icon, this.color);
  final IconData icon;
  final Color color;
}

TopicStyle topicStyle(String topic, Brightness b) {
  final dark = b == Brightness.dark;
  Color c(int light, int darkC) => Color(dark ? darkC : light);
  return switch (topic) {
    'environment' => TopicStyle(Icons.eco_outlined, c(0xFF1F6B3A, 0xFF8FD6A3)),
    'science' => TopicStyle(Icons.science_outlined, c(0xFF3F4FA8, 0xFFB4BEFF)),
    'health' => TopicStyle(Icons.favorite_border, c(0xFFA33A52, 0xFFFFB2C0)),
    'education' => TopicStyle(Icons.school_outlined, c(0xFF8A5A00, 0xFFFFC866)),
    'technology' => TopicStyle(Icons.lightbulb_outline, c(0xFF1C6A7A, 0xFF8ADBEC)),
    'community' => TopicStyle(Icons.diversity_3_outlined, c(0xFF8E4A1B, 0xFFFFB98A)),
    'development' => TopicStyle(Icons.trending_up, c(0xFF2F6B4F, 0xFF9AD8B8)),
    'society' => TopicStyle(Icons.groups_outlined, c(0xFF6A4A9E, 0xFFDCC1FF)),
    'culture' => TopicStyle(Icons.palette_outlined, c(0xFF9A3E7A, 0xFFFFB0DD)),
    _ => TopicStyle(Icons.auto_awesome_outlined, c(0xFF55606A, 0xFFC1CBD4)),
  };
}
