import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity/connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xochat_flutter_sdk/db/const.dart';

import 'package:xochat_flutter_sdk/db/wk_db_helper.dart';
import 'package:xochat_flutter_sdk/entity/msg.dart';
import 'package:xochat_flutter_sdk/proto/write_read.dart';
import 'package:xochat_flutter_sdk/wkim.dart';
import 'package:xochat_flutter_sdk/common/crypto_utils.dart';
import '../common/logs.dart';
import '../entity/conversation.dart';
import '../proto/packet.dart';
import '../proto/proto.dart';
import '../type/const.dart';

mixin _Socket {
  void close();
  void send(Uint8List data);
  void listen(void Function(dynamic data) onData, void Function() error);
}

class _XOSocket implements _Socket {
  Socket? _socket; // 将 _socket 声明为可空类型
  bool _isListening = false;
  static _XOSocket? _instance;
  _XOSocket._internal(this._socket);

  factory _XOSocket.newSocket(Socket socket) {
    _instance ??= _XOSocket._internal(socket);
    return _instance!;
  }

  @override
  void close() {
    _isListening = false;
    _instance = null;
    try {
      _socket?.destroy();
    } finally {
      _socket = null; // 现在可以将 _socket 设置为 null
    }
  }

  @override
  void send(Uint8List data) {
    try {
      if (_socket?.remotePort != null) {
        _socket?.add(data); // 使用安全调用操作符
        _socket?.flush();
      }
    } catch (e) {
      Logs.debug('发送消息错误$e');
    }
  }

  @override
  void listen(void Function(dynamic data) onData, void Function() error) {
    if (!_isListening && _socket != null) {
      _socket?.listen(
        onData,
        onError: (err) {
          Logs.debug('socket断开了${err.toString()}');
        },
        onDone: () {
          close(); // 关闭和重置 Socket 连接
          error();
        },
      );
      _isListening = true;
    }
  }
}

class _XOWebSocket implements _Socket {
  WebSocketChannel? _socket; // 将 _socket 声明为可空类型
  bool _isListening = false;
  static _XOWebSocket? _instance;
  _XOWebSocket._internal(this._socket);

  factory _XOWebSocket.newSocket(WebSocketChannel socket) {
    _instance ??= _XOWebSocket._internal(socket);
    return _instance!;
  }

  @override
  void close() {
    _isListening = false;
    _instance = null;
    try {
      _socket?.sink.close();
    } finally {
      _socket = null; // 现在可以将 _socket 设置为 null
    }
  }

  @override
  void send(Uint8List data) {
    try {
      if (_socket?.sink != null) {
        _socket?.sink.add(data); // 使用安全调用操作符
      }
    } catch (e) {
      Logs.debug('发送消息错误$e');
    }
  }

  @override
  void listen(void Function(dynamic data) onData, void Function() error) {
    if (!_isListening && _socket != null) {
      _socket?.stream.listen(
        onData,
        onError: (err) {
          Logs.debug('socket断开了${err.toString()}');
        },
        onDone: () {
          close(); // 关闭和重置 Socket 连接
          error();
        },
      );
      _isListening = true;
    }
  }
}

class XOConnectionManager {
  XOConnectionManager._privateConstructor();
  static final XOConnectionManager _instance =
      XOConnectionManager._privateConstructor();
  static XOConnectionManager get shared => _instance;
  bool _isLogout = false;
  bool isReconnection = false;
  final int reconnMilliseconds = 1500;
  Timer? heartTimer;
  Timer? checkNetworkTimer;
  final heartIntervalSecond = const Duration(seconds: 60);
  final checkNetworkSecond = const Duration(seconds: 1);
  final HashMap<int, SendingMsg> _sendingMsgMap = HashMap();
  HashMap<String, Function(int, String)>? _connectionListenerMap;
  _Socket? _socket;
  addOnConnectionStatus(String key, Function(int, String) back) {
    _connectionListenerMap ??= HashMap();
    _connectionListenerMap![key] = back;
  }

  removeOnConnectionStatus(String key) {
    if (_connectionListenerMap != null) {
      _connectionListenerMap!.remove(key);
    }
  }

