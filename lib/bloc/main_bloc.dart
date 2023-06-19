// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_game/bloc/base_bloc.dart';

import '../util/util.dart';
import 'package:http/http.dart';

class MainBloc extends BaseBloc<UIState, UIState> {
  static const _TAG = 'MainBloc';
  static const URL = 'url';

  MainBloc() {
    stream = _getStream();
    appLog(_TAG, 'init');
  }

  Stream<UIState> _getStream() async* {
    yield UIState.GAME;
    _getCountry();
    yield* ctr.stream;
  }

  Future<void> _getCountry() async {
    var sp = await SharedPreferences.getInstance();
    if (sp.containsKey(FLAG)) return;
    String? country;
    if (await inetOK()) {
      final s = (await get(Uri.parse('http://ip-api.com/json'))).body;
      final json = jsonDecode(s);
      country = json['country'];
    }
    if (country == null) {
      final instance = WidgetsBinding.instance;
      final code = instance.platformDispatcher.locale.countryCode;
      country = CODE_TO_COUNTRY[code];
      appLog(_TAG, 'code:$code, country:$country');
    }
    appLog(_TAG, 'country just before:$country');
    country ??= COUNTRY_TO_FLAG.keys.elementAt(Random().nextInt(COUNTRY_TO_FLAG.length));
    appLog(_TAG, 'country:$country');
    final flag = _getFlag(country.toString().toLowerCase());
    sp
      ..setString(FLAG, flag)
      ..setString(COUNTRY, country);
  }

  String _getFlag(String c) {
    return COUNTRY_TO_FLAG.entries
        .firstWhere((e) => c.toLowerCase() == e.key,
            orElse: () => MapEntry('', COUNTRY_TO_FLAG.values.elementAt(Random().nextInt(COUNTRY_TO_FLAG.length))))
        .value;
  }
}

enum UIState { LOADING, GAME }
