class ConversationRsp {
  String? uid;
  List<Conversations>? conversations;
  List<User>? users;
  List<Group>? groups;

  ConversationRsp({this.uid, this.conversations, this.users, this.groups});

  ConversationRsp.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    if (json['conversations'] != null) {
      conversations = <Conversations>[];
      json['conversations'].forEach((v) {
        conversations!.add(Conversations.fromJson(v));
      });
    }
    if (json['users'] != null) {
      users = <User>[];
      json['users'].forEach((v) {
        users!.add(User.fromJson(v));
      });
    }
    if (json['groups'] != null) {
      groups = <Group>[];
      json['groups'].forEach((v) {
        groups!.add(Group.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uid'] = uid;
    if (conversations != null) {
      data['conversations'] = conversations!.map((v) => v.toJson()).toList();
    }
    if (users != null) {
      data['users'] = users!.map((v) => v.toJson()).toList();
    }
    if (groups != null) {
      data['groups'] = groups!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Conversations {
  String? channelId;
  int? channelType;
  int? unread;
  int? timestamp;
  int? lastMsgSeq;
  String? lastClientMsgNo;
  int? offsetMsgSeq;
  int? version;
  List<Recent>? recents;
  Extra? extra;

  Conversations(
      {this.channelId,
      this.channelType,
      this.unread,
      this.timestamp,
      this.lastMsgSeq,
      this.lastClientMsgNo,
      this.offsetMsgSeq,
      this.version,
      this.recents,
      this.extra});

  Conversations.fromJson(Map<String, dynamic> json) {
    channelId = json['channel_id'];
    channelType = json['channel_type'];
    unread = json['unread'];
    timestamp = json['timestamp'];
    lastMsgSeq = json['last_msg_seq'];
    lastClientMsgNo = json['last_client_msg_no'];
    offsetMsgSeq = json['offset_msg_seq'];
    version = json['version'];
    if (json['recents'] != null) {
      recents = <Recent>[];
      json['recents'].forEach((v) {
        recents!.add(Recent.fromJson(v));
      });
    }
    extra = json['extra'] != null ? Extra.fromJson(json['extra']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['channel_id'] = channelId;
    data['channel_type'] = channelType;
    data['unread'] = unread;
    data['timestamp'] = timestamp;
    data['last_msg_seq'] = lastMsgSeq;
    data['last_client_msg_no'] = lastClientMsgNo;
    data['offset_msg_seq'] = offsetMsgSeq;
    data['version'] = version;
    if (recents != null) {
      data['recents'] = recents!.map((v) => v.toJson()).toList();
    }
    if (extra != null) {
      data['extra'] = extra!.toJson();
    }
    return data;
  }
}

class Recent {
  Header? header;
  int? setting;
  int? messageId;
  String? messageIdstr;
  int? messageSeq;
  String? clientMsgNo;
  String? fromUid;
  String? channelId;
  int? channelType;
  int? timestamp;
  Payload? payload;
  String? signalPayload;
  int? isDeleted;
  int? readed;
  int? extraVersion;

  Recent(
      {this.header,
      this.setting,
      this.messageId,
      this.messageIdstr,
      this.messageSeq,
      this.clientMsgNo,
      this.fromUid,
      this.channelId,
      this.channelType,
      this.timestamp,
      this.payload,
      this.signalPayload,
      this.isDeleted,
      this.readed,
      this.extraVersion});

  Recent.fromJson(Map<String, dynamic> json) {
    header = json['header'] != null ? Header.fromJson(json['header']) : null;
    setting = json['setting'];
    messageId = json['message_id'];
    messageIdstr = json['message_idstr'];
    messageSeq = json['message_seq'];
    clientMsgNo = json['client_msg_no'];
    fromUid = json['from_uid'];
    channelId = json['channel_id'];
    channelType = json['channel_type'];
    timestamp = json['timestamp'];
    payload = Payload.fromJson(json['payload'] ?? {});
    signalPayload = json['signal_payload'];
    isDeleted = json['is_deleted'];
    readed = json['readed'];
    extraVersion = json['extra_version'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (header != null) {
      data['header'] = header!.toJson();
    }
    data['setting'] = setting;
    data['message_id'] = messageId;
    data['message_idstr'] = messageIdstr;
    data['message_seq'] = messageSeq;
    data['client_msg_no'] = clientMsgNo;
    data['from_uid'] = fromUid;
    data['channel_id'] = channelId;
    data['channel_type'] = channelType;
    data['timestamp'] = timestamp;
    if (payload != null) {
      data['payload'] = payload;
    }
    data['signal_payload'] = signalPayload;
    data['is_deleted'] = isDeleted;
    data['readed'] = readed;
    data['extra_version'] = extraVersion;
    return data;
  }
}

class Header {
  int? noPersist;
  int? redDot;
  int? syncOnce;

  Header({this.noPersist, this.redDot, this.syncOnce});

  Header.fromJson(Map<String, dynamic> json) {
    noPersist = json['no_persist'];
    redDot = json['red_dot'];
    syncOnce = json['sync_once'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['no_persist'] = noPersist;
    data['red_dot'] = redDot;
    data['sync_once'] = syncOnce;
    return data;
  }
}

class Payload {
  String? content;
  int? type;

  Payload({this.content, this.type});

  Payload.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['content'] = content;
    data['type'] = type;
    return data;
  }
}

class Extra {
  String? channelId;
  int? channelType;
  int? browseTo;
  int? keepMessageSeq;
  int? keepOffsetY;
  String? draft;
  int? version;

  Extra(
      {this.channelId,
      this.channelType,
      this.browseTo,
      this.keepMessageSeq,
      this.keepOffsetY,
      this.draft,
      this.version});

  Extra.fromJson(Map<String, dynamic> json) {
    channelId = json['channel_id'];
    channelType = json['channel_type'];
    browseTo = json['browse_to'];
    keepMessageSeq = json['keep_message_seq'];
    keepOffsetY = json['keep_offset_y'];
    draft = json['draft'];
    version = json['version'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['channel_id'] = channelId;
    data['channel_type'] = channelType;
    data['browse_to'] = browseTo;
    data['keep_message_seq'] = keepMessageSeq;
    data['keep_offset_y'] = keepOffsetY;
    data['draft'] = draft;
    data['version'] = version;
    return data;
  }
}

class User {
  String? uid;
  String? name;
  String? username;
  int? mute;
  int? top;
  int? sex;
  String? category;
  String? shortNo;
  int? chatPwdOn;
  int? screenshot;
  int? revokeRemind;
  int? receipt;
  int? online;
  int? lastOffline;
  int? deviceFlag;
  int? follow;
  int? beDeleted;
  int? beBlacklist;
  String? code;
  String? vercode;
  String? sourceDesc;
  String? remark;
  int? isUploadAvatar;
  int? status;
  int? robot;
  int? isDestroy;
  int? flame;
  int? flameSecond;

  User(
      {this.uid,
      this.name,
      this.username,
      this.mute,
      this.top,
      this.sex,
      this.category,
      this.shortNo,
      this.chatPwdOn,
      this.screenshot,
      this.revokeRemind,
      this.receipt,
      this.online,
      this.lastOffline,
      this.deviceFlag,
      this.follow,
      this.beDeleted,
      this.beBlacklist,
      this.code,
      this.vercode,
      this.sourceDesc,
      this.remark,
      this.isUploadAvatar,
      this.status,
      this.robot,
      this.isDestroy,
      this.flame,
      this.flameSecond});

  User.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    name = json['name'];
    username = json['username'];
    mute = json['mute'];
    top = json['top'];
    sex = json['sex'];
    category = json['category'];
    shortNo = json['short_no'];
    chatPwdOn = json['chat_pwd_on'];
    screenshot = json['screenshot'];
    revokeRemind = json['revoke_remind'];
    receipt = json['receipt'];
    online = json['online'];
    lastOffline = json['last_offline'];
    deviceFlag = json['device_flag'];
    follow = json['follow'];
    beDeleted = json['be_deleted'];
    beBlacklist = json['be_blacklist'];
    code = json['code'];
    vercode = json['vercode'];
    sourceDesc = json['source_desc'];
    remark = json['remark'];
    isUploadAvatar = json['is_upload_avatar'];
    status = json['status'];
    robot = json['robot'];
    isDestroy = json['is_destroy'];
    flame = json['flame'];
    flameSecond = json['flame_second'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uid'] = uid;
    data['name'] = name;
    data['username'] = username;
    data['mute'] = mute;
    data['top'] = top;
    data['sex'] = sex;
    data['category'] = category;
    data['short_no'] = shortNo;
    data['chat_pwd_on'] = chatPwdOn;
    data['screenshot'] = screenshot;
    data['revoke_remind'] = revokeRemind;
    data['receipt'] = receipt;
    data['online'] = online;
    data['last_offline'] = lastOffline;
    data['device_flag'] = deviceFlag;
    data['follow'] = follow;
    data['be_deleted'] = beDeleted;
    data['be_blacklist'] = beBlacklist;
    data['code'] = code;
    data['vercode'] = vercode;
    data['source_desc'] = sourceDesc;
    data['remark'] = remark;
    data['is_upload_avatar'] = isUploadAvatar;
    data['status'] = status;
    data['robot'] = robot;
    data['is_destroy'] = isDestroy;
    data['flame'] = flame;
    data['flame_second'] = flameSecond;
    return data;
  }
}

class Group {
  String? groupNo;
  int? groupType;
  String? category;
  String? name;
  String? remark;
  String? notice;
  int? mute;
  int? top;
  int? showNick;
  int? save;
  int? forbidden;
  int? invite;
  int? chatPwdOn;
  int? screenshot;
  int? revokeRemind;
  int? joinGroupRemind;
  int? forbiddenAddFriend;
  int? status;
  int? receipt;
  int? flame;
  int? flameSecond;
  int? allowViewHistoryMsg;
  int? memberCount;
  int? onlineCount;
  int? quit;
  int? role;
  int? forbiddenExpirTime;
  String? createdAt;
  String? updatedAt;
  int? version;

  Group(
      {this.groupNo,
      this.groupType,
      this.category,
      this.name,
      this.remark,
      this.notice,
      this.mute,
      this.top,
      this.showNick,
      this.save,
      this.forbidden,
      this.invite,
      this.chatPwdOn,
      this.screenshot,
      this.revokeRemind,
      this.joinGroupRemind,
      this.forbiddenAddFriend,
      this.status,
      this.receipt,
      this.flame,
      this.flameSecond,
      this.allowViewHistoryMsg,
      this.memberCount,
      this.onlineCount,
      this.quit,
      this.role,
      this.forbiddenExpirTime,
      this.createdAt,
      this.updatedAt,
      this.version});

  Group.fromJson(Map<String, dynamic> json) {
    groupNo = json['group_no'];
    groupType = json['group_type'];
    category = json['category'];
    name = json['name'];
    remark = json['remark'];
    notice = json['notice'];
    mute = json['mute'];
    top = json['top'];
    showNick = json['show_nick'];
    save = json['save'];
    forbidden = json['forbidden'];
    invite = json['invite'];
    chatPwdOn = json['chat_pwd_on'];
    screenshot = json['screenshot'];
    revokeRemind = json['revoke_remind'];
    joinGroupRemind = json['join_group_remind'];
    forbiddenAddFriend = json['forbidden_add_friend'];
    status = json['status'];
    receipt = json['receipt'];
    flame = json['flame'];
    flameSecond = json['flame_second'];
    allowViewHistoryMsg = json['allow_view_history_msg'];
    memberCount = json['member_count'];
    onlineCount = json['online_count'];
    quit = json['quit'];
    role = json['role'];
    forbiddenExpirTime = json['forbidden_expir_time'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    version = json['version'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['group_no'] = groupNo;
    data['group_type'] = groupType;
    data['category'] = category;
    data['name'] = name;
    data['remark'] = remark;
    data['notice'] = notice;
    data['mute'] = mute;
    data['top'] = top;
    data['show_nick'] = showNick;
    data['save'] = save;
    data['forbidden'] = forbidden;
    data['invite'] = invite;
    data['chat_pwd_on'] = chatPwdOn;
    data['screenshot'] = screenshot;
    data['revoke_remind'] = revokeRemind;
    data['join_group_remind'] = joinGroupRemind;
    data['forbidden_add_friend'] = forbiddenAddFriend;
    data['status'] = status;
    data['receipt'] = receipt;
    data['flame'] = flame;
    data['flame_second'] = flameSecond;
    data['allow_view_history_msg'] = allowViewHistoryMsg;
    data['member_count'] = memberCount;
    data['online_count'] = onlineCount;
    data['quit'] = quit;
    data['role'] = role;
    data['forbidden_expir_time'] = forbiddenExpirTime;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['version'] = version;
    return data;
  }
}