  setConnectionStatus(int status, String reason) {
    if (_connectionListenerMap != null) {
      _connectionListenerMap!.forEach((key, back) {
        back(status, reason);
      });
    }
  }

  connect({String socketType = "ws"}) {
    var addr = XOIM.shared.options.addr;
    if ((addr == null || addr == "") && XOIM.shared.options.getAddr == null) {
      Logs.info("没有配置addr！");
      return;
    }
    if (XOIM.shared.options.uid == "" ||
        XOIM.shared.options.uid == null ||
        XOIM.shared.options.token == "" ||
        XOIM.shared.options.token == null) {
      Logs.error("没有初始化uid或token");
      return;
    }
    _isLogout = false;
    if (XOIM.shared.options.getAddr != null) {
      XOIM.shared.options.getAddr!((String addr) {
        _socketConnect(addr, socketType);
      });
      // _socketConnect(addr!, socketType);
    } else {
      _socketConnect(addr!, socketType);
    }
  }

  disconnect(bool isLogout) {
    _isLogout = true;
    if (_socket != null) {
      _socket!.close();
    }
    if (isLogout) {
      // _isLogout = true;
      XOIM.shared.options.uid = '';
      XOIM.shared.options.token = '';
      XOIM.shared.messageManager.updateSendingMsgFail();
      XODBHelper.shared.close();
    }
    _closeAll();
  }

  _socketConnect(String addr, String socketType) {
    Logs.info("连接地址--->$addr");
    try {
      setConnectionStatus(XOConnectStatus.connecting, '');
      if (socketType == "tcp") {
        var addrs = addr.split(":");
        var host = addrs[0];
        var port = addrs[1];
        Socket.connect(host, int.parse(port),
                timeout: const Duration(seconds: 5))
            .then((socket) {
          _socket = _XOSocket.newSocket(socket);
          print("链接成功");
          _connectSuccess();
        }).catchError((err) {
          print("链接成功---2222-----$err");
          _connectFail(err);
        }).onError((err, stackTrace) {
          print("链接成功---1111-----$err");
          _connectFail(err);
        });
      } else {
        var socket = IOWebSocketChannel.connect(addr,
            connectTimeout: const Duration(seconds: 5));
        _socket = _XOWebSocket.newSocket(socket);
        print("链接成功");
        _connectSuccess();
      }
    } catch (e) {
      Logs.error(e.toString());
    }
  }

  // socket 连接成功
  _connectSuccess() {
    // 监听消息
    _socket?.listen(
      (dynamic data) {
        _cutDatas(data);
        // _decodePacket(data);
      },
      () {
        if (_isLogout) {
          Logs.debug("登出了");
          return;
        }
        //  isReconnection = true;
        Future.delayed(Duration(milliseconds: reconnMilliseconds), () {
          connect();
        });
      },
    );
    // 发送连接包
    _sendConnectPacket();
  }

  _connectFail(error) {
    // _socket?.close();
    Future.delayed(Duration(milliseconds: reconnMilliseconds), () {
      connect();
    });
  }

  testCutData(Uint8List data) {
    _cutDatas(data);
  }

  Uint8List? _cacheData;
  _cutDatas(Uint8List data) {
    if (_cacheData == null || _cacheData!.isEmpty) {
      _cacheData = data;
    } else {
      // 上次存在未解析完的消息
      Uint8List temp = Uint8List(_cacheData!.length + data.length);
      for (var i = 0; i < _cacheData!.length; i++) {
        temp[i] = _cacheData![i];
      }
      for (var i = 0; i < data.length; i++) {
        temp[i + _cacheData!.length] = data[i];
      }
      _cacheData = temp;
    }
    Uint8List lastMsgBytes = _cacheData!;
    int readLength = 0;
    while (lastMsgBytes.isNotEmpty && readLength != lastMsgBytes.length) {
      readLength = lastMsgBytes.length;
      ReadData readData = ReadData(lastMsgBytes);
      var b = readData.readUint8();
      var packetType = b >> 4;
      if (PacketType.values[(b >> 4)] == PacketType.pong) {
        Logs.debug('pong');
        Uint8List bytes = lastMsgBytes.sublist(1, lastMsgBytes.length);
        _cacheData = lastMsgBytes = bytes;
      } else {
        if (packetType < 10) {
          if (lastMsgBytes.length < 5) {
            _cacheData = lastMsgBytes;
            break;
          }
          int remainingLength = readData.readVariableLength();
          if (remainingLength == -1) {
            //剩余长度被分包
            _cacheData = lastMsgBytes;
            break;
          }
          if (remainingLength > 1 << 21) {
            _cacheData = null;
            break;
          }
          List<int> bytes = encodeVariableLength(remainingLength);

          if (remainingLength + 1 + bytes.length > lastMsgBytes.length) {
            //半包情况
            _cacheData = lastMsgBytes;
          } else {
            var msg =
                lastMsgBytes.sublist(0, remainingLength + 1 + bytes.length);
            _decodePacket(msg);
            var temps = lastMsgBytes.sublist(msg.length, lastMsgBytes.length);
            _cacheData = lastMsgBytes = temps;
          }
        } else {
          _cacheData = null;
          // 数据包错误，重连
          connect();
          break;
        }
      }
    }
  }

