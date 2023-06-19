import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:web_game/util/util.dart';

class LoadingBorder extends InputBorder {
  static const _TAG = 'LoadingBorder';
  final Color _dark;
  final ValueNotifier<double> listenable;

  const LoadingBorder(this.listenable, this._dark, {super.borderSide});

  @override
  InputBorder copyWith({BorderSide? borderSide}) {
    return LoadingBorder(listenable, _dark, borderSide: borderSide ?? this.borderSide);
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(bottom: borderSide.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(Rect.fromLTWH(rect.left, rect.top, rect.width, math.max(0.0, rect.height - borderSide.width)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(const BorderRadius.all(Radius.circular(4)).toRRect(rect));
  }

  @override
  bool get isOutline => false;

  @override
  paint(Canvas canvas, Rect rect,
      {double? gapStart, double gapExtent = 0.0, double gapPercentage = 0.0, TextDirection? textDirection}) {
    final bottomRight = rect.bottomRight;
    final bottomLeft = rect.bottomLeft;
    final pLight = borderSide.toPaint();
    canvas.drawLine(bottomLeft, bottomRight, pLight);
    final len = bottomRight.dx / 3;
    final pDark = Paint()
      ..color = _dark
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final step = bottomRight.dx / 100;
    if (listenable.value == -1) return;
    _anim(pLight, pDark, canvas, len, step, bottomRight, bottomLeft, listenable.value + bottomLeft.dx);
    Future.delayed(
        const Duration(milliseconds: 160),
        () => listenable.value == -1
            ? null
            : listenable.value = listenable.value - len > bottomRight.dx ? listenable.value = 0 : listenable.value + step);
  }

  @override
  ShapeBorder scale(double t) => LoadingBorder(listenable, _dark, borderSide: borderSide.scale(t));

  void _anim(
      Paint pLight, Paint pDark, Canvas canvas, double len, double step, Offset bottomRight, Offset bottomLeft, double x) {
    if (x - bottomLeft.dx <= len) {
      canvas.drawLine(bottomLeft, bottomLeft.translate(x, 0), pDark);
    } else if (x <= bottomRight.dx) {
      final start = x - len;
      canvas.drawLine(bottomLeft.translate(start, 0), bottomLeft.translate(start + len, 0), pDark);
    } else if (x - len <= bottomRight.dx) {
      canvas.drawLine(bottomLeft.translate(x - len, 0), bottomRight, pDark);
    }
  }
}
