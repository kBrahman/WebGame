// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_game/bloc/leader_bloc.dart';
import 'package:web_game/model/event.dart';
import 'package:web_game/util/ext.dart';
import 'package:web_game/util/util.dart';
import 'package:web_game/widget/loading_border.dart';

import '../model/leader_data.dart';

class Leaderboard extends SimpleDialog {
  static const _TAG = 'Leaderboard';
  final LeaderBloc _bloc;

  const Leaderboard(this._bloc, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LeaderData>(
        initialData: const LeaderData(),
        stream: _bloc.stream,
        builder: (ctx, snap) {
          final data = snap.data!;
          var state = data.state;
          final list = data.list;
          appLog(_TAG, 'data :${data.toString()}');
          if (data.networkErr)
            SchedulerBinding.instance
                .addPostFrameCallback((_) => _showSnack(ctx, 'Network error, check your Internet access'));
          else if (data.signInErr)
            SchedulerBinding.instance.addPostFrameCallback((_) => _showSnack(ctx, 'Could not sign in try again please'));

          final ctr = ScrollController();
          switch (state) {
            case UIState.LEADER_LIST:
              late int myIndex;
              var rank = 1;
              var currScore = data.list.first.score;
              return CustomScrollView(controller: ctr, slivers: [
                SliverAppBar(
                    leading: IconButton(
                        onPressed: () {
                          appLog(_TAG, 'update');
                          _bloc.ctr.add(Event(Cmd.UPDATE));
                        },
                        icon: const Icon(Icons.cached, color: Colors.black)),
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    title: const Text('LEADERBOARD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    actions: [
                      IconButton(
                          onPressed: () {
                            appLog(_TAG, 'my index:$myIndex');
                            ctr.jumpTo(28.0 * myIndex);
                          },
                          icon: const Icon(Icons.my_location_sharp, color: Colors.black))
                    ],
                    bottom: PreferredSize(
                        preferredSize: const Size(0, 30),
                        child: Column(children: [
                          Padding(
                              padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                              child: Row(children: [
                                Text(_format('#', list.length.toString().length),
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 23),
                                const Expanded(child: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold))),
                                const Text('COUNTRY',
                                    textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                const Text('SCORE', style: TextStyle(fontWeight: FontWeight.bold))
                              ])),
                          if (data.updating) const LinearProgressIndicator()
                        ]))),
                SliverList(
                    delegate: SliverChildBuilderDelegate(childCount: list.length, (ctx, i) {
                  final user = list[i];
                  final id = user.id;
                  final isMe = id == data.id;
                  if (isMe) myIndex = i;
                  final score = user.score;
                  if (score < currScore) {
                    rank++;
                    currScore = score;
                  }
                  return Container(
                      padding: const EdgeInsets.only(top: 4, bottom: 4, right: 8, left: 8),
                      color: isMe ? Colors.grey[100] : null,
                      child: Row(children: [
                        Text(_format((rank).toString(), list.length.toString().length),
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 3),
                        Expanded(
                            flex: 3,
                            child: Text(user.name + _getMedal(score, data.silver, data.bronze),
                                style: const TextStyle(fontSize: 20))),
                        Expanded(
                            flex: 1,
                            child: GestureDetector(
                                onTap: () => showDialog(
                                    context: ctx,
                                    builder: (ctx) => Dialog(
                                          insetPadding: EdgeInsets.zero,
                                          child: Text(user.country.capitalizeFirstLetters()!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Theme.of(ctx).primaryColorDark, fontSize: 20)),
                                        )),
                                child: Text(user.flag, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center))),
                        const SizedBox(width: 32),
                        Text(_format(score.toString(), data.list.first.score.toString().length),
                            style: const TextStyle(fontSize: 20))
                      ]));
                }))
              ]);
            case UIState.LOADING:
              return const Center(child: CircularProgressIndicator());
            case UIState.SET_NAME:
              return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(height: 16),
                    const Text('LEADERBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('1, 2 and 3 places can play without ads!!!', style: TextStyle(color: Colors.grey)),
                    Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: ValueListenableBuilder(
                            valueListenable: _bloc.listenable,
                            builder: (ctx, v, ch) => TextField(
                                controller: _bloc.txtNameCtr,
                                decoration: InputDecoration(
                                    focusedBorder: LoadingBorder(_bloc.listenable, Theme.of(ctx).primaryColorDark,
                                        borderSide: BorderSide(color: Theme.of(ctx).primaryColorLight)),
                                    hintText: 'Set your name',
                                    icon: Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: IconButton(
                                            onPressed: () => _showCountries(context)
                                                .then((flag) => flag != null ? _bloc.ctr.add(Event(Cmd.FLAG, flag)) : null),
                                            icon: Text(data.flag ?? '', style: const TextStyle(fontSize: 19)))))))),
                    TextButton(onPressed: () => _bloc.ctr.sink.add(Event(Cmd.NEXT)), child: const Text('OK'))
                  ]));
            default:
              throw 'unimplemented';
          }
        });
    // ]);
  }

  Future<String?> _showCountries(BuildContext context) => showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
          children: COUNTRY_TO_FLAG.entries
              .map((e) => GestureDetector(
                  onTap: () {
                    appLog(_TAG, 'tap, flag:${e.value}');
                    Navigator.pop(ctx, e.value);
                  },
                  child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('${e.value} ${e.key.capitalizeFirstLetters()}', style: const TextStyle(fontSize: 19)))))
              .toList(growable: false)));

  _showSnack(BuildContext ctx, String txt) =>
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(txt), duration: const Duration(seconds: 3)));

  String _format(String s, int max) => s.length >= max ? s : _format('$s ', max);

  String _getMedal(int score, int silver, int bronze) {
    if (score > silver) return '🥇';
    if (score > bronze) return '🥈';
    if (score == bronze) return '🥉';
    return '';
  }
}
