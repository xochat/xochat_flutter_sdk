import 'package:xochat_flutter_sdk/entity/msg.dart';

class XOMessageContent {
  var contentType = 0;
  String content = "";
  String topicId = "";
  XOReply? reply;
  List<XOMsgEntity>? entities;
  Map<String, dynamic> encodeJson() {
    return {};
  }

  XOMessageContent decodeJson(Map<String, dynamic> json) {
    return this;
  }

  String displayText() {
    return content;
  }

  String searchableWord() {
    return content;
  }

  int readInt(dynamic json, String key) {
    dynamic result = json[key];
    if (result == Null || result == null) {
      return 0;
    }
    return result as int;
  }

  String readString(dynamic json, String key) {
    dynamic result = json[key];
    if (result == Null || result == null) {
      return '';
    }
    return result.toString();
  }
}
