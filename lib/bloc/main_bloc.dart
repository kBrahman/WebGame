// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_game/bloc/base_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../util.dart';

class MainBloc extends BaseBloc<UIState, UIState> {
  static const _TAG = 'MainBloc';
  static const URL = 'url';
  final WebViewController webCtr = WebViewController();

  MainBloc() {
    stream = _getStream();
    webCtr
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) => ctr.sink.add(UIState.WEBVIEW)))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false);
    appLog(_TAG, 'main bloc');
  }

  Stream<UIState> _getStream() async* {
    final sPrefs = await SharedPreferences.getInstance();
    var url = sPrefs.getString(URL);
    appLog(_TAG, 'url from sp:$url');
    if (!await inetOK()) {
      yield UIState.ERR_CONNECTION;
    } else if (url == null) {
      try {
        final instance = FirebaseRemoteConfig.instance
          ..setConfigSettings(RemoteConfigSettings(
              fetchTimeout: const Duration(seconds: 30), minimumFetchInterval: const Duration(minutes: 1)));
        await instance.fetchAndActivate();
        url = instance.getString(URL);
        appLog(_TAG, 'url:$url, last fetch time:${instance.lastFetchTime}');
        if (await _shouldOpenPlug(url))
          yield UIState.PLUG;
        else {
          url = _checkAndCorrect(url);
          webCtr.loadRequest(Uri.parse(url));
          sPrefs.setString(URL, url);
        }
      } catch (e) {
        appLog(_TAG, 'remote config problem:$e');
        yield UIState.ERR_CONNECTION;
      }
    } else {
      try {
        webCtr.loadRequest(Uri.parse(url));
      } catch (e) {
        appLog(_TAG, 'web load err:$e');
        yield UIState.ERR_CONNECTION;
      }
    }
    yield* ctr.stream;
  }

  Future<bool> _shouldOpenPlug(String url) async => url.isEmpty || await _checkIsEmu();

  _checkIsEmu() async {
    final devInfo = DeviceInfoPlugin();
    final em = await devInfo.androidInfo;
    var phoneModel = em.model;
    var buildProduct = em.product;
    var buildHardware = em.hardware;
    var result = (em.fingerprint.startsWith("generic") ||
        phoneModel.contains("google_sdk") ||
        phoneModel.contains("droid4x") ||
        phoneModel.contains("Emulator") ||
        phoneModel.contains("Android SDK built for x86") ||
        em.manufacturer.contains("Genymotion") ||
        buildHardware == "goldfish" ||
        buildHardware == "vbox86" ||
        buildProduct == "sdk" ||
        buildProduct == "google_sdk" ||
        buildProduct == "sdk_x86" ||
        buildProduct == "vbox86p" ||
        em.brand.contains('google') ||
        em.board.toLowerCase().contains("nox") ||
        em.bootloader.toLowerCase().contains("nox") ||
        buildHardware.toLowerCase().contains("nox") ||
        !em.isPhysicalDevice ||
        buildProduct.toLowerCase().contains("nox"));
    if (result) return true;
    result = result || (em.brand.startsWith("generic") && em.device.startsWith("generic"));
    if (result) return true;
    result = result || ("google_sdk" == buildProduct);
    return result;
  }

  String _checkAndCorrect(String url) => !url.startsWith(RegExp(r'https?://')) ? 'https://$url' : url;
}

enum UIState { LOADING, ERR_CONNECTION, PLUG, WEBVIEW }
