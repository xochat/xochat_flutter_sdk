import 'dart:collection';

import 'package:xochat_flutter_sdk/db/reminder.dart';
import 'package:xochat_flutter_sdk/entity/reminder.dart';

class XOReminderManager {
  XOReminderManager._privateConstructor();
  static final XOReminderManager _instance =
      XOReminderManager._privateConstructor();
  static XOReminderManager get shared => _instance;

  HashMap<String, Function(List<XOReminder>)>? _newReminderback;

  Future<List<XOReminder>> getWithChannel(
      String channelID, int channelType, int done) {
    return ReminderDB.shared.queryWithChannel(channelID, channelType, done);
  }

  addOnNewReminderListener(String key, Function(List<XOReminder>) back) {
    _newReminderback ??= HashMap();
    _newReminderback![key] = back;
  }

  removeOnNewReminderListener(String key) {
    if (_newReminderback != null) {
      _newReminderback!.remove(key);
    }
  }

  setNewReminder(List<XOReminder> list) {
    if (_newReminderback != null) {
      _newReminderback!.forEach((key, back) {
        back(list);
      });
    }
  }

  saveOrUpdateReminders(List<XOReminder> list) async {
    if (list.isNotEmpty) {
      List<XOReminder> wkReminders =
          await ReminderDB.shared.saveReminders(list);
      if (wkReminders.isNotEmpty) {
        setNewReminder(list);
      }
    }
  }

  Future<int> getMaxVersion() async {
    return ReminderDB.shared.getMaxVersion();
  }
}