  _decodePacket(Uint8List data) {
    var packet = XOIM.shared.options.proto.decode(data);
    Logs.debug('解码出包->$packet');
    if (packet.header.packetType == PacketType.connack) {
      var connackPacket = packet as ConnackPacket;
      if (connackPacket.reasonCode == 1) {
        Logs.debug('连接成功！');
        CryptoUtils.setServerKeyAndSalt(
            connackPacket.serverKey, connackPacket.salt);
        setConnectionStatus(XOConnectStatus.success, '');
        XOIM.shared.conversationManager.setSyncConversation(() {
          setConnectionStatus(XOConnectStatus.success, '');
        });
        _resendMsg();
        _startHeartTimer();
        _startCheckNetworkTimer();
      } else {
        String reason = '';
        if (connackPacket.reasonCode == XOConnectStatus.kicked) {
          reason = 'ReasonAuthFail';
        }
        setConnectionStatus(XOConnectStatus.fail, reason);
        Logs.debug('连接失败！错误->${connackPacket.reasonCode}');
      }
    } else if (packet.header.packetType == PacketType.recv) {
      var recvPacket = packet as RecvPacket;
      _verifyRecvMsg(recvPacket);
      _sendRecvAckPacket(recvPacket.messageID, recvPacket.messageSeq);
    } else if (packet.header.packetType == PacketType.sendack) {
      var sendack = packet as SendAckPacket;
      XOIM.shared.messageManager.updateSendResult(
        sendack.messageID,
        sendack.clientSeq,
        sendack.messageSeq,
        sendack.reasonCode,
      );
      if (_sendingMsgMap.containsKey(sendack.clientSeq)) {
        _sendingMsgMap[sendack.clientSeq]!.isCanResend = false;
      }
    } else if (packet.header.packetType == PacketType.disconnect) {
      disconnect(true);
      // _closeAll();
      setConnectionStatus(XOConnectStatus.kicked, 'ReasonConnectKick');
    } else if (packet.header.packetType == PacketType.pong) {
      Logs.info('pong...');
    }
  }

  _closeAll() {
    // _isLogout = true;
    // XOIM.shared.options.uid = '';
    // XOIM.shared.options.token = '';
    // XOIM.shared.messageManager.updateSendingMsgFail();
    _stopCheckNetworkTimer();
    _stopHeartTimer();
    if (_socket != null) {
      _socket!.close();
    }

    // XODBHelper.shared.close();
  }

  _sendRecvAckPacket(BigInt messageID, int messageSeq) {
    RecvAckPacket ackPacket = RecvAckPacket();
    ackPacket.messageID = messageID;
    ackPacket.messageSeq = messageSeq;
    _sendPacket(ackPacket);
  }

