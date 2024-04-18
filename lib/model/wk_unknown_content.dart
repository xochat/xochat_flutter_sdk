import 'package:xochat_flutter_sdk/model/wk_message_content.dart';
import 'package:xochat_flutter_sdk/type/const.dart';

class XOUnknownContent extends XOMessageContent {
  XOUnknownContent() {
    contentType = WkMessageContentType.unknown;
  }
  @override
  String displayText() {
    return '[未知消息]';
  }
}
