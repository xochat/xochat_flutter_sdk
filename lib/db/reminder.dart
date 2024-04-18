import 'dart:collection';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:xochat_flutter_sdk/db/const.dart';
import 'package:xochat_flutter_sdk/db/conversation.dart';
import 'package:xochat_flutter_sdk/db/wk_db_helper.dart';
import 'package:xochat_flutter_sdk/wkim.dart';

import '../entity/conversation.dart';
import '../entity/reminder.dart';

class ReminderDB {
  ReminderDB._privateConstructor();
  static final ReminderDB _instance = ReminderDB._privateConstructor();
  static ReminderDB get shared => _instance;

  Future<int> getMaxVersion() async {
    String sql =
        "select * from ${XODBConst.tableReminders} order by version desc limit 1";
    int version = 0;

    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      if (data != null) {
        version = XODBConst.readInt(data, 'version');
      }
    }
    return version;
  }

  Future<List<XOReminder>> queryWithChannel(
      String channelID, int channelType, int done) async {
    List<XOReminder> list = [];
    List<Map<String, Object?>> results = await XODBHelper.shared.getDB().query(
        XODBConst.tableReminders,
        where: "channel_id=? and channel_type=? and done=?",
        whereArgs: [channelID, channelType, done],
        orderBy: "message_seq desc");
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeReminder(data));
      }
    }
    return list;
  }

  Future<List<XOReminder>> saveReminders(List<XOReminder> list) async {
    List<int> ids = [];
    List<String> channelIds = [];
    for (int i = 0, size = list.length; i < size; i++) {
      bool isAdd = true;
      for (String channelId in channelIds) {
        if (list[i].channelID == list[i].channelID &&
            channelId == list[i].channelID) {
          isAdd = false;
          break;
        }
      }
      if (isAdd) {
        channelIds.add(list[i].channelID);
      }
      ids.add(list[i].reminderID);
    }
    List<Map<String, dynamic>> addList = [];
    List<Map<String, dynamic>> updateList = [];
    List<XOReminder> allList = await queryWithIds(ids);
    for (int i = 0, size = list.length; i < size; i++) {
      bool isAdd = true;
      for (XOReminder reminder in allList) {
        if (reminder.reminderID == list[i].reminderID) {
          updateList.add(getMap(reminder));
          isAdd = false;
          break;
        }
      }
      if (isAdd) {
        addList.add(getMap(list[i]));
      }
    }

    if (addList.isNotEmpty || updateList.isNotEmpty) {
      XODBHelper.shared.getDB().transaction((txn) async {
        if (addList.isNotEmpty) {
          for (Map<String, dynamic> value in addList) {
            txn.insert(XODBConst.tableReminders, value,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (updateList.isNotEmpty) {
          for (Map<String, dynamic> value in updateList) {
            txn.update(XODBConst.tableReminders, value,
                where: "reminder_id=${value['reminder_id']}");
          }
        }
      });
    }

    List<XOReminder> reminderList = await queryWithChannelIds(channelIds);
    HashMap<String, List<XOReminder>?> maps = listToMap(reminderList);
    List<XOUIConversationMsg> uiMsgList = [];
    List<XOConversationMsg> msgs =
        await ConversationDB.shared.queryWithChannelIds(channelIds);
    for (int i = 0; i < msgs.length; i++) {
      uiMsgList.add(ConversationDB.shared.getUIMsg(msgs[i]));
    }
    for (int i = 0, size = uiMsgList.length; i < size; i++) {
      String key = "${uiMsgList[i].channelID}_${uiMsgList[i].channelType}";
      if (maps.containsKey(key) && maps[key] != null) {
        uiMsgList[i].setReminderList(maps[key]!);
      }
      XOIM.shared.conversationManager
          .setRefreshMsg(uiMsgList[i], i == list.length - 1);
    }
    return reminderList;
  }

  Future<List<XOReminder>> queryWithChannelIds(List<String> channelIds) async {
    List<XOReminder> list = [];
    List<Map<String, Object?>> results = await XODBHelper.shared.getDB().query(
        XODBConst.tableReminders,
        where:
            "channel_id in (${XODBConst.getPlaceholders(channelIds.length)})",
        whereArgs: channelIds);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeReminder(data));
      }
    }
    return list;
  }

  Future<List<XOReminder>> queryWithIds(List<int> ids) async {
    List<XOReminder> list = [];
    List<Map<String, Object?>> results = await XODBHelper.shared.getDB().query(
        XODBConst.tableReminders,
        where: "reminder_id in (${XODBConst.getPlaceholders(ids.length)})",
        whereArgs: ids);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeReminder(data));
      }
    }
    return list;
  }

  HashMap<String, List<XOReminder>?> listToMap(List<XOReminder> list) {
    HashMap<String, List<XOReminder>?> map = HashMap();
    if (list.isEmpty) {
      return map;
    }
    for (XOReminder reminder in list) {
      String key = "${reminder.channelID}_${reminder.channelType}";
      List<XOReminder>? tempList = [];
      if (map.containsKey(key)) {
        tempList = map[key];
      }
      tempList ??= [];
      tempList.add(reminder);
      map[key] = tempList;
    }
    return map;
  }

  dynamic getMap(XOReminder reminder) {
    var map = <String, Object>{};
    map['channel_id'] = reminder.channelID;
    map['channel_type'] = reminder.channelType;
    map['reminder_id'] = reminder.reminderID;
    map['message_id'] = reminder.messageID;
    map['message_seq'] = reminder.messageSeq;
    map['uid'] = reminder.uid;
    map['type'] = reminder.type;
    map['is_locate'] = reminder.isLocate;
    map['text'] = reminder.text;
    map['version'] = reminder.version;
    map['done'] = reminder.done;
    map['needUpload'] = reminder.needUpload;
    map['publisher'] = reminder.publisher;
    if (reminder.data != null) {
      map['data'] = jsonEncode(reminder.data);
    } else {
      map['data'] = '';
    }

    return map;
  }
}
