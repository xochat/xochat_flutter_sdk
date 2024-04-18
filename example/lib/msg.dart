import 'package:xochat_flutter_sdk/entity/msg.dart';
import 'package:xochat_flutter_sdk/type/const.dart';

import 'const.dart';

class UIMsg {
  XOMsg wkMsg;
  UIMsg(this.wkMsg);

  String getShowContent() {
    if (wkMsg.messageContent == null) {
      return '';
    }
    var readCount = 0;
    if (wkMsg.wkMsgExtra != null) {
      readCount = wkMsg.wkMsgExtra!.readedCount;
    }
    return wkMsg.messageContent!.displayText();
    // return "${wkMsg.messageContent!.displayText()} [是否需要回执：${wkMsg.setting.receipt}]，[已读数量：$readCount]";
  }

  String getShowTime() {
    return CommonUtils.formatDateTime(wkMsg.timestamp);
  }

  String getStatusIV() {
    if (wkMsg.status == XOSendMsgResult.sendLoading) {
      return 'assets/loading.png';
    } else if (wkMsg.status == XOSendMsgResult.sendSuccess) {
      return 'assets/success.png';
    }
    return 'assets/error.png';
  }
}
