// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:developer';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_game/bloc/base_bloc.dart';
import 'package:web_game/model/event.dart';
import 'package:web_game/model/user.dart';

import '../model/leader_data.dart';
import '../util/util.dart';

class LeaderBloc extends BaseBloc<LeaderData, Event> {
  static const _TAG = 'LeaderBloc';
  final listenable = ValueNotifier(-1.0);
  final txtNameCtr = TextEditingController();
  final Function(int) updateBestScoreUI;

  LeaderBloc(String? id, this.updateBestScoreUI) {
    stream = _getStream(id);
  }

  Stream<LeaderData> _getStream(String? id) async* {
    final sp = await SharedPreferences.getInstance();
    // await sp.reload();
    var data = const LeaderData();
    final flag = sp.getString(FLAG);
    appLog(_TAG, 'id:$id, flag:$flag');
    if (id == null)
      yield data = data.copyWith(state: UIState.SET_NAME, flag: flag);
    else {
      try {
        await FirebaseFirestore.instance.doc('$COLLECTION_LEADERBOARD/$id').update({SCORE_BEST: sp.getInt(SCORE_BEST) ?? 0});
        yield data = await _getResult(data, sp.getString(NAME)!, id, flag);
      } catch (e) {
        appLog(_TAG, 'err:$e');
      }
    }
    await for (final e in ctr.stream) {
      final cmd = e.cmd;
      appLog(_TAG, 'cmd:$cmd');
      switch (cmd) {
        case Cmd.UPDATE:
          yield data = data.copyWith(updating: true);
          data = await _getResult(data, sp.getString(NAME)!, sp.getString(ID)!, flag);
          yield data = data.copyWith(updating: false);
          break;
        case Cmd.FLAG:
          final flag = e.flag;
          sp.setString(FLAG, flag!);
          yield data = data.copyWith(flag: flag);
          break;
        case Cmd.NEXT:
          final name = txtNameCtr.text;
          if (name.isNotEmpty) {
            listenable.value = 0;
            if (!(await inetOK())) {
              yield data = data.copyWith(networkErr: true);
              listenable.value = -1;
              break;
            } else
              yield data = data.copyWith(networkErr: false);
            String? id;
            try {
              id = await _googleSignIn();
            } catch (e) {
              appLog(_TAG, e);
              yield data = data.copyWith(signInErr: true);
            }
            if (id == null) {
              listenable.value = -1;
              break;
            }
            try {
              await _register(sp.getInt(SCORE_BEST) ?? 0, name, id, flag ?? '', sp.getString(COUNTRY), sp);
              yield data = await _getResult(data, name, id, flag);
            } catch (e) {
              appLog(_TAG, 'exc err:$e');
              yield data = data.copyWith(networkErr: false);
              listenable.value = -1;
            }
          }
      }
    }
  }

  Future<String?> _googleSignIn() async {
    appLog(_TAG, '_signIn');
    GoogleSignIn googleSignIn = GoogleSignIn(scopes: <String>['email']);
    var id = googleSignIn.currentUser?.email;
    if (id == null && (id = (await googleSignIn.signInSilently())?.email) == null) id = (await googleSignIn.signIn())?.email;
    return id;
  }

  final Random _random = Random();

  String _getRandomName() {
    final len = _random.nextInt(4) + 3;
    return _generateRandomString(len);
  }

  String _generateRandomString(int len) {
    final r = Random();
    String randomString = String.fromCharCodes(List.generate(len, (index) => r.nextInt(33) + 89));
    return randomString;
  }

  List<User> _getTestLeaderList(name, id) => List.generate(
      1000,
      (index) => index == 222
          ? User(name, 994, '🇦🇸', id, 'American samoa')
          : User(_getRandomName(), _random.nextInt(1000), '🇦🇲', 'id', 'Armenia'))
    ..sort((u1, u2) => -(u1.score).compareTo(u2.score));

  List<int> _getMin(List<User> list) {
    final max = list.first.score;
    var silver = -1;
    for (final score in list.map((e) => e.score))
      if (score < max && silver == -1)
        silver = score;
      else if (score < silver) return [silver, score];
    return [silver, -1];
  }

  Future<LeaderData> _getResult(LeaderData data, String name, String id, String? flag) async {
    appLog(_TAG, 'get result, name:$name');
    final leaderList = await _getLeaderList(name, id);
    appLog(_TAG, 'leader list:$leaderList');
    final silverBronze = _getMin(leaderList);
    final int silver = silverBronze.first;
    final int bronze = silverBronze.last;
    return data.copyWith(
        state: UIState.LEADER_LIST, list: leaderList, name: name, flag: flag, id: id, silver: silver, bronze: bronze);
  }

  Future<List<User>> _getLeaderList(String name, String id) async {
    appLog(_TAG, 'name:$name, id":$id');
    try {
      final docs =
          await FirebaseFirestore.instance.collection(COLLECTION_LEADERBOARD).orderBy(SCORE_BEST, descending: true).get();
      return docs.docs.map((u) => User(u[NAME], u[SCORE_BEST], u[FLAG], u.id, u[COUNTRY])).toList(growable: false);
    } catch (e) {
      appLog(_TAG, e);
    }
    return [];
  }

  _register(int score, String name, String id, String flag, String? country, SharedPreferences sp) async {
    sp
      ..setString(ID, id)
      ..setString(NAME, name);
    final doc = await FirebaseFirestore.instance.doc('$COLLECTION_LEADERBOARD/$id').get();
    if (doc.exists && doc[SCORE_BEST] > score) {
      updateBestScoreUI(doc[SCORE_BEST]);
      await FirebaseFirestore.instance.doc('$COLLECTION_LEADERBOARD/$id').update({NAME: name, FLAG: flag, COUNTRY: country});
    } else
      await FirebaseFirestore.instance
          .doc('$COLLECTION_LEADERBOARD/$id')
          .set({NAME: name, FLAG: flag, SCORE_BEST: score, COUNTRY: country});
  }
}

enum UIState { LOADING, SET_NAME, LEADER_LIST }

enum Cmd { NEXT, FLAG, UPDATE }
