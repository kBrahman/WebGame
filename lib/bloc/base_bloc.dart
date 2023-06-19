// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:web_game/util/util.dart';

abstract class BaseBloc<D, C> {
  static const _TAG = 'BaseBloc';
  final ctr = StreamController<C>();

  late Stream<D> stream;

  Future<bool> inetOK() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      appLog(_TAG, 'connection problem: $e');
    }
    return false;
  }
}
