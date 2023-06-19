import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:web_game/bloc/main_bloc.dart';
import 'package:web_game/widget/main_widget.dart';

void main() async {
  runApp(const FlappyBall());
  Firebase.initializeApp();
}

class FlappyBall extends StatelessWidget {
  const FlappyBall({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false, theme: ThemeData(primarySwatch: Colors.blue), home: MainWidget(MainBloc()));
}
