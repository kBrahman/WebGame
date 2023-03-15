import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:web_game/bloc/main_bloc.dart';
import 'package:web_game/widget/main_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData(primarySwatch: Colors.blue), home: MainWidget(MainBloc()));
  }
}
