import 'dart:convert';

import 'package:xochat_flutter_sdk/entity/channel.dart';
import 'package:xochat_flutter_sdk/entity/channel_member.dart';
import 'package:xochat_flutter_sdk/entity/conversation.dart';
import 'package:xochat_flutter_sdk/entity/msg.dart';
import 'package:xochat_flutter_sdk/entity/reminder.dart';
import 'package:xochat_flutter_sdk/type/const.dart';
import 'package:xochat_flutter_sdk/wkim.dart';

import '../proto/proto.dart';

class XODBConst {
  static const tableMessage = 'message';
  static const tableMessageReaction = 'message_reaction';
  static const tableMessageExtra = 'message_extra';
  static const tableConversation = 'conversation';
  static const tableConversationExtra = 'conversation_extra';
  static const tableChannel = 'channel';
  static const tableChannelMember = 'channel_members';
  static const tableReminders = 'reminders';
  static const tableRobot = 'robot';
  static const tableRobotMenu = 'robot_menu';

  static XOMsg serializeXOMsg(dynamic data) {
    XOMsg msg = XOMsg();
    msg.messageID = readString(data, 'message_id');
    msg.messageSeq = readInt(data, 'message_seq');
    msg.clientSeq = readInt(data, 'client_seq');
    msg.timestamp = readInt(data, 'timestamp');
    msg.fromUID = readString(data, 'from_uid');
    msg.channelID = readString(data, 'channel_id');
    msg.channelType = readInt(data, 'channel_type');
    msg.contentType = readInt(data, 'type');
    msg.content = readString(data, 'content');
    msg.status = readInt(data, 'status');
    msg.voiceStatus = readInt(data, 'voice_status');
    msg.searchableWord = readString(data, 'searchable_word');
    msg.clientMsgNO = readString(data, 'client_msg_no');
    msg.isDeleted = readInt(data, 'is_deleted');
    msg.orderSeq = readInt(data, 'order_seq');
    int setting = readInt(data, 'setting');
    msg.setting = Setting().decode(setting);
    msg.viewed = readInt(data, 'viewed');
    msg.viewedAt = readInt(data, 'viewed_at');
    msg.topicID = readString(data, 'topic_id');
    // 扩展表数据
    msg.wkMsgExtra = serializeMsgExtra(data);

    String extra = readString(data, 'extra');
    if (extra != '') {
      msg.localExtraMap = jsonEncode(extra);
    }
    if (msg.content != '') {
      dynamic contentJson = jsonDecode(msg.content);
      msg.messageContent = XOIM.shared.messageManager
          .getMessageModel(msg.contentType, contentJson);
    }
    if (msg.wkMsgExtra!.contentEdit != '') {
      dynamic json = jsonDecode(msg.wkMsgExtra!.contentEdit);
      msg.wkMsgExtra!.messageContent = XOIM.shared.messageManager
          .getMessageModel(WkMessageContentType.text, json);
    }

    return msg;
  }

  static XOMsgExtra serializeMsgExtra(dynamic data) {
    XOMsgExtra extra = XOMsgExtra();
    extra.messageID = readString(data, 'message_id');
    extra.channelID = readString(data, 'channel_id');
    extra.channelType = readInt(data, 'channel_type');
    extra.readed = readInt(data, 'readed');
    extra.readedCount = readInt(data, 'readed_count');
    extra.unreadCount = readInt(data, 'unread_count');
    extra.revoke = readInt(data, 'revoke');
    extra.isMutualDeleted = readInt(data, 'is_mutual_deleted');
    extra.revoker = readString(data, 'revoker');
    extra.extraVersion = readInt(data, 'extra_version');
    extra.editedAt = readInt(data, 'edited_at');
    extra.contentEdit = readString(data, 'content_edit');
    extra.needUpload = readInt(data, 'need_upload');
    return extra;
  }

  static XOMsgReaction serializeMsgReation(dynamic data) {
    XOMsgReaction reaction = XOMsgReaction();
    reaction.channelID = readString(data, 'channel_id');
    reaction.channelType = readInt(data, 'channel_type');
    reaction.isDeleted = readInt(data, 'is_deleted');
    reaction.uid = readString(data, 'uid');
    reaction.name = readString(data, 'name');
    reaction.messageID = readString(data, 'message_id');
    reaction.createdAt = readString(data, 'created_at');
    reaction.seq = readInt(data, 'seq');
    reaction.emoji = readString(data, 'emoji');
    return reaction;
  }

  static XOConversationMsg serializeCoversation(dynamic data) {
    XOConversationMsg msg = XOConversationMsg();
    msg.channelID = readString(data, 'channel_id');
    msg.channelType = readInt(data, 'channel_type');
    msg.lastMsgTimestamp = readInt(data, 'last_msg_timestamp');
    msg.unreadCount = readInt(data, 'unread_count');
    msg.isDeleted = readInt(data, 'is_deleted');
    msg.version = readInt(data, 'version');
    msg.lastClientMsgNO = readString(data, 'last_client_msg_no');
    msg.lastMsgSeq = readInt(data, 'last_msg_seq');
    msg.parentChannelID = readString(data, 'parent_channel_id');
    msg.parentChannelType = readInt(data, 'parent_channel_type');
    String extra = readString(data, 'extra');
    if (extra != '') {
      msg.localExtraMap = jsonDecode(extra);
    }
    msg.msgExtra = serializeConversationExtra(data);
    return msg;
  }

