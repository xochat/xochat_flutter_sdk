import 'package:xochat_flutter_sdk/entity/conversation.dart';

class UIConversation {
  String lastContent = '';
  String channelAvatar = '';
  String channelName = '';
  XOUIConversationMsg msg;
  UIConversation(this.msg);

  String getUnreadCount() {
    if (msg.unreadCount > 0) {
      return '${msg.unreadCount}';
    }
    return '';
  }
}
