import 'dart:collection';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:xochat_flutter_sdk/db/const.dart';
import 'package:xochat_flutter_sdk/entity/channel.dart';

import '../entity/conversation.dart';
import 'wk_db_helper.dart';

class ConversationDB {
  ConversationDB._privateConstructor();
  static final ConversationDB _instance = ConversationDB._privateConstructor();
  static ConversationDB get shared => _instance;
  final String extraCols =
      "IFNULL(${XODBConst.tableConversationExtra}.browse_to,0) AS browse_to,IFNULL(${XODBConst.tableConversationExtra}.keep_message_seq,0) AS keep_message_seq,IFNULL(${XODBConst.tableConversationExtra}.keep_offset_y,0) AS keep_offset_y,IFNULL(${XODBConst.tableConversationExtra}.draft,'') AS draft,IFNULL(${XODBConst.tableConversationExtra}.draft_updated_at,0) AS draft_updated_at,IFNULL(${XODBConst.tableConversationExtra}.version,0) AS extra_version";
  final String channelCols =
      "${XODBConst.tableChannel}.channel_remark,${XODBConst.tableChannel}.channel_name,${XODBConst.tableChannel}.top,${XODBConst.tableChannel}.mute,${XODBConst.tableChannel}.save,${XODBConst.tableChannel}.status as channel_status,${XODBConst.tableChannel}.forbidden,${XODBConst.tableChannel}.invite,${XODBConst.tableChannel}.follow,${XODBConst.tableChannel}.is_deleted as channel_is_deleted,${XODBConst.tableChannel}.show_nick,${XODBConst.tableChannel}.avatar,${XODBConst.tableChannel}.avatar_cache_key,${XODBConst.tableChannel}.online,${XODBConst.tableChannel}.last_offline,${XODBConst.tableChannel}.category,${XODBConst.tableChannel}.receipt,${XODBConst.tableChannel}.robot,${XODBConst.tableChannel}.parent_channel_id AS c_parent_channel_id,${XODBConst.tableChannel}.parent_channel_type AS c_parent_channel_type,${XODBConst.tableChannel}.version AS channel_version,${XODBConst.tableChannel}.remote_extra AS channel_remote_extra,${XODBConst.tableChannel}.extra AS channel_extra";

