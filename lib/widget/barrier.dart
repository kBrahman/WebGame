import 'package:flutter/material.dart';

class Barrier extends StatelessWidget {
  final double _h;
  final double _w;
  final Alignment _alignment;

  const Barrier(this._h, this._w, this._alignment, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: _alignment, children: [
      Container(
          width: _w,
          height: _h,
          decoration: BoxDecoration(
              color: Colors.green,
              border: Border.all(width: 9, color: Colors.green[800]!),
              borderRadius: BorderRadius.circular(10))),
      Container(
          width: _w,
          height: _h < 9 ? 0 : 9,
          decoration: BoxDecoration(
              color: Colors.green,
              border: Border(
                  right: BorderSide(width: 9, color: Colors.green[800]!),
                  left: BorderSide(width: 9, color: Colors.green[800]!))))
    ]);
  }
}
