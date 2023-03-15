import 'package:flutter/material.dart';

class Barrier extends StatelessWidget {
  final double _h;
  final double _w;

  const Barrier(this._h, this._w, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: _w,
        height: _h,
        decoration: BoxDecoration(
            color: Colors.green,
            border: Border.all(width: 9, color: Colors.green[800]!),
            borderRadius: BorderRadius.circular(10)));
  }
}