  Future<List<XOUIConversationMsg>> queryAll() async {
    String sql =
        "SELECT ${XODBConst.tableConversation}.*,$channelCols,$extraCols FROM ${XODBConst.tableConversation} LEFT JOIN ${XODBConst.tableChannel} ON ${XODBConst.tableConversation}.channel_id = ${XODBConst.tableChannel}.channel_id AND ${XODBConst.tableConversation}.channel_type = ${XODBConst.tableChannel}.channel_type LEFT JOIN ${XODBConst.tableConversationExtra} ON ${XODBConst.tableConversation}.channel_id=${XODBConst.tableConversationExtra}.channel_id AND ${XODBConst.tableConversation}.channel_type=${XODBConst.tableConversationExtra}.channel_type where ${XODBConst.tableConversation}.is_deleted=0 order by last_msg_timestamp desc";
    List<XOUIConversationMsg> list = [];
    List<Map<String, Object?>> results =
        await XODBHelper.shared.getDB().rawQuery(sql);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        XOConversationMsg msg = XODBConst.serializeCoversation(data);
        XOChannel wkChannel = XODBConst.serializeChannel(data);
        XOUIConversationMsg uiMsg = getUIMsg(msg);
        uiMsg.setWkChannel(wkChannel);
        list.add(uiMsg);
      }
    }
    return list;
  }

  Future<bool> delete(String channelID, int channelType) async {
    Map<String, dynamic> data = HashMap<String, Object>();
    data['is_deleted'] = 1;
    int row = await XODBHelper.shared.getDB().update(
        XODBConst.tableConversation, data,
        where: "channel_id=? and channel_type=?",
        whereArgs: [channelID, channelType]);
    return row > 0;
  }

  Future<XOUIConversationMsg?> insertOrUpdateWithConvMsg(
      XOConversationMsg conversationMsg) async {
    int row;
    XOConversationMsg? lastMsg = await queryMsgByMsgChannelId(
        conversationMsg.channelID, conversationMsg.channelType);

    if (lastMsg == null || lastMsg.channelID.isEmpty) {
      row = await XODBHelper.shared.getDB().insert(
          XODBConst.tableConversation, getMap(conversationMsg, false),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      conversationMsg.unreadCount =
          lastMsg.unreadCount + conversationMsg.unreadCount;
      row = await XODBHelper.shared.getDB().update(
          XODBConst.tableConversation, getMap(conversationMsg, false),
          where: "channel_id=? and channel_type=?",
          whereArgs: [conversationMsg.channelID, conversationMsg.channelType]);
    }
    if (row > 0) {
      return getUIMsg(conversationMsg);
    }
    return null;
  }

  Future<XOConversationMsg?> queryMsgByMsgChannelId(
      String channelId, int channelType) async {
    XOConversationMsg? msg;

    List<Map<String, Object?>> list = await XODBHelper.shared.getDB().query(
        XODBConst.tableConversation,
        where: "channel_id=? and channel_type=?",
        whereArgs: [channelId, channelType]);
    if (list.isNotEmpty) {
      msg = XODBConst.serializeCoversation(list[0]);
    }
    return msg;
  }

  Future<int> getMaxVersion() async {
    int maxVersion = 0;
    String sql =
        "select max(version) version from ${XODBConst.tableConversation} limit 0, 1";

    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      maxVersion = XODBConst.readInt(data, 'version');
    }
    return maxVersion;
  }

  Future<String> getLastMsgSeqs() async {
    String lastMsgSeqs = "";
    String sql =
        "select GROUP_CONCAT(channel_id||':'||channel_type||':'|| last_seq,'|') synckey from (select *,(select max(message_seq) from ${XODBConst.tableMessage} where ${XODBConst.tableMessage}.channel_id=${XODBConst.tableConversation}.channel_id and ${XODBConst.tableMessage}.channel_type=${XODBConst.tableConversation}.channel_type limit 1) last_seq from ${XODBConst.tableConversation}) cn where channel_id<>'' AND is_deleted=0";

    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      lastMsgSeqs = XODBConst.readString(data, 'synckey');
    }
    return lastMsgSeqs;
  }

  Future<List<XOConversationMsg>> queryWithChannelIds(
      List<String> channelIds) async {
    List<XOConversationMsg> list = [];
    List<Map<String, Object?>> results = await XODBHelper.shared.getDB().query(
        XODBConst.tableConversation,
        where:
            "channel_id in (${XODBConst.getPlaceholders(channelIds.length)})",
        whereArgs: channelIds);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeCoversation(data));
      }
    }
    return list;
  }

  insertMsgList(List<XOConversationMsg> list) async {
    List<String> channelIds = [];
    for (var i = 0; i < list.length; i++) {
      if (list[i].channelID != '') {
        channelIds.add(list[i].channelID);
      }
    }
    List<XOConversationMsg> existList = await queryWithChannelIds(channelIds);
    List<Map<String, dynamic>> insertList = [];
    List<Map<String, dynamic>> updateList = [];

    for (XOConversationMsg msg in list) {
      bool isAdd = true;
      if (existList.isNotEmpty) {
        for (var i = 0; i < existList.length; i++) {
          if (existList[i].channelID == msg.channelID &&
              existList[i].channelType == msg.channelType) {
            updateList.add(getMap(msg, true));
            isAdd = false;
            break;
          }
        }
      }
      if (isAdd) {
        insertList.add(getMap(msg, true));
      }
    }
    if (insertList.isNotEmpty || updateList.isNotEmpty) {
      XODBHelper.shared.getDB().transaction((txn) async {
        if (insertList.isNotEmpty) {
          for (int i = 0; i < insertList.length; i++) {
            txn.insert(XODBConst.tableConversation, insertList[i],
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        if (updateList.isNotEmpty) {
          for (Map<String, dynamic> value in updateList) {
            txn.update(XODBConst.tableConversation, value,
                where: "channel_id=? and channel_type=?",
                whereArgs: [value['channel_id'], value['channel_type']]);
          }
        }
      });
    }
  }

  clearAll() {
    XODBHelper.shared.getDB().delete(XODBConst.tableConversation);
  }

  Future<int> queryExtraMaxVersion() async {
    int maxVersion = 0;
    String sql =
        "select max(version) version from ${XODBConst.tableConversationExtra}";

    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      maxVersion = XODBConst.readInt(data, 'version');
    }
    return maxVersion;
  }

  Future<int> updateWithField(
      dynamic map, String channelID, int channelType) async {
    return await XODBHelper.shared.getDB().update(
        XODBConst.tableConversation, map,
        where: "channel_id=? and channel_type=?",
        whereArgs: [channelID, channelType]);
  }

  XOUIConversationMsg getUIMsg(XOConversationMsg conversationMsg) {
    XOUIConversationMsg msg = XOUIConversationMsg();
    msg.lastMsgSeq = conversationMsg.lastMsgSeq;
    msg.clientMsgNo = conversationMsg.lastClientMsgNO;
    msg.unreadCount = conversationMsg.unreadCount;
    msg.lastMsgTimestamp = conversationMsg.lastMsgTimestamp;
    msg.channelID = conversationMsg.channelID;
    msg.channelType = conversationMsg.channelType;
    msg.isDeleted = conversationMsg.isDeleted;
    msg.parentChannelID = conversationMsg.parentChannelID;
    msg.parentChannelType = conversationMsg.parentChannelType;
    msg.setRemoteMsgExtra(conversationMsg.msgExtra);
    return msg;
  }

  Map<String, dynamic> getMap(XOConversationMsg msg, bool isSync) {
    Map<String, dynamic> data = HashMap<String, Object>();
    data['channel_id'] = msg.channelID;
    data['channel_type'] = msg.channelType;
    data['last_client_msg_no'] = msg.lastClientMsgNO;
    data['last_msg_timestamp'] = msg.lastMsgTimestamp;
    data['last_msg_seq'] = msg.lastMsgSeq;
    data['unread_count'] = msg.unreadCount;
    data['parent_channel_id'] = msg.parentChannelID;
    data['parent_channel_type'] = msg.parentChannelType;
    data['is_deleted'] = msg.isDeleted;
    if (msg.localExtraMap == null) {
      data['extra'] = '';
    } else {
      data['extra'] = jsonEncode(msg.localExtraMap);
    }
    if (isSync) {
      data['version'] = msg.version;
    }
    return data;
  }
}
