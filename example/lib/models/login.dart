class LoginRsp {
  String? uid;
  String? appId;
  String? name;
  String? username;
  int? sex;
  String? category;
  String? shortNo;
  String? zone;
  String? phone;
  String? token;
  String? chatPwd;
  String? lockScreenPwd;
  int? lockAfterMinute;
  Setting? setting;
  String? rsaPublicKey;
  int? shortStatus;
  int? msgExpireSecond;

  LoginRsp(
      {this.uid,
      this.appId,
      this.name,
      this.username,
      this.sex,
      this.category,
      this.shortNo,
      this.zone,
      this.phone,
      this.token,
      this.chatPwd,
      this.lockScreenPwd,
      this.lockAfterMinute,
      this.setting,
      this.rsaPublicKey,
      this.shortStatus,
      this.msgExpireSecond});

  LoginRsp.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    appId = json['app_id'];
    name = json['name'];
    username = json['username'];
    sex = json['sex'];
    category = json['category'];
    shortNo = json['short_no'];
    zone = json['zone'];
    phone = json['phone'];
    token = json['token'];
    chatPwd = json['chat_pwd'];
    lockScreenPwd = json['lock_screen_pwd'];
    lockAfterMinute = json['lock_after_minute'];
    setting = Setting.fromJson(json['setting'] ?? "{}");
    rsaPublicKey = json['rsa_public_key'];
    shortStatus = json['short_status'];
    msgExpireSecond = json['msg_expire_second'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uid'] = uid;
    data['app_id'] = appId;
    data['name'] = name;
    data['username'] = username;
    data['sex'] = sex;
    data['category'] = category;
    data['short_no'] = shortNo;
    data['zone'] = zone;
    data['phone'] = phone;
    data['token'] = token;
    data['chat_pwd'] = chatPwd;
    data['lock_screen_pwd'] = lockScreenPwd;
    data['lock_after_minute'] = lockAfterMinute;
    if (setting != null) {
      data['setting'] = setting!.toJson();
    }
    data['rsa_public_key'] = rsaPublicKey;
    data['short_status'] = shortStatus;
    data['msg_expire_second'] = msgExpireSecond;
    return data;
  }
}

class Setting {
  int? searchByPhone;
  int? searchByShort;
  int? newMsgNotice;
  int? msgShowDetail;
  int? voiceOn;
  int? shockOn;
  int? offlineProtection;
  int? deviceLock;
  int? muteOfApp;

  Setting(
      {this.searchByPhone,
      this.searchByShort,
      this.newMsgNotice,
      this.msgShowDetail,
      this.voiceOn,
      this.shockOn,
      this.offlineProtection,
      this.deviceLock,
      this.muteOfApp});

  Setting.fromJson(Map<String, dynamic> json) {
    searchByPhone = json['search_by_phone'];
    searchByShort = json['search_by_short'];
    newMsgNotice = json['new_msg_notice'];
    msgShowDetail = json['msg_show_detail'];
    voiceOn = json['voice_on'];
    shockOn = json['shock_on'];
    offlineProtection = json['offline_protection'];
    deviceLock = json['device_lock'];
    muteOfApp = json['mute_of_app'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['search_by_phone'] = searchByPhone;
    data['search_by_short'] = searchByShort;
    data['new_msg_notice'] = newMsgNotice;
    data['msg_show_detail'] = msgShowDetail;
    data['voice_on'] = voiceOn;
    data['shock_on'] = shockOn;
    data['offline_protection'] = offlineProtection;
    data['device_lock'] = deviceLock;
    data['mute_of_app'] = muteOfApp;
    return data;
  }
}
