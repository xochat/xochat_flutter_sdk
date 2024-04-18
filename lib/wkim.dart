import 'package:xochat_flutter_sdk/common/crypto_utils.dart';
import 'package:xochat_flutter_sdk/db/wk_db_helper.dart';
import 'package:xochat_flutter_sdk/manager/channel_manager.dart';
import 'package:xochat_flutter_sdk/manager/channel_member_manager.dart';
import 'package:xochat_flutter_sdk/manager/cmd_manager.dart';
import 'package:xochat_flutter_sdk/manager/conversation_manager.dart';
import 'package:xochat_flutter_sdk/manager/message_manager.dart';
import 'package:xochat_flutter_sdk/manager/reminder_manager.dart';
import 'package:xochat_flutter_sdk/model/wk_image_content.dart';
import 'package:xochat_flutter_sdk/model/wk_text_content.dart';
import 'package:xochat_flutter_sdk/model/wk_video_content.dart';
import 'package:xochat_flutter_sdk/model/wk_voice_content.dart';
import 'package:xochat_flutter_sdk/type/const.dart';

import 'common/options.dart';
import 'manager/connect_manager.dart';
import 'model/wk_card_content.dart';

class XOIM {
  XOIM._privateConstructor();
  int deviceFlagApp = 0;
  static final XOIM _instance = XOIM._privateConstructor();

  static XOIM get shared => _instance;

  Options options = Options();

  Future<bool> setup(Options opts) async {
    options = opts;
    CryptoUtils.init();
    _initNormalMsgContent();
    bool result = await XODBHelper.shared.init();
    if (result) {
      messageManager.updateSendingMsgFail();
    }
    return result;
  }

  _initNormalMsgContent() {
    messageManager.registerMsgContent(WkMessageContentType.text,
        (dynamic data) {
      return XOTextContent('').decodeJson(data);
    });
    messageManager.registerMsgContent(WkMessageContentType.card,
        (dynamic data) {
      return XOCardContent('', '').decodeJson(data);
    });
    messageManager.registerMsgContent(WkMessageContentType.image,
        (dynamic data) {
      return XOImageContent(
        0,
        0,
      ).decodeJson(data);
    });
    messageManager.registerMsgContent(WkMessageContentType.voice,
        (dynamic data) {
      return XOVoiceContent(
        0,
      ).decodeJson(data);
    });
    messageManager.registerMsgContent(WkMessageContentType.video,
        (dynamic data) {
      return XOVideoContent().decodeJson(data);
    });
  }

  void setDeviceFlag(int deviceFlag) {
    deviceFlagApp = deviceFlag;
  }

  XOConnectionManager connectionManager = XOConnectionManager.shared;
  XOMessageManager messageManager = XOMessageManager.shared;
  XOConversationManager conversationManager = XOConversationManager.shared;
  XOChannelManager channelManager = XOChannelManager.shared;
  XOChannelMemberManager channelMemberManager = XOChannelMemberManager.shared;
  XOReminderManager reminderManager = XOReminderManager.shared;
  XOCMDManager cmdManager = XOCMDManager.shared;
}
