/// Achievement badge shield — a [CustomPainter], not an asset.
///
/// Locked-but-visible with the criteria stated is what motivates; a
/// day-one user has earned nothing, so the default state here is grey and
/// honest, not pre-coloured. See `me_shell.dart`'s achievements section.
library;

import 'package:flutter/material.dart';

class BadgeShield extends StatefulWidget {
  final Color color;
  final IconData icon;
  final bool unlocked;

  /// Only meaningful when [unlocked] — plays the one-time earn pulse.
  /// False for a badge that was already unlocked on a previous visit, so
  /// it doesn't re-pulse every time the Me tab rebuilds.
  final bool justUnlocked;

  const BadgeShield({
    super.key,
    required this.color,
    required this.icon,
    required this.unlocked,
    this.justUnlocked = false,
  });

  @override
  State<BadgeShield> createState() => _BadgeShieldState();
}

class _BadgeShieldState extends State<BadgeShield> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.unlocked && widget.justUnlocked) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: widget.unlocked ? 1.0 : 0.6,
          child: SizedBox(
            width: 44,
            height: 56,
            child: CustomPaint(
              painter: _ShieldPainter(
                color: widget.unlocked ? widget.color : const Color(0xFFD1D5DB),
                icon: widget.unlocked ? widget.icon : Icons.lock_outline,
                iconSize: widget.unlocked ? 22 : 20,
                iconColor: widget.unlocked ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color color;
  final IconData icon;
  final double iconSize;
  final Color iconColor;

  _ShieldPainter({
    required this.color,
    required this.icon,
    required this.iconSize,
    required this.iconColor,
  });

  Path _shieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    const cornerRadius = 4.0;
    const pointRadius = 6.0;
    final sideBottom = h * 0.60;

    return Path()
      ..moveTo(cornerRadius, 0)
      ..lineTo(w - cornerRadius, 0)
      ..quadraticBezierTo(w, 0, w, cornerRadius)
      ..lineTo(w, sideBottom)
      ..quadraticBezierTo(w, sideBottom + pointRadius * 1.4, w / 2 + pointRadius, h - pointRadius)
      ..quadraticBezierTo(w / 2, h, w / 2 - pointRadius, h - pointRadius)
      ..quadraticBezierTo(0, sideBottom + pointRadius * 1.4, 0, sideBottom)
      ..lineTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shieldPath(size);
    final darker = Color.lerp(color, Colors.black, 0.22)!;

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = darker,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: iconColor,
        ),
      ),
    )..layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height * 0.42 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.icon != icon;
}
