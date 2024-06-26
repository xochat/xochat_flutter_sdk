import 'dart:collection';

import 'package:xochat_flutter_sdk/db/message.dart';
import 'package:xochat_flutter_sdk/db/reaction.dart';
import 'package:xochat_flutter_sdk/entity/msg.dart';
import 'package:xochat_flutter_sdk/wkim.dart';

import '../db/conversation.dart';
import '../entity/conversation.dart';
import '../type/const.dart';

class XOConversationManager {
  XOConversationManager._privateConstructor();
  static final XOConversationManager _instance =
      XOConversationManager._privateConstructor();
  static XOConversationManager get shared => _instance;

  HashMap<String, Function(XOUIConversationMsg, bool)>? _refeshMsgMap;
  HashMap<String, Function(String, int)>? _deleteMsgMap;

  Function(String lastSsgSeqs, int msgCount, int version,
      Function(XOSyncConversation))? _syncConersationBack;

  Future<List<XOUIConversationMsg>> getAll() async {
    return await ConversationDB.shared.queryAll();
  }

  Future<bool> deleteMsg(String channelID, int channelType) async {
    bool result = await ConversationDB.shared.delete(channelID, channelType);
    if (result) {
      _setDeleteMsg(channelID, channelType);
    }

    return result;
  }

  Future<XOUIConversationMsg?> saveWithLiMMsg(XOMsg msg) async {
    XOConversationMsg wkConversationMsg = XOConversationMsg();
    if (msg.channelType == XOChannelType.communityTopic &&
        msg.channelID != '') {
      if (msg.channelID.contains("@")) {
        var str = msg.channelID.split("@");
        wkConversationMsg.parentChannelID = str[0];
        wkConversationMsg.parentChannelType = XOChannelType.community;
      }
    }
    wkConversationMsg.channelID = msg.channelID;
    wkConversationMsg.channelType = msg.channelType;
    wkConversationMsg.localExtraMap = msg.localExtraMap;
    wkConversationMsg.lastMsgTimestamp = msg.timestamp;
    wkConversationMsg.lastClientMsgNO = msg.clientMsgNO;
    wkConversationMsg.lastMsgSeq = msg.messageSeq;
    wkConversationMsg.unreadCount = msg.header.redDot ? 1 : 0;
    XOUIConversationMsg? uiMsg = await ConversationDB.shared
        .insertOrUpdateWithConvMsg(wkConversationMsg);
    return uiMsg;
  }

  Future<int> getExtraMaxVersion() async {
    return ConversationDB.shared.queryExtraMaxVersion();
  }

  Future<XOUIConversationMsg?> getWithChannel(
      String channelID, int channelType) async {
    var msg = await ConversationDB.shared
        .queryMsgByMsgChannelId(channelID, channelType);
    if (msg != null) {
      return ConversationDB.shared.getUIMsg(msg);
    }
    return null;
  }

  clearAll() {
    ConversationDB.shared.clearAll();
  }

  updateRedDot(String channelID, int channelType, int redDot) async {
    var map = <String, Object>{};
    map['unread_count'] = redDot;
    var result = await ConversationDB.shared
        .updateWithField(map, channelID, channelType);
    if (result > 0) {
      _refreshMsg(channelID, channelType);
    }
  }

  _refreshMsg(String channelID, int channelType) async {
    var msg = await ConversationDB.shared
        .queryMsgByMsgChannelId(channelID, channelType);
    if (msg != null) {
      var uiMsg = ConversationDB.shared.getUIMsg(msg);
      setRefreshMsg(uiMsg, true);
    }
  }

  addOnDeleteMsgListener(String key, Function(String, int) back) {
    _deleteMsgMap ??= HashMap();
    _deleteMsgMap![key] = back;
  }

  removeDeleteMsgListener(String key) {
    if (_deleteMsgMap != null) {
      _deleteMsgMap!.remove(key);
    }
  }

  _setDeleteMsg(String channelID, int channelType) {
    if (_deleteMsgMap != null) {
      _deleteMsgMap!.forEach((key, back) {
        back(channelID, channelType);
      });
    }
  }

  setRefreshMsg(XOUIConversationMsg msg, bool isEnd) {
    if (_refeshMsgMap != null) {
      _refeshMsgMap!.forEach((key, back) {
        back(msg, isEnd);
      });
    }
  }

  addOnRefreshMsgListener(
      String key, Function(XOUIConversationMsg, bool) back) {
    _refeshMsgMap ??= HashMap();
    _refeshMsgMap![key] = back;
  }

  removeOnRefreshMsg(String key) {
    if (_refeshMsgMap != null) {
      _refeshMsgMap!.remove(key);
    }
  }

  addOnSyncConversationListener(
    Function(
      String lastSsgSeqs,
      int msgCount,
      int version,
      Function(XOSyncConversation),
    ) back,
  ) {
    _syncConersationBack = back;
  }

