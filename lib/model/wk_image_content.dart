import 'package:xochat_flutter_sdk/model/wk_media_message_content.dart';
import 'package:xochat_flutter_sdk/model/wk_message_content.dart';
import 'package:xochat_flutter_sdk/type/const.dart';

class XOImageContent extends XOMediaMessageContent {
  int width;
  int height;
  XOImageContent(this.width, this.height) {
    contentType = WkMessageContentType.image;
  }
  @override
  Map<String, dynamic> encodeJson() {
    return {
      'width': width,
      'height': height,
      'url': url,
      'localPath': localPath
    };
  }

  @override
  XOMessageContent decodeJson(Map<String, dynamic> json) {
    width = readInt(json, 'width');
    height = readInt(json, 'height');
    url = readString(json, 'url');
    localPath = readString(json, 'localPath');
    return this;
  }

  @override
  String displayText() {
    return '[图片]';
  }

  @override
  String searchableWord() {
    return '[图片]';
  }
}
