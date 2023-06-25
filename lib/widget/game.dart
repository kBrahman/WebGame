// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_game/bloc/leader_bloc.dart';
import 'package:web_game/widget/barrier.dart';

import '../util/util.dart';
import 'leaderboard.dart';

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<StatefulWidget> createState() => _GameState();
}

class _GameState extends State<Game> {
  static const _TAG = '_GameState';
  final _v = 2.6;
  var _y = .0;
  var _t = .0;
  var _y0 = .0;
  var started = false;
  var gameOver = false;
  var _score = 0;
  var _best = 0;
  var _passed = false;
  late double _barrierXInitial;
  double? _barrieX;
  late double _ballSpace;
  late double _ballSide;
  late double _barrierWidth;
  late double _maxH;
  late double _maxW;
  double? _bottomBarrierH;
  double? _topBarrierHeight;
  int? _rank;
  final rnd = Random();
  InterstitialAd? _ad;
  DateTime? _nxtAdShowTime;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SharedPreferences.getInstance().then((sp) {
      setState(() => _best = sp.getInt(SCORE_BEST) ?? 0);
      Firebase.initializeApp().whenComplete(() => _getRank(sp));
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: gameOver
          ? null
          : started
              ? _jump
              : () => _start(_getDelta(MediaQuery.of(context).size.width)),
      child: Column(children: [
        Expanded(
            flex: 4,
            child: LayoutBuilder(builder: (ctx, cnsts) {
              _maxH = cnsts.maxHeight;
              _maxW = cnsts.maxWidth;
              _ballSide = _getBallSide(_maxW);
              _ballSpace = _getBallSpace(_maxW);
              _barrierWidth = _getBarrierWidth(_maxW);
              // appLog(_TAG, 'max w:$_maxW, max h:$_maxH, top h:$_topBarrierHeight, bottom h:$_bottomBarrierH');

              return Stack(children: [
                AnimatedContainer(
                    color: Colors.blue,
                    alignment: Alignment(0, _y),
                    duration: const Duration(milliseconds: 0),
                    child: Image.asset('assets/ball.png', height: _ballSide, width: _ballSide)),
                AnimatedContainer(
                    duration: const Duration(milliseconds: 0),
                    alignment: Alignment(_barrieX ?? 2, 1),
                    child: Barrier(_bottomBarrierH ?? 0, _barrierWidth, Alignment.bottomCenter)),
                AnimatedContainer(
                    duration: const Duration(milliseconds: 0),
                    alignment: Alignment(_barrieX ?? 2, -1),
                    child: Barrier(_topBarrierHeight ?? 0, _barrierWidth, Alignment.topCenter)),
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
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                      onPressed: started
                          ? _jump
                          : () => SharedPreferences.getInstance().then((sp) async {
                                await _showLeaderBoard(context, sp);
                                _getRank(sp);
                              }),
                      icon: const Icon(Icons.leaderboard)),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SCORE:$_score', style: const TextStyle(fontSize: 25)),
                        Text('BEST:$_best', style: const TextStyle(fontSize: 25)),
                        if (_rank != null) Text('# $_rank', style: const TextStyle(fontSize: 20))
                      ])
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
        _barrieX = _barrierXInitial;
        _generateHeights();
        _score = 0;
      });

  void _start(delta) {
    const deltaTime = 30;
    _barrierXInitial = _getBarrXInit(_maxW);
    _barrieX = _barrierXInitial;
    _bottomBarrierH = rnd.nextDouble() * (_maxH - _ballSpace);
    _topBarrierHeight = _maxH - _ballSpace - _bottomBarrierH!;
    appLog(_TAG, 'start: barrx:$_barrieX, bx init:$_barrierXInitial, bar w:$_barrierWidth');
    Timer.periodic(const Duration(milliseconds: deltaTime), (timer) {
      _t += deltaTime / 1000;
      setState(() {
        _y = _y0 - _v * _t + 9.8 * _t * _t / 2;
        _barrieX = _barrieX! - delta;
      });
      if (_y > 1 || _hit()) {
        _showAd();
        timer.cancel();
        started = false;
        setState(() {
          gameOver = true;
        });
        if (_score > _best) {
          _best = _score;
          SharedPreferences.getInstance().then((sp) {
            sp.setInt(SCORE_BEST, _best);
            final id = sp.getString(ID);
            if (id == null) return;
            FirebaseFirestore.instance.doc('$COLLECTION_LEADERBOARD/$id').update({SCORE_BEST: _best});
            _getRank(sp);
          });
        }
      } else if (_barrieX! < -_barrierXInitial) {
        _barrieX = _barrierXInitial;
        _passed = false;
        _generateHeights();
      } else if (_barrieX! < -_barrierWidth / _maxW && !_passed) {
        _score++;
        _passed = true;
      }
    });
    started = true;
    _updateTime();
    _prepareAd();
  }

  void _generateHeights() {
    _bottomBarrierH = rnd.nextDouble() * (_maxH - _ballSpace);
    _topBarrierHeight = _maxH - _ballSpace - _bottomBarrierH!;
  }

  bool _hit() => _barrieX! >= -_ballSide / _maxW && _barrieX! <= _ballSide / _maxW && !_inBallSpace();

  bool _inBallSpace() {
    final barrTop = _topBarrierHeight! * 2 / (_maxH - _ballSide) - 1;
    final barrBottom = (_topBarrierHeight! + _ballSpace) * 2 / (_maxH - _ballSide) - 1;
    return _y >= barrTop && _y + _ballSide * 2 / _maxH <= barrBottom;
  }

  _showLeaderBoard(BuildContext context, SharedPreferences sp) => showDialog(
      context: context,
      builder: (ctx) => Dialog(
              child: Leaderboard(LeaderBloc(sp.getString(ID), (score) {
            setState(() => _best = score);
            sp.setInt(SCORE_BEST, _best);
          }))));

  void _getRank(SharedPreferences sp) {
    final id = sp.getString(ID);
    if (id == null) return;
    FirebaseFirestore.instance
        .collection(COLLECTION_LEADERBOARD)
        .where(SCORE_BEST, isGreaterThanOrEqualTo: _best)
        .get()
        .then((docs) => docs.docs.map((e) => e[SCORE_BEST]).toSet().length)
        .then((rank) => setState(() => _rank = rank));
  }

  void _updateTime() => SharedPreferences.getInstance().then((sp) {
        final id = sp.getString(ID);
        if (id == null) return;
        final t = sp.getInt(TIME_LAST_CHECK) ?? 0;
        final now = Timestamp.now();
        final millis = now.millisecondsSinceEpoch;
        if (millis > t + Duration.millisecondsPerDay) {
          FirebaseFirestore.instance.doc('$COLLECTION_LEADERBOARD/$id').update({TIME: now});
          sp.setInt(TIME_LAST_CHECK, millis);
        }
      });

  _getDelta(double screenWidth) {
    return .05;
    const a = -0.000039432176656;
    const b = 0.06537854889584;
    final d = a * screenWidth + b;
    appLog(_TAG, 'delta:$d');
    return d;
  }

  double _getBallSide(double w) => 0.07097791798107256 * w + 17.32868771706356;

  double _getBallSpace(double w) => 0.28391167192429 * w + 69.274447949526814;

  double _getBarrierWidth(double w) => 0.157728706624606 * w + 38.485804416403785;

  double _getBarrXInit(double w) => 1.984542586750789 - 0.000473186119874 * w;

  void _prepareAd() {
    if (_ad != null || _rank != null && _rank! < 4) return;
    _nxtAdShowTime = DateTime.now().add(const Duration(seconds: 57));
    InterstitialAd.load(
        adUnitId: ID_INTERSTITIAL,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
          appLog(_TAG, 'ad loaded');
          _ad = ad;
        }, onAdFailedToLoad: (err) {
          appLog(_TAG, 'ad failed to load:$err');
          _prepareAd();
        }));
  }

  void _showAd() {
    appLog(_TAG, 'show ad');
    if ((_rank ?? 4) > 3 && (_nxtAdShowTime?.isBefore(DateTime.now()) ?? true)) {
      _ad?.fullScreenContentCallback = FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _prepareAd();
      });
      _ad?.setImmersiveMode(true);
      _ad?.show();
      appLog(_TAG, 'should show ad');
    }
  }
}
