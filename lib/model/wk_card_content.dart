import 'package:xochat_flutter_sdk/model/wk_message_content.dart';
import 'package:xochat_flutter_sdk/type/const.dart';

class XOCardContent extends XOMessageContent {
  String name;
  String uid;
  String? vercode;
  XOCardContent(this.uid, this.name) {
    contentType = WkMessageContentType.card;
  }

  @override
  XOMessageContent decodeJson(Map<String, dynamic> json) {
    name = readString(json, 'name');
    uid = readString(json, 'uid');
    vercode = readString(json, 'uid');
    return this;
  }

  @override
  Map<String, dynamic> encodeJson() {
    return {'name': name, 'uid': uid, 'vercode': vercode};
  }

  @override
  String displayText() {
    return "[名片]";
  }

  @override
  String searchableWord() {
    return "[名片]";
  }
}
