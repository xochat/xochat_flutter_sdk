import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:xochat_flutter_sdk/db/channel.dart';
import 'package:xochat_flutter_sdk/db/const.dart';
import 'package:xochat_flutter_sdk/db/reaction.dart';
import 'package:xochat_flutter_sdk/entity/msg.dart';
import 'package:xochat_flutter_sdk/type/const.dart';
import 'package:xochat_flutter_sdk/wkim.dart';

import '../entity/channel.dart';
import '../entity/channel_member.dart';
import 'channel_member.dart';
import 'wk_db_helper.dart';

class MessageDB {
  MessageDB._privateConstructor();
  static final MessageDB _instance = MessageDB._privateConstructor();
  static MessageDB get shared => _instance;
  final String extraCols =
      "IFNULL(${XODBConst.tableMessageExtra}.readed,0) as readed,IFNULL(${XODBConst.tableMessageExtra}.readed_count,0) as readed_count,IFNULL(${XODBConst.tableMessageExtra}.unread_count,0) as unread_count,IFNULL(${XODBConst.tableMessageExtra}.revoke,0) as revoke,IFNULL(${XODBConst.tableMessageExtra}.revoker,'') as revoker,IFNULL(${XODBConst.tableMessageExtra}.extra_version,0) as extra_version,IFNULL(${XODBConst.tableMessageExtra}.is_mutual_deleted,0) as is_mutual_deleted,IFNULL(${XODBConst.tableMessageExtra}.need_upload,0) as need_upload,IFNULL(${XODBConst.tableMessageExtra}.content_edit,'') as content_edit,IFNULL(${XODBConst.tableMessageExtra}.edited_at,0) as edited_at";
  final String messageCols =
      "${XODBConst.tableMessage}.client_seq,${XODBConst.tableMessage}.message_id,${XODBConst.tableMessage}.message_seq,${XODBConst.tableMessage}.channel_id,${XODBConst.tableMessage}.channel_type,${XODBConst.tableMessage}.timestamp,${XODBConst.tableMessage}.topic_id,${XODBConst.tableMessage}.from_uid,${XODBConst.tableMessage}.type,${XODBConst.tableMessage}.content,${XODBConst.tableMessage}.status,${XODBConst.tableMessage}.voice_status,${XODBConst.tableMessage}.created_at,${XODBConst.tableMessage}.updated_at,${XODBConst.tableMessage}.searchable_word,${XODBConst.tableMessage}.client_msg_no,${XODBConst.tableMessage}.setting,${XODBConst.tableMessage}.order_seq,${XODBConst.tableMessage}.extra,${XODBConst.tableMessage}.is_deleted,${XODBConst.tableMessage}.flame,${XODBConst.tableMessage}.flame_second,${XODBConst.tableMessage}.viewed,${XODBConst.tableMessage}.viewed_at";

  Future<bool> isExist(String clientMsgNo) async {
    bool isExist = false;
    List<Map<String, Object?>> list = await XODBHelper.shared.getDB().query(
        XODBConst.tableMessage,
        where: "client_msg_no=?",
        whereArgs: [clientMsgNo]);
    if (list.isNotEmpty) {
      isExist = true;
    }
    return isExist;
  }

