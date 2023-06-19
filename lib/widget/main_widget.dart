import 'package:flutter/material.dart';
import 'package:web_game/bloc/main_bloc.dart';
import 'package:web_game/widget/game.dart';

class MainWidget extends StatelessWidget {
  final MainBloc _bloc;

  const MainWidget(this._bloc, {super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<UIState>(
      initialData: UIState.LOADING,
      stream: _bloc.stream,
      builder: (ctx, snap) {
        final state = snap.data!;
        return Scaffold(
            appBar: state == UIState.GAME ? AppBar(toolbarHeight: 0) : AppBar(title: const Text('Flappy Ball')),
            body: _getBody(state));
      });

  _getBody(UIState state) {
    switch (state) {
      case UIState.LOADING:
        return const Center(child: CircularProgressIndicator());
      // case UIState.ERR_CONNECTION:
      //   return const Center(child: Text('You need internet access to proceed'));
      case UIState.GAME:
        return const Game();
      default:
        throw 'not implemented';
    }
  }
}
