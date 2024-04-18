import 'package:xochat_flutter_sdk/type/const.dart';
import 'package:xochat_flutter_sdk/wkim.dart';

import 'channel.dart';
import 'cmd.dart';
import 'msg.dart';
import 'reminder.dart';

class XOConversationMsg {
  //频道id
  String channelID = '';
  //频道类型
  int channelType = XOChannelType.personal;
  //最后一条消息本地ID
  String lastClientMsgNO = '';
  //是否删除
  int isDeleted = 0;
  //服务器同步版本号
  int version = 0;
  //最后一条消息时间
  int lastMsgTimestamp = 0;
  //未读消息数量
  int unreadCount = 0;
  //最后一条消息序号
  int lastMsgSeq = 0;
  //扩展字段
  dynamic localExtraMap;
  XOConversationMsgExtra? msgExtra;
  String parentChannelID = '';
  int parentChannelType = 0;
}

class XOConversationMsgExtra {
  String channelID = '';
  int channelType = 0;
  int browseTo = 0;
  int keepMessageSeq = 0;
  int keepOffsetY = 0;
  String draft = '';
  int version = 0;
  int draftUpdatedAt = 0;
}

class XOUIConversationMsg {
  int lastMsgSeq = 0;
  String clientMsgNo = '';
  //频道ID
  String channelID = '';
  //频道类型
  int channelType = 0;
  //最后一条消息时间
  int lastMsgTimestamp = 0;
  //消息频道
  XOChannel? _wkChannel;
  //消息正文
  XOMsg? _wkMsg;
  //未读消息数量
  int unreadCount = 0;
  int isDeleted = 0;
  XOConversationMsgExtra? _remoteMsgExtra;
  //高亮内容[{type:1,text:'[有人@你]'}]
  List<XOReminder>? _reminderList;
  //扩展字段
  dynamic localExtraMap;
  String parentChannelID = '';
  int parentChannelType = 0;

  Future<XOMsg?> getWkMsg() async {
    _wkMsg ??= await XOIM.shared.messageManager.getWithClientMsgNo(clientMsgNo);
    return _wkMsg;
  }

  void setWkMsg(XOMsg wkMsg) {
    _wkMsg = wkMsg;
  }

  Future<XOChannel?> getWkChannel() async {
    _wkChannel ??=
        await XOIM.shared.channelManager.getChannel(channelID, channelType);
    return _wkChannel;
  }

  void setWkChannel(XOChannel wkChannel) {
    _wkChannel = wkChannel;
  }

  Future<List<XOReminder>?> getReminderList() async {
    _reminderList ??= await XOIM.shared.reminderManager
        .getWithChannel(channelID, channelType, 0);
    return _reminderList;
  }

  void setReminderList(List<XOReminder> list) {
    _reminderList = list;
  }

  XOConversationMsgExtra? getRemoteMsgExtra() {
    return _remoteMsgExtra;
  }

  void setRemoteMsgExtra(XOConversationMsgExtra? extra) {
    _remoteMsgExtra = extra;
  }
}

class XOSyncConversation {
  int cmdVersion = 0;
  List<WkSyncCMD>? cmds;
  String uid = '';
  List<XOSyncConvMsg>? conversations;
}

class XOSyncConvMsg {
  String channelID = '';
  int channelType = 0;
  String lastClientMsgNO = '';
  int lastMsgSeq = 0;
  int offsetMsgSeq = 0;
  int timestamp = 0;
  int unread = 0;
  int version = 0;
  List<XOSyncMsg>? recents;
}