  Future<int> insert(XOMsg msg) async {
    if (msg.clientSeq != 0) {
      updateMsg(msg);
      return msg.clientSeq;
    }
    if (msg.clientMsgNO != '') {
      bool exist = await isExist(msg.clientMsgNO);
      if (exist) {
        msg.isDeleted = 1;
        msg.clientMsgNO = XOIM.shared.messageManager.generateClientMsgNo();
      }
    }
    return await XODBHelper.shared.getDB().insert(
        XODBConst.tableMessage, getMap(msg),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMsg(XOMsg msg) async {
    return await XODBHelper.shared.getDB().update(
        XODBConst.tableMessage, getMap(msg),
        where: "client_seq=?", whereArgs: [msg.clientSeq]);
  }

  Future<int> updateMsgWithField(dynamic map, int clientSeq) async {
    return await XODBHelper.shared.getDB().update(XODBConst.tableMessage, map,
        where: "client_seq=?", whereArgs: [clientSeq]);
  }

  Future<int> updateMsgWithFieldAndClientMsgNo(
      dynamic map, String clientMsgNO) async {
    return await XODBHelper.shared.getDB().update(XODBConst.tableMessage, map,
        where: "client_msg_no=?", whereArgs: [clientMsgNO]);
  }

  Future<XOMsg?> queryWithClientMsgNo(String clientMsgNo) async {
    XOMsg? wkMsg;
    String sql =
        "select $messageCols,$extraCols from ${XODBConst.tableMessage} LEFT JOIN ${XODBConst.tableMessageExtra} ON ${XODBConst.tableMessage}.message_id=${XODBConst.tableMessageExtra}.message_id WHERE ${XODBConst.tableMessage}.client_msg_no=?";

    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql, [clientMsgNo]);
    if (list.isNotEmpty) {
      wkMsg = XODBConst.serializeXOMsg(list[0]);
    }
    if (wkMsg != null) {
      wkMsg.reactionList =
          await ReactionDB.shared.queryWithMessageId(wkMsg.messageID);
    }
    return wkMsg;
  }

  Future<XOMsg?> queryWithClientSeq(int clientSeq) async {
    XOMsg? wkMsg;
    String sql =
        "select $messageCols,$extraCols from ${XODBConst.tableMessage} LEFT JOIN ${XODBConst.tableMessageExtra} ON ${XODBConst.tableMessage}.message_id=${XODBConst.tableMessageExtra}.message_id WHERE ${XODBConst.tableMessage}.client_seq=?";

    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql, [clientSeq]);
    if (list.isNotEmpty) {
      wkMsg = XODBConst.serializeXOMsg(list[0]);
    }
    if (wkMsg != null) {
      wkMsg.reactionList =
          await ReactionDB.shared.queryWithMessageId(wkMsg.messageID);
    }
    return wkMsg;
  }

