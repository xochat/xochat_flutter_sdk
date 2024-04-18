## 悟空 IM Flutter SDK

![](https://img.shields.io/static/v1?label=platform&message=flutter&color=green) ![](https://img.shields.io/hexpm/l/plug.svg)

[悟空 IM](https://github.com/WuKongIM/WuKongIM "文档") flutter sdk 源码 [详细文档](http://githubim.com/sdk/flutter.html "文档")

## 快速入门

#### 安装

```
dependencies:
  xochat_flutter_sdk: ^1.3.3
```

#### 引入

```dart
import 'package:xochat_flutter_sdk/wkim.dart';
```

**初始化 sdk**

```dart
XOIM.shared.setup(Options.newDefault('uid', 'token'));
```

**初始化 IP**

```dart
XOIM.shared.options.getAddr = (Function(String address) complete) async {
    // 可通过接口获取后返回
      String ip = await HttpUtils.getIP();
      complete(ip);
    };
```

**连接**

```dart
XOIM.shared.connectionManager.connect();
```

**断开**

```dart
// isLogout true：退出并不再重连 false：退出保持重连
XOIM.shared.connectionManager.disconnect(isLogout)
```

**发消息**

```dart
XOIM.shared.messageManager.sendMessage(XOTextContent('我是文本消息'), XOChannel(channelID, channelType));
```

## 监听

**连接监听**

```dart
XOIM.shared.connectionManager.addOnConnectionStatus('home',
        (status, reason) {
      if (status == XOConnectStatus.connecting) {
        // 连接中
      } else if (status == XOConnectStatus.success) {
        // 成功
      } else if (status == XOConnectStatus.noNetwork) {
        // 网络异常
      } else if (status == XOConnectStatus.syncMsg) {
        //同步消息中
      }
    });
```

**消息入库**

```dart
XOIM.shared.messageManager.addOnMsgInsertedListener((wkMsg) {
      // todo 展示在UI上
    });
```

**收到新消息**

```dart
XOIM.shared.messageManager.addOnNewMsgListener('chat', (msgs) {
      // todo 展示在UI上
    });
```

**刷新某条消息**

```dart
XOIM.shared.messageManager.addOnRefreshMsgListener('chat', (wkMsg) {
      // todo 刷新消息
    });
```

**命令消息(cmd)监听**

```dart
XOIM.shared.cmdManager.addOnCmdListener('chat', (cmdMsg) {
    // todo 按需处理cmd消息
});
```

- 包含`key`的事件监听均有移除监听的方法，为了避免重复收到事件回掉，在退出或销毁页面时通过传入的`key`移除事件
