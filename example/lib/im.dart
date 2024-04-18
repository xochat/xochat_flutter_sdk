import 'package:example/const.dart';
import 'package:xochat_flutter_sdk/common/options.dart';
import 'package:xochat_flutter_sdk/entity/channel.dart';
import 'package:xochat_flutter_sdk/model/wk_image_content.dart';
import 'package:xochat_flutter_sdk/model/wk_video_content.dart';
import 'package:xochat_flutter_sdk/model/wk_voice_content.dart';
import 'package:xochat_flutter_sdk/type/const.dart';
import 'package:xochat_flutter_sdk/wkim.dart';

import 'custom_message.dart';
import 'http.dart';

class IMUtils {
  static Future<bool> initIM() async {
    bool result = await XOIM.shared.setup(Options.newDefault(
      UserInfo.uid,
      UserInfo.token,
    ));
    XOIM.shared.options.getAddr = (Function(String address) complete) async {
      String ip = await HttpUtils.getIP();
      complete(ip);
    };
    if (result) {
      XOIM.shared.connectionManager.connect(socketType: "tcp");
      initListener();
    }
    // 注册自定义消息
    XOIM.shared.messageManager
        .registerMsgContent(12, (data) => CustomMsg("").decodeJson(data));
    return result;
  }

  static initListener() {
    var imgs = [
      "https://lmg.jj20.com/up/allimg/tx29/06052048151752929.png",
      "https://pic.imeitou.com/uploads/allimg/2021061715/aqg1wx3nsds.jpg",
      "https://lmg.jj20.com/up/allimg/tx30/10121138219844229.jpg",
      "https://lmg.jj20.com/up/allimg/tx30/10121138219844229.jpg",
      "https://lmg.jj20.com/up/allimg/tx28/430423183653303.jpg",
      "https://lmg.jj20.com/up/allimg/tx23/520420024834916.jpg",
      "https://himg.bdimg.com/sys/portraitn/item/public.1.a535a65d.tJe8MgWmP8zJ456B73Kzfg",
      "https://images.liqucn.com/img/h23/h07/img_localize_cb7b78b88d5b33e2ce8921221bf3deae_400x400.png",
      "https://img1.baidu.com/it/u=3916753633,2634890492&fm=253&fmt=auto&app=138&f=JPEG?w=400&h=400",
      "https://img0.baidu.com/it/u=4210586523,443489101&fm=253&fmt=auto&app=138&f=JPEG?w=304&h=304",
      "https://img2.baidu.com/it/u=2559320899,1546883787&fm=253&fmt=auto&app=138&f=JPEG?w=441&h=499",
      "https://img0.baidu.com/it/u=2952429745,3806929819&fm=253&fmt=auto&app=138&f=JPEG?w=380&h=380",
      "https://img2.baidu.com/it/u=3783923022,668713258&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=500",
    ];

    XOIM.shared.messageManager.addOnSyncChannelMsgListener((
      channelID,
      channelType,
      startMessageSeq,
      endMessageSeq,
      limit,
      pullMode,
      back,
    ) {
      // 同步某个频道的消息
      HttpUtils.syncChannelMsg(
        channelID,
        channelType,
        startMessageSeq,
        endMessageSeq,
        limit,
        pullMode,
        (p0) => back(p0),
      );
    });
    // 获取channel资料
    XOIM.shared.channelManager
        .addOnGetChannelListener((channelId, channelType, back) {
      print('获取channel资料');
      if (channelType == XOChannelType.personal) {
        // 获取个人资料
        // 这里直接返回了。实际情况可通过API请求后返回
        var channel = XOChannel(channelId, channelType);
        channel.channelName = "单聊${channel.channelID.hashCode}";
        var index = channel.channelID.hashCode % imgs.length;
        channel.avatar = imgs[index];
        back(channel);
      } else if (channelType == XOChannelType.group) {
        // 获取群资料
        var channel = XOChannel(channelId, channelType);
        channel.channelName = "群聊${channel.channelID.hashCode}";
        var index = channel.channelID.hashCode % imgs.length;
        channel.avatar = imgs[index];
        back(channel);
      }
    });
    // 监听同步最近会话
    XOIM.shared.conversationManager.addOnSyncConversationListener((
      lastSsgSeqs,
      msgCount,
      version,
      back,
    ) {
      HttpUtils.syncConversation(lastSsgSeqs, msgCount, version, back);
    });
    // 监听上传消息附件
    XOIM.shared.messageManager.addOnUploadAttachmentListener((wkMsg, back) {
      if (wkMsg.contentType == WkMessageContentType.image) {
        // todo 上传附件
        XOImageContent imageContent = wkMsg.messageContent! as XOImageContent;
        imageContent.url = 'xxxxxx';
        wkMsg.messageContent = imageContent;
        back(true, wkMsg);
      }
      if (wkMsg.contentType == WkMessageContentType.voice) {
        // todo 上传语音
        XOVoiceContent voiceContent = wkMsg.messageContent! as XOVoiceContent;
        voiceContent.url = 'xxxxxx';
        wkMsg.messageContent = voiceContent;
        back(true, wkMsg);
      } else if (wkMsg.contentType == WkMessageContentType.video) {
        XOVideoContent videoContent = wkMsg.messageContent! as XOVideoContent;
        // todo 上传封面及视频
        videoContent.cover = 'xxxxxx';
        videoContent.url = 'ssssss';
        wkMsg.messageContent = videoContent;
        back(true, wkMsg);
      }
    });
  }
}
