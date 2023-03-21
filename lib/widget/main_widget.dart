import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_game/bloc/main_bloc.dart';
import 'package:web_game/widget/flappy_ball_plug.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
            appBar: state == UIState.WEBVIEW || state == UIState.LOADING
                ? null
                : state == UIState.PLUG
                    ? AppBar(toolbarHeight: 0)
                    : AppBar(title: const Text('WebGame')),
            body: _getBody(state));
      });

  _getBody(UIState state) {
    switch (state) {
      case UIState.LOADING:
        return const Center(child: CircularProgressIndicator());
      case UIState.ERR_CONNECTION:
        return const Center(child: Text('You need internet access to proceed'));
      case UIState.PLUG:
        return const FlappyBallPlug();
      case UIState.WEBVIEW:
        return SafeArea(
            child: WillPopScope(
                onWillPop: () async {
                  _bloc.webCtr.goBack();
                  return false;
                },
                child: WebViewWidget(controller: _bloc.webCtr)));
      default:
        throw 'not implemented';
    }
  }
}