  static XOConversationMsgExtra serializeConversationExtra(dynamic data) {
    XOConversationMsgExtra extra = XOConversationMsgExtra();
    extra.channelID = readString(data, 'channel_id');
    extra.channelType = readInt(data, 'channel_type');
    extra.keepMessageSeq = readInt(data, 'keep_message_seq');
    extra.keepOffsetY = readInt(data, 'keep_offset_y');
    extra.draft = readString(data, 'draft');
    extra.browseTo = readInt(data, 'browse_to');
    extra.draftUpdatedAt = readInt(data, 'draft_updated_at');
    extra.version = readInt(data, 'version');
    if (data['extra_version'] != null) {
      extra.version = readInt(data, 'extra_version');
    }
    return extra;
  }

  static XOChannel serializeChannel(dynamic data) {
    String channelID = readString(data, 'channel_id');
    int channelType = readInt(data, 'channel_type');
    XOChannel channel = XOChannel(channelID, channelType);
    channel.channelName = readString(data, 'channel_name');
    channel.channelRemark = readString(data, 'channel_remark');
    channel.showNick = readInt(data, 'show_nick');
    channel.top = readInt(data, 'top');
    channel.mute = readInt(data, 'mute');
    channel.isDeleted = readInt(data, 'is_deleted');
    channel.forbidden = readInt(data, 'forbidden');
    channel.status = readInt(data, 'status');
    channel.follow = readInt(data, 'follow');
    channel.invite = readInt(data, 'invite');
    channel.version = readInt(data, 'version');
    channel.avatar = readString(data, 'avatar');
    channel.online = readInt(data, 'online');
    channel.lastOffline = readInt(data, 'last_offline');
    channel.category = readString(data, 'category');
    channel.receipt = readInt(data, 'receipt');
    channel.robot = readInt(data, 'robot');
    channel.username = readString(data, 'username');
    channel.avatarCacheKey = readString(data, 'avatar_cache_key');
    channel.deviceFlag = readInt(data, 'device_flag');
    channel.parentChannelID = readString(data, 'parent_channel_id');
    channel.parentChannelType = readInt(data, 'parent_channel_type');
    channel.createdAt = readString(data, 'created_at');
    channel.updatedAt = readString(data, 'updated_at');
    String remoteExtra = readString(data, 'remote_extra');
    if (remoteExtra != '') {
      channel.remoteExtraMap = jsonDecode(remoteExtra);
    }
    String localExtra = readString(data, 'extra');
    if (remoteExtra != '') {
      channel.localExtra = jsonDecode(localExtra);
    }
    return channel;
  }

  static XOChannelMember serializeChannelMember(dynamic data) {
    XOChannelMember member = XOChannelMember();
    member.status = readInt(data, 'status');
    member.channelID = readString(data, 'channel_id');
    member.channelType = readInt(data, 'channel_type');
    member.memberUID = readString(data, 'member_uid');
    member.memberName = readString(data, 'member_name');
    member.memberAvatar = readString(data, 'member_avatar');
    member.memberRemark = readString(data, 'member_remark');
    member.role = readInt(data, 'role');
    member.isDeleted = readInt(data, 'is_deleted');
    member.version = readInt(data, 'version');
    member.createdAt = readString(data, 'created_at');
    member.updatedAt = readString(data, 'updated_at');
    member.memberInviteUID = readString(data, 'member_invite_uid');
    member.robot = readInt(data, 'robot');
    member.forbiddenExpirationTime = readInt(data, 'forbidden_expiration_time');
    String channelName = readString(data, 'channel_name');
    if (channelName != '') {
      member.memberName = channelName;
    }
    member.remark = readString(data, 'channel_remark');
    String channelAvatar = readString(data, 'avatar');
    if (channelAvatar != '') {
      member.memberAvatar = channelAvatar;
    }
    String avatarCache = readString(data, 'avatar_cache_key');
    if (avatarCache != '') {
      member.memberAvatarCacheKey = avatarCache;
    } else {
      member.memberAvatarCacheKey = readString(data, 'member_avatar_cache_key');
    }
    String extra = readString(data, 'extra');
    if (extra != '') {
      member.extraMap = jsonDecode(extra);
    }

    return member;
  }

  static XOReminder serializeReminder(dynamic data) {
    XOReminder reminder = XOReminder();
    reminder.type = readInt(data, 'type');
    reminder.reminderID = readInt(data, 'reminder_id');
    reminder.messageID = readString(data, 'message_id');
    reminder.messageSeq = readInt(data, 'message_seq');
    reminder.isLocate = readInt(data, 'is_locate');
    reminder.channelID = readString(data, 'channel_id');
    reminder.channelType = readInt(data, 'channel_type');
    reminder.text = readString(data, 'text');
    reminder.version = readInt(data, 'version');
    reminder.done = readInt(data, 'done');
    String data1 = readString(data, 'data');
    reminder.needUpload = readInt(data, 'needUpload');
    reminder.publisher = readString(data, 'publisher');
    if (data1 != '') {
      reminder.data = jsonDecode(data1);
    }
    return reminder;
  }

  static int readInt(dynamic data, String key) {
    dynamic result = data[key];
    if (result == Null || result == null) {
      return 0;
    }
    return result as int;
  }

  static String readString(dynamic data, String key) {
    dynamic result = data[key];
    if (result == Null || result == null) {
      return '';
    }
    return result.toString();
  }

  static String getPlaceholders(int count) {
    StringBuffer placeholders = StringBuffer();
    for (int i = 0; i < count; i++) {
      if (i != 0) {
        placeholders.write(", ");
      }
      placeholders.write("?");
    }
    return placeholders.toString();
  }
}
