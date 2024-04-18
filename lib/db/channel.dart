import 'dart:collection';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:xochat_flutter_sdk/db/const.dart';
import 'package:xochat_flutter_sdk/entity/channel.dart';

import 'wk_db_helper.dart';

class ChannelDB {
  ChannelDB._privateConstructor();
  static final ChannelDB _instance = ChannelDB._privateConstructor();
  static ChannelDB get shared => _instance;

  Future<XOChannel?> query(String channelID, int channelType) async {
    XOChannel? channel;
    List<Map<String, Object?>> list = await XODBHelper.shared.getDB().query(
        XODBConst.tableChannel,
        where: "channel_id=? and channel_type=?",
        whereArgs: [channelID, channelType]);
    if (list.isNotEmpty) {
      channel = XODBConst.serializeChannel(list[0]);
    }
    return channel;
  }

  insertOrUpdateList(List<XOChannel> list) async {
    List<Map<String, dynamic>> addList = [];
    List<Map<String, dynamic>> updateList = [];
    for (XOChannel channel in list) {
      bool bl = await isExist(channel.channelID, channel.channelType);
      if (bl) {
        updateList.add(getMap(channel));
      } else {
        addList.add(getMap(channel));
      }
    }
    if (addList.isNotEmpty || updateList.isNotEmpty) {
      XODBHelper.shared.getDB().transaction((txn) async {
        if (addList.isNotEmpty) {
          for (Map<String, dynamic> value in addList) {
            txn.insert(XODBConst.tableChannel, value);
          }
        }
        if (updateList.isNotEmpty) {
          for (Map<String, dynamic> value in updateList) {
            txn.update(XODBConst.tableChannel, value,
                where: "channel_id=? and channel_type=?",
                whereArgs: [value['channel_id'], value['channel_type']]);
          }
        }
      });
    }
  }

  saveOrUpdate(XOChannel channel) async {
    bool bl = await isExist(channel.channelID, channel.channelType);
    if (!bl) {
      insert(channel);
    } else {
      update(channel);
    }
  }

  insert(XOChannel channel) {
    XODBHelper.shared.getDB().insert(XODBConst.tableChannel, getMap(channel),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  update(XOChannel channel) {
    XODBHelper.shared.getDB().update(XODBConst.tableChannel, getMap(channel),
        where: "channel_id=? and channel_type=?",
        whereArgs: [channel.channelID, channel.channelType]);
  }

  Future<bool> isExist(String channelID, int channelType) async {
    bool isExit = false;
    List<Map<String, Object?>> list = await XODBHelper.shared.getDB().query(
        XODBConst.tableChannel,
        where: "channel_id=? and channel_type=?",
        whereArgs: [channelID, channelType]);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      if (data != null) {
        String channelID = XODBConst.readString(data, 'channel_id');
        if (channelID != '') {
          isExit = true;
        }
      }
    }
    return isExit;
  }

  Future<List<XOChannel>> queryWithChannelIdsAndChannelType(
      List<String> channelIDs, int channelType) async {
    if (channelIDs.isEmpty) {
      return [];
    }
    List<Object> args = [];
    args.addAll(channelIDs);
    args.add(channelType);
    List<XOChannel> list = [];
    List<Map<String, Object?>> results = await XODBHelper.shared.getDB().query(
        XODBConst.tableChannel,
        where:
            "channel_id in (${XODBConst.getPlaceholders(channelIDs.length)}) and channel_type=?",
        whereArgs: args);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeChannel(data));
      }
    }
    return list;
  }

  dynamic getMap(XOChannel channel) {
    var data = HashMap<String, Object>();
    data['channel_id'] = channel.channelID;
    data['channel_type'] = channel.channelType;
    data['channel_name'] = channel.channelName;
    data['channel_remark'] = channel.channelRemark;
    data['avatar'] = channel.avatar;
    data['top'] = channel.top;
    data['save'] = channel.save;
    data['mute'] = channel.mute;
    data['forbidden'] = channel.forbidden;
    data['invite'] = channel.invite;
    data['status'] = channel.status;
    data['is_deleted'] = channel.isDeleted;
    data['follow'] = channel.follow;
    data['version'] = channel.version;
    data['show_nick'] = channel.showNick;
    data['created_at'] = channel.createdAt;
    data['updated_at'] = channel.updatedAt;
    data['online'] = channel.online;
    data['last_offline'] = channel.lastOffline;
    data['receipt'] = channel.receipt;
    data['robot'] = channel.robot;
    data['category'] = channel.category;
    data['username'] = channel.username;
    data['avatar_cache_key'] = channel.avatarCacheKey;
    data['device_flag'] = channel.deviceFlag;
    data['parent_channel_id'] = channel.parentChannelID;
    data['parent_channel_type'] = channel.parentChannelType;
    if (channel.remoteExtraMap != null) {
      data['remote_extra'] = jsonEncode(channel.remoteExtraMap);
    }
    if (channel.localExtra != null) {
      data['extra'] = jsonEncode(channel.localExtra);
    }
    return data;
  }
}
