import 'package:xochat_flutter_sdk/model/wk_media_message_content.dart';
import 'package:xochat_flutter_sdk/model/wk_message_content.dart';
import 'package:xochat_flutter_sdk/type/const.dart';

class XOVoiceContent extends XOMediaMessageContent {
  int timeTrad; // 语音秒长
  String? waveform; // 语音波纹 base64编码
  XOVoiceContent(this.timeTrad) {
    contentType = WkMessageContentType.voice;
  }

  @override
  Map<String, dynamic> encodeJson() {
    return {
      'timeTrad': timeTrad,
      'url': url,
      'waveform': waveform,
      'localPath': localPath
    };
  }

  @override
  XOMessageContent decodeJson(Map<String, dynamic> json) {
    timeTrad = readInt(json, 'timeTrad');
    url = readString(json, 'url');
    localPath = readString(json, 'localPath');
    waveform = readString(json, 'waveform');
    return this;
  }

  @override
  String displayText() {
    return '[语音]';
  }

  @override
  String searchableWord() {
    return '[语音]';
  }
}
