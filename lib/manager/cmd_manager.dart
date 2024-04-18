import 'dart:collection';

import 'package:xochat_flutter_sdk/db/const.dart';

import '../entity/cmd.dart';

class XOCMDManager {
  XOCMDManager._privateConstructor();
  static final XOCMDManager _instance = XOCMDManager._privateConstructor();
  static XOCMDManager get shared => _instance;

  HashMap<String, Function(XOCMD)>? _cmdback;
  handleCMD(dynamic json) {
    String cmd = XODBConst.readString(json, 'cmd');
    dynamic param = json['param'];
    XOCMD wkcmd = XOCMD();
    wkcmd.cmd = cmd;
    wkcmd.param = param;
    pushCMD(wkcmd);
  }

  pushCMD(XOCMD wkcmd) {
    if (_cmdback != null) {
      _cmdback!.forEach((key, back) {
        back(wkcmd);
      });
    }
  }

  addOnCmdListener(String key, Function(XOCMD) back) {
    _cmdback ??= HashMap();
    _cmdback![key] = back;
  }

  removeCmdListener(String key) {
    if (_cmdback != null) {
      _cmdback!.remove(key);
    }
  }
}