  _sendConnectPacket() async {
    var deviceID = await _getDeviceID();
    var connectPacket = ConnectPacket(
      uid: XOIM.shared.options.uid!,
      token: XOIM.shared.options.token!,
      version: XOIM.shared.options.protoVersion,
      clientKey: base64Encode(CryptoUtils.dhPublicKey!),
      deviceID: deviceID,
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
    connectPacket.deviceFlag = XOIM.shared.deviceFlagApp;
    _sendPacket(connectPacket);
  }

  _sendPacket(Packet packet) {
    var data = XOIM.shared.options.proto.encode(packet);
    if (!isReconnection) {
      _socket?.send(data);
    }
  }

  _startCheckNetworkTimer() {
    _stopCheckNetworkTimer();
    checkNetworkTimer = Timer.periodic(checkNetworkSecond, (timer) {
      Future<ConnectivityResult> connectivityResult =
          (Connectivity().checkConnectivity());
      connectivityResult.then((value) {
        if (value == ConnectivityResult.none) {
          isReconnection = true;
          Logs.debug('网络断开了');
          _checkSendingMsg();
          setConnectionStatus(XOConnectStatus.noNetwork, '');
        } else {
          if (isReconnection) {
            connect();
            isReconnection = false;
          }
        }
      });
    });
  }

  _stopCheckNetworkTimer() {
    if (checkNetworkTimer != null) {
      checkNetworkTimer!.cancel();
      checkNetworkTimer = null;
    }
  }

  _startHeartTimer() {
    _stopHeartTimer();
    heartTimer = Timer.periodic(heartIntervalSecond, (timer) {
      Logs.info('ping...');
      _sendPacket(PingPacket());
    });
  }

  _stopHeartTimer() {
    if (heartTimer != null) {
      heartTimer!.cancel();
      heartTimer = null;
    }
  }

  sendMessage(XOMsg wkMsg) {
    SendPacket packet = SendPacket();
    packet.setting = wkMsg.setting;
    packet.header.noPersist = wkMsg.header.noPersist;
    packet.header.showUnread = wkMsg.header.redDot;
    packet.header.syncOnce = wkMsg.header.syncOnce;
    packet.channelID = wkMsg.channelID;
    packet.channelType = wkMsg.channelType;
    packet.clientSeq = wkMsg.clientSeq;
    packet.clientMsgNO = wkMsg.clientMsgNO;
    packet.topic = wkMsg.topicID;
    packet.payload = wkMsg.content;
    _addSendingMsg(packet);
    _sendPacket(packet);
  }

  _verifyRecvMsg(RecvPacket recvMsg) {
    StringBuffer sb = StringBuffer();
    sb.writeAll([
      recvMsg.messageID,
      recvMsg.messageSeq,
      recvMsg.clientMsgNO,
      recvMsg.messageTime,
      recvMsg.fromUID,
      recvMsg.channelID,
      recvMsg.channelType,
      recvMsg.payload
    ]);
    var encryptContent = sb.toString();
    var result = CryptoUtils.aesEncrypt(encryptContent);
    String localMsgKey = CryptoUtils.generateMD5(result);
    if (recvMsg.msgKey != localMsgKey) {
      Logs.error('非法消息-->期望msgKey：$localMsgKey，实际msgKey：${recvMsg.msgKey}');
      return;
    } else {
      recvMsg.payload = CryptoUtils.aesDecrypt(recvMsg.payload);
      Logs.debug(recvMsg.toString());
      _saveRecvMsg(recvMsg);
    }
  }

  _saveRecvMsg(RecvPacket recvMsg) async {
    XOMsg msg = XOMsg();
    msg.header.redDot = recvMsg.header.showUnread;
    msg.header.noPersist = recvMsg.header.noPersist;
    msg.header.syncOnce = recvMsg.header.syncOnce;
    msg.setting = recvMsg.setting;
    msg.channelType = recvMsg.channelType;
    msg.channelID = recvMsg.channelID;
    msg.content = recvMsg.payload;
    msg.messageID = recvMsg.messageID.toString();
    msg.messageSeq = recvMsg.messageSeq;
    msg.timestamp = recvMsg.messageTime;
    msg.fromUID = recvMsg.fromUID;
    msg.clientMsgNO = recvMsg.clientMsgNO;
    msg.status = XOSendMsgResult.sendSuccess;
    msg.topicID = recvMsg.topic;
    msg.orderSeq = await XOIM.shared.messageManager
        .getMessageOrderSeq(msg.messageSeq, msg.channelID, msg.channelType);
    dynamic contentJson = jsonDecode(msg.content);
    msg.contentType = XODBConst.readInt(contentJson, 'type');
    msg.isDeleted = _isDeletedMsg(contentJson);
    msg.messageContent = XOIM.shared.messageManager
        .getMessageModel(msg.contentType, contentJson);
    XOIM.shared.messageManager.parsingMsg(msg);
    if (msg.isDeleted == 0 &&
        !msg.header.noPersist &&
        msg.contentType != WkMessageContentType.insideMsg) {
      int row = await XOIM.shared.messageManager.saveMsg(msg);
      msg.clientSeq = row;
      XOUIConversationMsg? uiMsg =
          await XOIM.shared.conversationManager.saveWithLiMMsg(msg);
      if (uiMsg != null) {
        XOIM.shared.conversationManager.setRefreshMsg(uiMsg, true);
      }
    } else {
      Logs.debug(
          '消息不能存库:is_deleted=${msg.isDeleted},no_persist=${msg.header.noPersist},content_type:${msg.contentType}');
    }
    if (msg.contentType != WkMessageContentType.insideMsg) {
      List<XOMsg> list = [];
      list.add(msg);
      XOIM.shared.messageManager.pushNewMsg(list);
    }
  }

  int _isDeletedMsg(dynamic jsonObject) {
    int isDelete = 0;
    if (jsonObject != null) {
      var visibles = jsonObject['visibles'];
      if (visibles != null) {
        bool isIncludeLoginUser = false;
        var uids = visibles as List<String>;
        for (int i = 0, size = uids.length; i < size; i++) {
          if (uids[i] == XOIM.shared.options.uid) {
            isIncludeLoginUser = true;
            break;
          }
        }
        isDelete = isIncludeLoginUser ? 0 : 1;
      }
    }
    return isDelete;
  }

  _resendMsg() {
    _removeSendingMsg();
    if (_sendingMsgMap.isNotEmpty) {
      final it = _sendingMsgMap.entries.iterator;
      while (it.moveNext()) {
        if (it.current.value.isCanResend) {
          _sendPacket(it.current.value.sendPacket);
        }
      }
    }
  }

  _addSendingMsg(SendPacket sendPacket) {
    _removeSendingMsg();
    _sendingMsgMap[sendPacket.clientSeq] = SendingMsg(sendPacket);
  }

  _removeSendingMsg() {
    if (_sendingMsgMap.isNotEmpty) {
      List<int> ids = [];
      _sendingMsgMap.forEach((key, sendingMsg) {
        if (!sendingMsg.isCanResend) {
          ids.add(key);
        }
      });
      if (ids.isNotEmpty) {
        for (var i = 0; i < ids.length; i++) {
          _sendingMsgMap.remove(ids[i]);
        }
      }
    }
  }

  _checkSendingMsg() {
    if (_sendingMsgMap.isNotEmpty) {
      final it = _sendingMsgMap.entries.iterator;
      while (it.moveNext()) {
        var key = it.current.key;
        var wkSendingMsg = it.current.value;
        if (wkSendingMsg.sendCount == 5 && wkSendingMsg.isCanResend) {
          XOIM.shared.messageManager.updateMsgStatusFail(key);
          wkSendingMsg.isCanResend = false;
        } else {
          var nowTime =
              (DateTime.now().millisecondsSinceEpoch / 1000).truncate();
          if (nowTime - wkSendingMsg.sendTime > 10) {
            wkSendingMsg.sendTime =
                (DateTime.now().millisecondsSinceEpoch / 1000).truncate();
            wkSendingMsg.sendCount++;
            _sendingMsgMap[key] = wkSendingMsg;
            _sendPacket(wkSendingMsg.sendPacket);
            Logs.debug("消息发送失败，尝试重发中...");
          }
        }
      }

      _removeSendingMsg();
    }
  }
}

Future<String> _getDeviceID() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  String wkUid = XOIM.shared.options.uid!;
  String key = "${wkUid}_device_id";
  var deviceID = preferences.getString(key);
  if (deviceID == null || deviceID == "") {
    deviceID = const Uuid().v4().toString().replaceAll("-", "");
    preferences.setString(key, deviceID);
  }
  return "${deviceID}F";
}

class SendingMsg {
  SendPacket sendPacket;
  int sendCount = 0;
  int sendTime = 0;
  bool isCanResend = true;
  SendingMsg(this.sendPacket) {
    sendTime = (DateTime.now().millisecondsSinceEpoch / 1000).truncate();
  }
}
