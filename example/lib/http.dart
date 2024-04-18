import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:example/const.dart';
import 'package:example/models/conversation.dart';
import 'package:example/models/login.dart';
import 'package:xochat_flutter_sdk/entity/conversation.dart';
import 'package:xochat_flutter_sdk/entity/msg.dart';
import 'package:xochat_flutter_sdk/wkim.dart';

class HttpUtils {
  static String apiURL = "http://13.201.220.225:3333/api/v1";

  static Future<int> login(String uid, String token) async {
    final dio = Dio();
    var url = "$apiURL/user/login";
    final response = await dio.post(url, data: {
      'username': uid,
      'password': token,
      'flag': 0,
      'device': {
        "device_id": "1111111",
        "device_name": "小米",
        "device_model": "112"
      }
    });
    var data = LoginRsp.fromJson(response.data);
    XOIM.shared.options.uid = data.uid ?? "";
    XOIM.shared.options.token = data.token ?? "";
    return response.statusCode!;
  }

  static Future<String> getIP() async {
    final dio = Dio();
    String ip = '';
    final response =
        await dio.get('$apiURL/users/${XOIM.shared.options.uid ?? ""}/im');
    if (response.statusCode == HttpStatus.ok) {
      ip = response.data['tcp_addr'];
    }
    return ip;
  }

  static syncConversation(String lastSsgSeqs, int msgCount, int version,
      Function(XOSyncConversation) back) async {
    final dio = Dio();
    final response = await dio.post(
      '$apiURL/conversation/sync',
      data: {
        "uid": UserInfo.uid, // 当前登录用户uid
        "version": version, //  当前客户端的会话最大版本号(从保存的结果里取最大的version，如果本地没有数据则传0)，
        "last_msg_seqs":
            lastSsgSeqs, //   客户端所有频道会话的最后一条消息序列号拼接出来的同步串 格式： channelID:channelType:last_msg_seq|channelID:channelType:last_msg_seq  （此字段非必填，如果不填就获取全量数据，填写了获取增量数据，看你自己的需求。）
        "msg_count": 10 // 每个会话获取最大的消息数量，一般为app点进去第一屏的数据
      },
      options: Options(headers: {"token": UserInfo.token}),
    );
    // print(response.data);
    XOSyncConversation conversation = XOSyncConversation();
    conversation.conversations = [];
    if (response.statusCode == HttpStatus.ok) {
      var data = ConversationRsp.fromJson(response.data);
      for (int i = 0; i < (data.conversations ?? []).length; i++) {
        var json = data.conversations?[i] ?? Conversations();
        XOSyncConvMsg convMsg = XOSyncConvMsg();
        convMsg.channelID = json.channelId ?? "";
        convMsg.channelType = json.channelType ?? 0;
        convMsg.unread = json.unread ?? 0;
        convMsg.timestamp = json.timestamp ?? 0;
        convMsg.lastMsgSeq = json.lastMsgSeq ?? 0;
        convMsg.lastClientMsgNO = json.lastClientMsgNo ?? "";
        convMsg.version = json.version ?? 0;
        var msgListJson = json.recents as List<Recent>;
        List<XOSyncMsg> msgList = [];
        if (msgListJson.isNotEmpty) {
          for (int j = 0; j < msgListJson.length; j++) {
            var msgJson = msgListJson[j];
            msgList.add(getXOSyncMsg(msgJson));
          }
        }

        convMsg.recents = msgList;
        conversation.conversations!.add(convMsg);
      }
    }
    back(conversation);
  }

  static syncChannelMsg(
    String channelID,
    int channelType,
    int startMsgSeq,
    int endMsgSeq,
    int limit,
    int pullMode,
    Function(XOSyncChannelMsg) back,
  ) async {
    final dio = Dio();
    print('同不消息');
    final response = await dio.post(
      '$apiURL/message/channel/sync',
      data: {
        "login_uid": UserInfo.uid, // 当前登录用户uid
        "channel_id": channelID, //  频道ID
        "channel_type": channelType, // 频道类型
        "start_message_seq": startMsgSeq, // 开始消息列号（结果包含start_message_seq的消息）
        "end_message_seq": endMsgSeq, // 结束消息列号（结果不包含end_message_seq的消息）
        "limit": limit, // 消息数量限制
        "pull_mode": pullMode // 拉取模式 0:向下拉取 1:向上拉取
      },
      options: Options(headers: {"token": UserInfo.token}),
    );
    if (response.statusCode == HttpStatus.ok) {
      var data = response.data;
      XOSyncChannelMsg msg = XOSyncChannelMsg();
      msg.startMessageSeq = data['start_message_seq'];
      msg.endMessageSeq = data['end_message_seq'];
      msg.more = data['more'];
      var messages = data['messages'] as List<dynamic>;
      List<XOSyncMsg> msgList = [];
      for (int i = 0; i < messages.length; i++) {
        var json = Recent.fromJson(messages[i] ?? {});
        msgList.add(getXOSyncMsg(json));
      }
      msg.messages = msgList;
      back(msg);
    }
  }

  static XOSyncMsg getXOSyncMsg(Recent json) {
    XOSyncMsg msg = XOSyncMsg();
    msg.channelID = json.channelId ?? "";
    msg.messageID = "${json.messageId ?? 0}";
    msg.channelType = json.channelType ?? 0;
    msg.clientMsgNO = json.clientMsgNo ?? "";
    msg.messageSeq = json.messageSeq ?? 0;
    msg.fromUID = json.fromUid ?? "";
    msg.timestamp = json.timestamp ?? 0;
    //  msg.payload = json['payload'];
    Payload payload = json.payload ?? Payload();
    try {
      msg.payload =
          jsonDecode(utf8.decode(base64Decode(payload.content ?? "")));
      // print('查询的消息${msg.payload}');
    } catch (e) {
      // print('异常了');
    }
    return msg;
  }
}
