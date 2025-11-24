import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:soundsliced_tween_animation_builder/soundsliced_tween_animation_builder.dart';
import 'package:states_rebuilder_extended/states_rebuilder_extended.dart';

/// A widget that adds a glowing effect around its child.
class Glow2 extends StatefulWidget {
  /// Creates an [Glow2] widget.
  const Glow2({
    Key? key,
    required this.child,
    this.glowCount = 2,
    this.glowColor = Colors.white,
    this.glowShape = BoxShape.circle,
    this.glowBorderRadius,
    this.duration = const Duration(milliseconds: 3500),
    this.startDelay,
    this.animate = true,
    this.repeat = true,
    this.curve = Curves.fastOutSlowIn,
    this.glowRadiusFactor = 0.7,
  })  : assert(
          glowShape != BoxShape.circle || glowBorderRadius == null,
          'Cannot specify a border radius if the shape is a circle.',
        ),
        super(key: key);

  /// The child widget to display inside the glowing effect.
  final Widget child;

  /// The number of glowing effects to show around the child.
  final int glowCount;

  /// The color of the glow effect.
  final Color glowColor;

  /// The shape of the glow effect.
  final BoxShape glowShape;

  /// The border radius for the glow effect.
  final BorderRadius? glowBorderRadius;

  /// The duration of the glowing animation.
  final Duration duration;

  /// The delay before starting the glowing animation.
  final Duration? startDelay;

  /// Whether to animate the glowing effect.
  final bool animate;

  /// Whether to repeat the glowing animation.
  final bool repeat;

  /// The curve for the glowing animation.
  final Curve curve;

  /// The factor that determines the size of each glow effect relative to the original size.
  final double glowRadiusFactor;

  @override
  State<Glow2> createState() => _Glow2State();
}

class _Glow2State extends State<Glow2> {
  bool _isDelayComplete = false;
  final _animationKey = 1.inject<int>();

  @override
  void initState() {
    super.initState();
    _handleStartDelay();
  }

  @override
  void didUpdateWidget(covariant Glow2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) {
      return;
    }
    // If animate state changes, handle the delay again
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        setState(() {
          _isDelayComplete = false;
          _animationKey.update<int>((s) => s + 1);
        });
        _handleStartDelay();
      } else {
        setState(() {
          _isDelayComplete = false;
        });
      }
    }

    // If duration or repeat changes, restart animation
    if (widget.duration != oldWidget.duration ||
        widget.repeat != oldWidget.repeat) {
      if (!mounted) {
        return;
      }
      _animationKey.update<int>((s) => s + 1);
    }
  }

  void _handleStartDelay() async {
    final startDelay = widget.startDelay;
    if (startDelay != null) {
      await Future.delayed(startDelay);
    }

    if (mounted && widget.animate) {
      setState(() {
        _isDelayComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate || !_isDelayComplete) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: _Glow2Painter(
            progress: 0.0,
            curve: widget.curve,
            glowCount: widget.glowCount,
            glowDecoration: BoxDecoration(
              color: widget.glowColor,
              shape: widget.glowShape,
              borderRadius: widget.glowBorderRadius,
            ),
            glowRadiusFactor: widget.glowRadiusFactor,
          ),
          child: widget.child,
        ),
      );
    }

    return _animationKey.builderData<int>(
      (k) => _TheGlow2(
        animationKey: k,
        glowCount: widget.glowCount,
        glowColor: widget.glowColor,
        glowShape: widget.glowShape,
        glowBorderRadius: widget.glowBorderRadius,
        duration: widget.duration,
        repeat: widget.repeat,
        curve: widget.curve,
        glowRadiusFactor: widget.glowRadiusFactor,
        child: widget.child,
        onEndCallback: () {
          if (widget.repeat && mounted) {
            _animationKey.update<int>((s) => s + 1);
          }
        },
      ),
    );
  }
}

class _TheGlow2 extends StatelessWidget {
  final int animationKey;
  final int glowCount;
  final Color glowColor;
  final BoxShape glowShape;
  final BorderRadius? glowBorderRadius;
  final Duration duration;
  final bool repeat;
  final Curve curve;
  final double glowRadiusFactor;
  final Widget child;
  final Function()? onEndCallback;

  const _TheGlow2({
    required this.animationKey,
    this.glowCount = 2,
    this.glowColor = Colors.white,
    this.glowShape = BoxShape.circle,
    this.glowBorderRadius,
    this.duration = const Duration(seconds: 2),
    this.repeat = true,
    this.curve = Curves.fastOutSlowIn,
    this.glowRadiusFactor = 0.7,
    required this.child,
    this.onEndCallback,
  });

  @override
  Widget build(BuildContext context) {
    return STweenAnimationBuilder<double>(
      animationKey: animationKey,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      onEnd: repeat ? onEndCallback : null,
      builder: (context, progress, child) {
        return RepaintBoundary(
          child: CustomPaint(
            painter: _Glow2Painter(
              progress: progress,
              curve: curve,
              glowCount: glowCount,
              glowDecoration: BoxDecoration(
                color: glowColor,
                shape: glowShape,
                borderRadius: glowBorderRadius,
              ),
              glowRadiusFactor: glowRadiusFactor,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Glow2Painter extends CustomPainter {
  _Glow2Painter({
    required this.progress,
    required this.curve,
    required this.glowCount,
    required this.glowDecoration,
    required this.glowRadiusFactor,
  });

  final double progress;
  final Curve curve;
  final int glowCount;
  final BoxDecoration glowDecoration;
  final double glowRadiusFactor;

  // We cache the path so that we don't have to recreate it
  // every time we paint.
  final Path _glowPath = Path();

  static final Tween<double> _opacityTween = Tween<double>(begin: 0.3, end: 0);

  @override
  void paint(Canvas canvas, Size size) {
    final glowColor = glowDecoration.color!;
    final opacity = _opacityTween.transform(progress);

    final paint = Paint()
      ..color = glowColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final glowSize = math.min(size.width, size.height);
    final glowRadius = glowSize / 2;

    final currentProgress = curve.transform(progress);

    // Cache the path and reuse it for each glow.
    _glowPath.reset();

    // We need to draw the glows from the smallest to the largest.
    for (int i = 1; i <= glowCount; i++) {
      final currentRadius =
          glowRadius + glowRadius * glowRadiusFactor * i * currentProgress;

      final currentRect = Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: currentRadius,
      );

      _addGlowPath(currentRect);
      canvas.drawPath(_glowPath, paint);
    }
  }

  void _addGlowPath(Rect glowRect) {
    _glowPath.addPath(
      glowDecoration.getClipPath(
        glowRect,
        TextDirection.ltr,
      ),
      Offset.zero,
    );
  }

  @override
  bool shouldRepaint(covariant _Glow2Painter oldDelegate) {
    return progress != oldDelegate.progress ||
        curve != oldDelegate.curve ||
        glowCount != oldDelegate.glowCount ||
        glowDecoration != oldDelegate.glowDecoration ||
        glowRadiusFactor != oldDelegate.glowRadiusFactor;
  }
}
