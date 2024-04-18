import 'package:xochat_flutter_sdk/db/const.dart';
import 'package:xochat_flutter_sdk/model/wk_message_content.dart';
import 'package:xochat_flutter_sdk/type/const.dart';

class XOTextContent extends XOMessageContent {
  XOTextContent(content) {
    contentType = WkMessageContentType.text;
    this.content = content;
  }
  @override
  Map<String, dynamic> encodeJson() {
    return {"content": content};
  }

  @override
  XOMessageContent decodeJson(Map<String, dynamic> json) {
    content = XODBConst.readString(json, 'content');
    return this;
  }

  @override
  String displayText() {
    return content;
  }

  @override
  String searchableWord() {
    return content;
  }
}