  Future<List<XOMsg>> queryWithMessageIds(List<String> messageIds) async {
    String sql =
        "select $messageCols,$extraCols from ${XODBConst.tableMessage} LEFT JOIN ${XODBConst.tableMessageExtra} ON ${XODBConst.tableMessage}.message_id=${XODBConst.tableMessageExtra}.message_id WHERE ${XODBConst.tableMessage}.message_id in (${XODBConst.getPlaceholders(messageIds.length)})";
    List<XOMsg> list = [];
    List<Map<String, Object?>> results =
        await XODBHelper.shared.getDB().rawQuery(sql, messageIds);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeXOMsg(data));
      }
    }
    return list;
  }

  Future<int> queryMaxOrderSeq(String channelID, int channelType) async {
    int maxOrderSeq = 0;
    String sql =
        "select max(order_seq) order_seq from ${XODBConst.tableMessage} where channel_id =? and channel_type=? and type<>99 and type<>0 and is_deleted=0";
    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql, [channelID, channelType]);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      maxOrderSeq = XODBConst.readInt(data, 'order_seq');
    }
    return maxOrderSeq;
  }

  Future<int> getMaxMessageSeq(String channelID, int channelType) async {
    String sql =
        "SELECT max(message_seq) message_seq FROM ${XODBConst.tableMessage} WHERE channel_id=? AND channel_type=?";
    int messageSeq = 0;
    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql, [channelID, channelType]);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      messageSeq = XODBConst.readInt(data, 'message_seq');
    }
    return messageSeq;
  }

  Future<int> getOrderSeq(
      String channelID, int channelType, int maxOrderSeq, int limit) async {
    int minOrderSeq = 0;
    String sql =
        "select order_seq from ${XODBConst.tableMessage} where channel_id=? and channel_type=? and type<>99 and order_seq <=? order by order_seq desc limit ?";
    List<Map<String, Object?>> list = await XODBHelper.shared
        .getDB()
        .rawQuery(sql, [channelID, channelType, maxOrderSeq, limit]);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      minOrderSeq = XODBConst.readInt(data, 'order_seq');
    }
    return minOrderSeq;
  }

  Future<List<XOMsg>> getMessages(String channelId, int channelType,
      int oldestOrderSeq, bool contain, int pullMode, int limit) async {
    List<XOMsg> msgList = [];
    String sql;
    var args = [];
    if (oldestOrderSeq <= 0) {
      sql =
          "SELECT * FROM (SELECT $messageCols,$extraCols FROM ${XODBConst.tableMessage} LEFT JOIN ${XODBConst.tableMessageExtra} on ${XODBConst.tableMessage}.message_id=${XODBConst.tableMessageExtra}.message_id WHERE ${XODBConst.tableMessage}.channel_id=? and ${XODBConst.tableMessage}.channel_type=? and ${XODBConst.tableMessage}.type<>0 and ${XODBConst.tableMessage}.type<>99) where is_deleted=0 and is_mutual_deleted=0 order by order_seq desc limit 0,?";
      args.add(channelId);
      args.add(channelType);
      args.add(limit);
    } else {
      if (pullMode == 0) {
        if (contain) {
          sql =
              "SELECT * FROM (SELECT $messageCols,$extraCols FROM ${XODBConst.tableMessage} LEFT JOIN ${XODBConst.tableMessageExtra} on ${XODBConst.tableMessage}.message_id=${XODBConst.tableMessageExtra}.message_id WHERE ${XODBConst.tableMessage}.channel_id=? and ${XODBConst.tableMessage}.channel_type=? and ${XODBConst.tableMessage}.type<>0 and ${XODBConst.tableMessage}.type<>99 AND ${XODBConst.tableMessage}.order_seq<=?) where is_deleted=0 and is_mutual_deleted=0 order by order_seq desc limit 0,?";
        } else {
          sql =
              "SELECT * FROM (SELECT $messageCols,$extraCols FROM ${XODBConst.tableMessage} LEFT JOIN ${XODBConst.tableMessageExtra} on ${XODBConst.tableMessage}.message_id=${XODBConst.tableMessageExtra}.message_id WHERE ${XODBConst.tableMessage}.channel_id=? and ${XODBConst.tableMessage}.channel_type=? and ${XODBConst.tableMessage}.type<>0 and ${XODBConst.tableMessage}.type<>99 AND ${XODBConst.tableMessage}.order_seq<?) where is_deleted=0 and is_mutual_deleted=0 order by order_seq desc limit 0,?";
        }
      } else {
        if (contain) {
          sql =
              "SELECT * FROM (SELECT $messageCols,$extraCols FROM ${XODBConst.tableMessage} LEFT JOIN ${XODBConst.tableMessageExtra} on ${XODBConst.tableMessage}.message_id=${XODBConst.tableMessageExtra}.message_id WHERE ${XODBConst.tableMessage}.channel_id=? and ${XODBConst.tableMessage}.channel_type=? and ${XODBConst.tableMessage}.type<>0 and ${XODBConst.tableMessage}.type<>99 AND ${XODBConst.tableMessage}.order_seq>=?) where is_deleted=0 and is_mutual_deleted=0 order by order_seq asc limit 0,?";
        } else {
          sql =
              "SELECT * FROM (SELECT $messageCols,$extraCols FROM ${XODBConst.tableMessage} LEFT JOIN ${XODBConst.tableMessageExtra} on ${XODBConst.tableMessage}.message_id=${XODBConst.tableMessageExtra}.message_id WHERE ${XODBConst.tableMessage}.channel_id=? and ${XODBConst.tableMessage}.channel_type=? and ${XODBConst.tableMessage}.type<>0 and ${XODBConst.tableMessage}.type<>99 AND ${XODBConst.tableMessage}.order_seq>?) where is_deleted=0 and is_mutual_deleted=0 order by order_seq asc limit 0,?";
        }
      }
      args.add(channelId);
      args.add(channelType);
      args.add(oldestOrderSeq);
      args.add(limit);
    }
    List<String> messageIds = [];
    List<String> replyMsgIds = [];
    List<String> fromUIDs = [];
    List<Map<String, Object?>> results =
        await XODBHelper.shared.getDB().rawQuery(sql, args);
    if (results.isNotEmpty) {
      XOChannel? wkChannel =
          await ChannelDB.shared.query(channelId, channelType);
      for (Map<String, Object?> data in results) {
        XOMsg wkMsg = XODBConst.serializeXOMsg(data);
        wkMsg.setChannelInfo(wkChannel);
        if (wkMsg.messageID != '') {
          messageIds.add(wkMsg.messageID);
        }

        if (wkMsg.messageContent != null &&
            wkMsg.messageContent!.reply != null &&
            wkMsg.messageContent!.reply!.messageId != '') {
          replyMsgIds.add(wkMsg.messageContent!.reply!.messageId);
        }
        if (wkMsg.fromUID != '') {
          bool isAdd = true;
          for (int i = 0; i < fromUIDs.length; i++) {
            if (fromUIDs[i] == wkMsg.fromUID) {
              isAdd = false;
              break;
            }
          }
          if (isAdd) {
            fromUIDs.add(wkMsg.fromUID);
          }
        }
        if (pullMode == 0) {
          msgList.insert(0, wkMsg);
        } else {
          msgList.add(wkMsg);
        }
      }
    }
    //扩展消息
    List<XOMsgReaction> list =
        await ReactionDB.shared.queryWithMessageIds(messageIds);
    if (list.isNotEmpty) {
      for (int i = 0, size = msgList.length; i < size; i++) {
        for (int j = 0, len = list.length; j < len; j++) {
          if (list[j].messageID == msgList[i].messageID) {
            if (msgList[i].reactionList == null) {
              msgList[i].reactionList = [];
            }
            msgList[i].reactionList!.add(list[j]);
          }
        }
      }
    }
    // 发送者成员信息
    if (channelType == XOChannelType.group) {
      List<XOChannelMember> memberList = await ChannelMemberDB.shared
          .queryMemberWithUIDs(channelId, channelType, fromUIDs);
      if (memberList.isNotEmpty) {
        for (XOChannelMember member in memberList) {
          for (int i = 0, size = msgList.length; i < size; i++) {
            if (msgList[i].fromUID != '' &&
                msgList[i].fromUID == member.memberUID) {
              msgList[i].setMemberOfFrom(member);
            }
          }
        }
      }
    }
    //消息发送者信息
    List<XOChannel> wkChannels = await ChannelDB.shared
        .queryWithChannelIdsAndChannelType(fromUIDs, XOChannelType.personal);
    if (wkChannels.isNotEmpty) {
      for (XOChannel wkChannel in wkChannels) {
        for (int i = 0, size = msgList.length; i < size; i++) {
          if (msgList[i].fromUID != '' &&
              msgList[i].fromUID == wkChannel.channelID) {
            msgList[i].setFrom(wkChannel);
          }
        }
      }
    }
    // 查询编辑内容
    if (replyMsgIds.isNotEmpty) {
      List<XOMsgExtra> msgExtraList =
          await queryMsgExtrasWithMsgIds(replyMsgIds);
      if (msgExtraList.isNotEmpty) {
        for (XOMsgExtra extra in msgExtraList) {
          for (int i = 0, size = msgList.length; i < size; i++) {
            if (msgList[i].messageContent != null &&
                msgList[i].messageContent!.reply != null &&
                extra.messageID ==
                    msgList[i].messageContent!.reply!.messageId) {
              msgList[i].messageContent!.reply!.revoke = extra.revoke;
            }
            if (extra.contentEdit != '' &&
                msgList[i].messageContent != null &&
                msgList[i].messageContent!.reply != null &&
                msgList[i].messageContent!.reply!.messageId != '' &&
                extra.messageID ==
                    msgList[i].messageContent!.reply!.messageId) {
              msgList[i].messageContent!.reply!.editAt = extra.editedAt;
              msgList[i].messageContent!.reply!.contentEdit = extra.contentEdit;
              var json = jsonEncode(extra.contentEdit);
              var type = XODBConst.readInt(json, 'type');
              msgList[i].messageContent!.reply!.contentEditMsgModel =
                  XOIM.shared.messageManager.getMessageModel(type, json);
              break;
            }
          }
        }
      }
    }
    return msgList;
  }

  var requestCount = 0;
  var isMore = 1;
  void getOrSyncHistoryMessages(
      String channelId,
      int channelType,
      int oldestOrderSeq,
      bool contain,
      int pullMode,
      int limit,
      final Function(List<XOMsg>) iGetOrSyncHistoryMsgBack,
      final Function() syncBack) async {
    //获取原始数据
    List<XOMsg> list = await getMessages(
        channelId, channelType, oldestOrderSeq, contain, pullMode, limit);
    //业务判断数据
    List<XOMsg> tempList = [];
    for (int i = 0, size = list.length; i < size; i++) {
      tempList.add(list[i]);
    }

    //先通过message_seq排序
    if (tempList.isNotEmpty) {
      tempList.sort((a, b) => a.messageSeq.compareTo(b.messageSeq));
    }
    //获取最大和最小messageSeq
    int minMessageSeq = 0;
    int maxMessageSeq = 0;
    for (int i = 0, size = tempList.length; i < size; i++) {
      if (tempList[i].messageSeq != 0) {
        if (minMessageSeq == 0) minMessageSeq = tempList[i].messageSeq;
        if (tempList[i].messageSeq > maxMessageSeq) {
          maxMessageSeq = tempList[i].messageSeq;
        }

        if (tempList[i].messageSeq < minMessageSeq) {
          minMessageSeq = tempList[i].messageSeq;
        }
      }
    }
    //是否同步消息
    bool isSyncMsg = false;
    int startMsgSeq = 0;
    int endMsgSeq = 0;
    //判断页与页之间是否连续
    int oldestMsgSeq;

    //如果获取到的messageSeq为0说明oldestOrderSeq这条消息是本地消息则获取他上一条或下一条消息的messageSeq做为判断
    if (oldestOrderSeq % 1000 != 0) {
      oldestMsgSeq =
          await getMsgSeq(channelId, channelType, oldestOrderSeq, pullMode);
    } else {
      oldestMsgSeq = oldestOrderSeq ~/ 1000;
    }
    if (oldestMsgSeq == 1 || isMore == 0) {
      isMore = 1;
      requestCount = 0;
      iGetOrSyncHistoryMsgBack(list);
      return;
    }
    if (pullMode == 0) {
      //下拉获取消息
      if (maxMessageSeq != 0 &&
          oldestMsgSeq != 0 &&
          oldestMsgSeq - maxMessageSeq > 1) {
        isSyncMsg = true;
        startMsgSeq = oldestMsgSeq;
        endMsgSeq = maxMessageSeq;
      }
    } else {
      //上拉获取消息
      if (minMessageSeq != 0 &&
          oldestMsgSeq != 0 &&
          minMessageSeq - oldestMsgSeq > 1) {
        isSyncMsg = true;
        startMsgSeq = oldestMsgSeq;
        endMsgSeq = minMessageSeq;
      }
    }
    if (!isSyncMsg) {
      //判断当前页是否连续
      for (int i = 0, size = tempList.length; i < size; i++) {
        int nextIndex = i + 1;
        if (nextIndex < tempList.length) {
          if (tempList[nextIndex].messageSeq != 0 &&
              tempList[i].messageSeq != 0 &&
              tempList[nextIndex].messageSeq - tempList[i].messageSeq > 1) {
            //判断该条消息是否被删除
            int num = await getDeletedCount(tempList[i].messageSeq,
                tempList[nextIndex].messageSeq, channelId, channelType);
            if (num <
                (tempList[nextIndex].messageSeq - tempList[i].messageSeq) - 1) {
              isSyncMsg = true;
              int max = tempList[nextIndex].messageSeq;
              int min = tempList[i].messageSeq;
              if (tempList[nextIndex].messageSeq < tempList[i].messageSeq) {
                max = tempList[i].messageSeq;
                min = tempList[nextIndex].messageSeq;
              }
              if (pullMode == 0) {
                // 下拉
                startMsgSeq = max;
                endMsgSeq = min;
              } else {
                startMsgSeq = min;
                endMsgSeq = max;
              }
              break;
            }
          }
        }
      }
    }
    if (!isSyncMsg) {
      if (minMessageSeq == 1) {
        requestCount = 0;
        iGetOrSyncHistoryMsgBack(list);
        return;
      }
    }
    //计算最后一页后是否还存在消息
    int syncLimit = limit;
    if (!isSyncMsg && tempList.length < limit) {
      if (pullMode == 0) {
        //如果下拉获取数据
        isSyncMsg = true;
        // startMsgSeq = oldestMsgSeq;
        startMsgSeq = minMessageSeq; // 不满足查询数量同步时按查询到的最小seq开始同步
        if (!contain) {
          syncLimit = syncLimit + 1;
        }
        endMsgSeq = 0;
      } else {
        //如果上拉获取数据
        isSyncMsg = true;
        // startMsgSeq = oldestMsgSeq;
        startMsgSeq = maxMessageSeq; // 不满足查询数量同步时按查询到的最大seq开始同步
        endMsgSeq = 0;
        if (!contain) {
          syncLimit = syncLimit + 1;
        }
      }
    }
    if (isSyncMsg &&
        (startMsgSeq != endMsgSeq || (startMsgSeq == 0 && endMsgSeq == 0)) &&
        requestCount < 5) {
      if (requestCount == 0) {
        syncBack();
      }
      //同步消息
      requestCount++;
      XOIM.shared.messageManager.setSyncChannelMsgListener(
          channelId, channelType, startMsgSeq, endMsgSeq, syncLimit, pullMode,
          (syncChannelMsg) {
        if (syncChannelMsg != null &&
            syncChannelMsg.messages != null &&
            syncChannelMsg.messages!.isNotEmpty) {
          isMore = syncChannelMsg.more;
          getOrSyncHistoryMessages(channelId, channelType, oldestOrderSeq,
              contain, pullMode, limit, iGetOrSyncHistoryMsgBack, syncBack);
        } else {
          requestCount = 0;
          isMore = 1;
          iGetOrSyncHistoryMsgBack(list);
        }
      });
    } else {
      requestCount = 0;
      isMore = 1;
      iGetOrSyncHistoryMsgBack(list);
    }
  }

  Future<int> getDeletedCount(int minMessageSeq, int maxMessageSeq,
      String channelID, int channelType) async {
    String sql =
        "select count(*) num from ${XODBConst.tableMessage} where channel_id=? and channel_type=? and message_seq>? and message_seq<? and is_deleted=1";
    int num = 0;
    List<Map<String, Object?>> list = await XODBHelper.shared
        .getDB()
        .rawQuery(sql, [channelID, channelType, minMessageSeq, maxMessageSeq]);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      num = XODBConst.readInt(data, 'num');
    }
    return num;
  }

  Future<int> getMsgSeq(String channelID, int channelType, int oldestOrderSeq,
      int pullMode) async {
    String sql;
    int messageSeq = 0;
    if (pullMode == 1) {
      sql =
          "select message_seq from ${XODBConst.tableMessage} where channel_id=? and channel_type=? and  order_seq>? and message_seq<>0 order by message_seq desc limit 1";
    } else {
      sql =
          "select message_seq from ${XODBConst.tableMessage} where channel_id=? and channel_type=? and  order_seq<? and message_seq<>0 order by message_seq asc limit 1";
    }

    List<Map<String, Object?>> list = await XODBHelper.shared
        .getDB()
        .rawQuery(sql, [channelID, channelType, oldestOrderSeq]);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      messageSeq = XODBConst.readInt(data, 'message_seq');
    }
    return messageSeq;
  }

  Future<bool> insertMsgList(List<XOMsg> list) async {
    if (list.isEmpty) return true;
    if (list.length == 1) {
      insert(list[0]);
      return true;
    }
    List<XOMsg> saveList = [];
    for (int i = 0, size = list.length; i < size; i++) {
      bool isExist = false;
      for (int j = 0, len = saveList.length; j < len; j++) {
        if (list[i].clientMsgNO == saveList[j].clientMsgNO) {
          isExist = true;
          break;
        }
      }
      if (isExist) {
        list[i].clientMsgNO = XOIM.shared.messageManager.generateClientMsgNo();
        list[i].isDeleted = 1;
      }
      saveList.add(list[i]);
    }
    List<String> clientMsgNos = [];
    List<XOMsg> existMsgList = [];
    for (int i = 0, size = saveList.length; i < size; i++) {
      if (clientMsgNos.length == 200) {
        List<XOMsg> tempList = await queryWithClientMsgNos(clientMsgNos);
        if (tempList.isNotEmpty) {
          existMsgList.addAll(tempList);
        }

        clientMsgNos.clear();
      }
      if (saveList[i].clientMsgNO != '') {}
      clientMsgNos.add(saveList[i].clientMsgNO);
    }
    if (clientMsgNos.isNotEmpty) {
      List<XOMsg> tempList = await queryWithClientMsgNos(clientMsgNos);
      if (tempList.isNotEmpty) {
        existMsgList.addAll(tempList);
      }

      clientMsgNos.clear();
    }

    for (XOMsg msg in saveList) {
      for (XOMsg tempMsg in existMsgList) {
        if (tempMsg.clientMsgNO != '' &&
            msg.clientMsgNO != '' &&
            tempMsg.clientMsgNO == msg.clientMsgNO) {
          msg.isDeleted = 1;
          msg.clientMsgNO = XOIM.shared.messageManager.generateClientMsgNo();
          break;
        }
      }
    }
    //  insertMsgList(saveList);
    List<Map<String, Object>> cvList = [];
    for (XOMsg wkMsg in saveList) {
      cvList.add(getMap(wkMsg));
    }
    if (cvList.isNotEmpty) {
      XODBHelper.shared.getDB().transaction((txn) async {
        for (int i = 0; i < cvList.length; i++) {
          txn.insert(XODBConst.tableMessage, cvList[i],
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    }
    return true;
  }

  Future<List<XOMsg>> queryWithClientMsgNos(List<String> clientMsgNos) async {
    List<XOMsg> msgs = [];
    List<Map<String, Object?>> results = await XODBHelper.shared.getDB().query(
        XODBConst.tableMessage,
        where:
            "client_msg_no in (${XODBConst.getPlaceholders(clientMsgNos.length)})",
        whereArgs: clientMsgNos);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        msgs.add(XODBConst.serializeXOMsg(data));
      }
    }
    return msgs;
  }

  Future<bool> insertOrUpdateMsgExtras(List<XOMsgExtra> list) async {
    List<String> msgIds = [];
    for (int i = 0, size = list.length; i < size; i++) {
      if (list[i].messageID != '') {
        msgIds.add(list[i].messageID);
      }
    }
    List<XOMsgExtra> existList = await queryMsgExtrasWithMsgIds(msgIds);
    List<Map<String, Object>> insertCVList = [];
    List<Map<String, Object>> updateCVList = [];
    for (int i = 0, size = list.length; i < size; i++) {
      bool isAdd = true;
      for (XOMsgExtra extra in existList) {
        if (list[i].messageID == extra.messageID) {
          updateCVList.add(getExtraMap(list[i]));
          isAdd = false;
          break;
        }
      }
      if (isAdd) {
        insertCVList.add(getExtraMap(list[i]));
      }
    }
    if (insertCVList.isNotEmpty || updateCVList.isNotEmpty) {
      XODBHelper.shared.getDB().transaction((txn) async {
        if (insertCVList.isNotEmpty) {
          for (int i = 0; i < insertCVList.length; i++) {
            txn.insert(XODBConst.tableMessageExtra, insertCVList[0],
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          if (updateCVList.isNotEmpty) {
            for (int i = 0; i < updateCVList.length; i++) {
              txn.update(XODBConst.tableMessageExtra, updateCVList[0],
                  where: "message_id=?",
                  whereArgs: [updateCVList[i]['message_id']]);
            }
          }
        }
      });
    }
    return true;
  }

  Future<int> queryMaxExtraVersionWithChannel(
      String channelID, int channelType) async {
    int extraVersion = 0;
    String sql =
        "select max(extra_version) extra_version from ${XODBConst.tableMessageExtra} where channel_id =? and channel_type=?";
    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql, [channelID, channelType]);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      extraVersion = XODBConst.readInt(data, 'extra_version');
    }
    return extraVersion;
  }

  Future<List<XOMsgExtra>> queryMsgExtraWithNeedUpload(int needUpload) async {
    String sql =
        "select * from ${XODBConst.tableMessageExtra}  where need_upload=?";
    List<XOMsgExtra> list = [];
    List<Map<String, Object?>> results =
        await XODBHelper.shared.getDB().rawQuery(sql, [needUpload]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeMsgExtra(data));
      }
    }

    return list;
  }

  Future<XOMsgExtra?> queryMsgExtraWithMsgID(String messageID) async {
    XOMsgExtra? msgExtra;
    List<Map<String, Object?>> list = await XODBHelper.shared.getDB().query(
        XODBConst.tableMessageExtra,
        where: "message_id=?",
        whereArgs: [messageID]);
    if (list.isNotEmpty) {
      msgExtra = XODBConst.serializeMsgExtra(list[0]);
    }
    return msgExtra;
  }

  Future<List<XOMsgExtra>> queryMsgExtrasWithMsgIds(List<String> msgIds) async {
    List<XOMsgExtra> list = [];
    List<Map<String, Object?>> results = await XODBHelper.shared.getDB().query(
        XODBConst.tableMessageExtra,
        where: "message_id in (${XODBConst.getPlaceholders(msgIds.length)})",
        whereArgs: msgIds);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeMsgExtra(data));
      }
    }

    return list;
  }

  updateSendingMsgFail() {
    var map = <String, Object>{};
    map['status'] = XOSendMsgResult.sendFail;
    XODBHelper.shared
        .getDB()
        .update(XODBConst.tableMessage, map, where: 'status=0');
  }

  Future<XOMsg?> queryMaxOrderSeqMsgWithChannel(
      String channelID, int channelType) async {
    XOMsg? wkMsg;
    String sql =
        "select * from ${XODBConst.tableMessage} where channel_id=? and channel_type=? and is_deleted=0 and type<>0 and type<>99 order by order_seq desc limit 1";
    List<Map<String, Object?>> list =
        await XODBHelper.shared.getDB().rawQuery(sql, [channelID, channelType]);
    if (list.isNotEmpty) {
      dynamic data = list[0];
      if (data != null) {
        wkMsg = XODBConst.serializeXOMsg(data);
      }
    }
    if (wkMsg != null) {
      wkMsg.reactionList =
          await ReactionDB.shared.queryWithMessageId(wkMsg.messageID);
    }
    return wkMsg;
  }

  dynamic getMap(XOMsg msg) {
    var map = <String, Object>{};
    map['message_id'] = msg.messageID;
    map['message_seq'] = msg.messageSeq;
    map['order_seq'] = msg.orderSeq;
    map['timestamp'] = msg.timestamp;
    map['from_uid'] = msg.fromUID;
    map['channel_id'] = msg.channelID;
    map['channel_type'] = msg.channelType;
    map['is_deleted'] = msg.isDeleted;
    map['type'] = msg.contentType;
    map['content'] = msg.content;
    map['status'] = msg.status;
    map['voice_status'] = msg.voiceStatus;
    map['client_msg_no'] = msg.clientMsgNO;
    map['viewed'] = msg.viewed;
    map['viewed_at'] = msg.viewedAt;
    map['topic_id'] = msg.topicID;
    if (msg.messageContent != null) {
      map['searchable_word'] = msg.messageContent!.searchableWord();
    } else {
      map['searchable_word'] = '';
    }
    if (msg.localExtraMap != null) {
      map['extra'] = jsonEncode(msg.localExtraMap);
    } else {
      map['extra'] = '';
    }
    map['setting'] = msg.setting.encode();
    return map;
  }

  dynamic getExtraMap(XOMsgExtra extra) {
    var map = <String, Object>{};
    map['channel_id'] = extra.channelID;
    map['channel_type'] = extra.channelType;
    map['readed'] = extra.readed;
    map['readed_count'] = extra.readedCount;
    map['unread_count'] = extra.unreadCount;
    map['revoke'] = extra.revoke;
    map['revoker'] = extra.revoker;
    map['extra_version'] = extra.extraVersion;
    map['is_mutual_deleted'] = extra.isMutualDeleted;
    map['content_edit'] = extra.contentEdit;
    map['edited_at'] = extra.editedAt;
    map['need_upload'] = extra.needUpload;
    map['message_id'] = extra.messageID;
    return map;
  }
}
