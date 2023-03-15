// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_game/widget/barrier.dart';

import '../util.dart';

class FlappyBallPlug extends StatefulWidget {
  const FlappyBallPlug({super.key});

  @override
  State<StatefulWidget> createState() => _PlugState();
}

class _PlugState extends State<FlappyBallPlug> {
  static const _TAG = '_PlugState';
  static const BEST_SCORE = 'best_score';
  final _v = 2.6;
  var _y = .0;
  var _t = .0;
  var _y0 = .0;
  var started = false;
  var gameOver = false;
  var _score = 0;
  var _best = 0;
  var _passed = false;
  var _barrieX = 1.8;
  final _ballSpace = 180;
  final _ballSide = 45.0;
  final _barrierWidth = 100.0;
  late double _maxH;
  late double _maxW;
  double? _bottomBarrierH;
  double? _topBarrierHeight;
  final rnd = Random();

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SharedPreferences.getInstance().then((sp) => setState(() => _best = sp.getInt(BEST_SCORE) ?? 0));
    super.initState();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: gameOver
          ? null
          : started
              ? _jump
              : _start,
      child: Column(children: [
        Expanded(
            flex: 4,
            child: LayoutBuilder(builder: (ctx, cnsts) {
              _maxH = cnsts.maxHeight;
              _maxW = cnsts.maxWidth;
              _bottomBarrierH ??= rnd.nextDouble() * (_maxH - _ballSpace);
              _topBarrierHeight ??= _maxH - _ballSpace - _bottomBarrierH!;
              final borderSide = BorderSide(color: Colors.green[800]!, width: 12);
              return Stack(children: [
                AnimatedContainer(
                    color: Colors.blue,
                    alignment: Alignment(0, _y),
                    duration: const Duration(milliseconds: 0),
                    child: Image.asset('assets/ball.png', height: _ballSide, width: _ballSide)),
                AnimatedContainer(
                    duration: const Duration(milliseconds: 0),
                    alignment: Alignment(_barrieX, 1),
                    child: Barrier(_bottomBarrierH!, _barrierWidth)),
                AnimatedContainer(
                    duration: const Duration(milliseconds: 0),
                    alignment: Alignment(_barrieX, -1),
                    child: Barrier(_topBarrierHeight!, _barrierWidth)),
                if (gameOver)
                  Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text(textAlign: TextAlign.center, 'GAME OVER', style: TextStyle(color: Colors.red, fontSize: 50)),
                    IconButton(iconSize: 50, onPressed: _init, icon: const Icon(Icons.replay, color: Colors.white))
                  ]))
              ]);
            })),
        Expanded(
            child: Container(
                color: Colors.green,
                alignment: Alignment.center,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('SCORE:$_score', style: const TextStyle(fontSize: 25)),
                  Text('BEST:$_best', style: const TextStyle(fontSize: 25))
                ])))
      ]));

  void _jump() {
    _t = 0;
    _y0 = _y;
  }

  _init() => setState(() {
        _t = 0;
        _y = 0;
        _y0 = 0;
        gameOver = false;
        _barrieX = 1.8;
        _generateHeights();
        _score = 0;
      });

  void _start() {
    started = true;
    Timer.periodic(const Duration(milliseconds: 45), (timer) {
      _t += .045;
      setState(() {
        _y = _y0 - _v * _t + 9.8 * _t * _t / 2;
        _barrieX -= .05;
      });
      if (_y > 1 || _hit()) {
        timer.cancel();
        started = false;
        setState(() {
          gameOver = true;
        });
        if (_score > _best) _best = _score;
        SharedPreferences.getInstance().then((sp) => sp.setInt(BEST_SCORE, _best));
      } else if (_barrieX < -1.8) {
        _barrieX = 1.8;
        _passed = false;
        _generateHeights();
      } else if (_barrieX < -_barrierWidth / _maxW && !_passed) {
        _score++;
        _passed = true;
      }
    });
  }

  void _generateHeights() {
    _bottomBarrierH = rnd.nextDouble() * (_maxH - _ballSpace);
    _topBarrierHeight = _maxH - _ballSpace - _bottomBarrierH!;
  }

  bool _hit() => _barrieX >= -_ballSide / _maxW && _barrieX <= _ballSide / _maxW && !_inBallSpace();

  bool _inBallSpace() {
    final barrTop = _topBarrierHeight! * 2 / (_maxH - _ballSide) - 1;
    final barrBottom = (_topBarrierHeight! + _ballSpace) * 2 / (_maxH - _ballSide) - 1;
    appLog(_TAG, 'newY:$_y, barrTop:$barrTop, barrBottom:$barrBottom, max height:$_maxH');
    return _y >= barrTop && _y + _ballSide * 2 / _maxH <= barrBottom;
  }
}