  setSyncConversation(Function() back) async {
    XOIM.shared.connectionManager
        .setConnectionStatus(XOConnectStatus.syncMsg, 'sync_conversation_msgs');
    if (_syncConersationBack != null) {
      int version = await ConversationDB.shared.getMaxVersion();
      String lastMsgSeqStr = await ConversationDB.shared.getLastMsgSeqs();
      _syncConersationBack!(lastMsgSeqStr, 200, version, (msgs) {
        _saveSyncCoversation(msgs);
        back();
      });
    }
  }

  _saveSyncCoversation(XOSyncConversation? syncChat) {
    if (syncChat == null ||
        syncChat.conversations == null ||
        syncChat.conversations!.isEmpty) {
      return;
    }
    List<XOConversationMsg> conversationMsgList = [];
    List<XOMsg> msgList = [];
    List<XOMsgReaction> msgReactionList = [];
    List<XOMsgExtra> msgExtraList = [];
    List<XOUIConversationMsg> uiMsgList = [];
    if (syncChat.conversations != null && syncChat.conversations!.isNotEmpty) {
      for (int i = 0, size = syncChat.conversations!.length; i < size; i++) {
        XOConversationMsg conversationMsg = XOConversationMsg();

        int channelType = syncChat.conversations![i].channelType;
        String channelID = syncChat.conversations![i].channelID;
        if (channelType == XOChannelType.communityTopic) {
          var str = channelID.split("@");
          conversationMsg.parentChannelID = str[0];
          conversationMsg.parentChannelType = XOChannelType.community;
        }
        conversationMsg.channelID = syncChat.conversations![i].channelID;
        conversationMsg.channelType = syncChat.conversations![i].channelType;
        conversationMsg.lastMsgSeq = syncChat.conversations![i].lastMsgSeq;
        conversationMsg.lastClientMsgNO =
            syncChat.conversations![i].lastClientMsgNO;
        conversationMsg.lastMsgTimestamp = syncChat.conversations![i].timestamp;
        conversationMsg.unreadCount = syncChat.conversations![i].unread;
        conversationMsg.version = syncChat.conversations![i].version;
        XOUIConversationMsg uiMsg =
            ConversationDB.shared.getUIMsg(conversationMsg);
        //聊天消息对象
        if (syncChat.conversations![i].recents != null &&
            syncChat.conversations![i].recents!.isNotEmpty) {
          for (XOSyncMsg wkSyncRecent in syncChat.conversations![i].recents!) {
            XOMsg msg = wkSyncRecent.getXOMsg();
            if (msg.reactionList != null && msg.reactionList!.isNotEmpty) {
              msgReactionList.addAll(msg.reactionList!);
            }
            //判断会话列表的fromUID
            if (conversationMsg.lastClientMsgNO == msg.clientMsgNO) {
              conversationMsg.isDeleted = msg.isDeleted;
              uiMsg.isDeleted = conversationMsg.isDeleted;
              uiMsg.setWkMsg(msg);
            }
            if (wkSyncRecent.messageExtra != null) {
              XOMsgExtra extra = XOIM.shared.messageManager
                  .wkSyncExtraMsg2XOMsgExtra(msg.channelID, msg.channelType,
                      wkSyncRecent.messageExtra!);
              msgExtraList.add(extra);
            }
            msgList.add(msg);
          }
        }
        conversationMsgList.add(conversationMsg);
        uiMsgList.add(uiMsg);
      }
    }
    if (msgExtraList.isNotEmpty) {
      MessageDB.shared.insertOrUpdateMsgExtras(msgExtraList);
    }

    if (msgList.isNotEmpty) {
      MessageDB.shared.insertMsgList(msgList);
    }
    if (conversationMsgList.isNotEmpty) {
      ConversationDB.shared.insertMsgList(conversationMsgList);
    }
    if (msgReactionList.isNotEmpty) {
      ReactionDB.shared.insertOrUpdateReactionList(msgReactionList);
    }
    if (msgList.isNotEmpty && msgList.length < 20) {
      msgList.sort((a, b) => a.messageSeq.compareTo(b.messageSeq));
      XOIM.shared.messageManager.pushNewMsg(msgList);
    }
    if (uiMsgList.isNotEmpty) {
      for (int i = 0, size = uiMsgList.length; i < size; i++) {
        XOIM.shared.conversationManager
            .setRefreshMsg(uiMsgList[i], i == uiMsgList.length - 1);
      }
    }
    if (syncChat.cmds != null && syncChat.cmds!.isNotEmpty) {
      for (int i = 0, size = syncChat.cmds!.length; i < size; i++) {
        dynamic json = <String, dynamic>{};
        json['cmd'] = syncChat.cmds![i].cmd;
        json['param'] = syncChat.cmds![i].param;
        XOIM.shared.cmdManager.handleCMD(json);
      }
    }
  }
}
