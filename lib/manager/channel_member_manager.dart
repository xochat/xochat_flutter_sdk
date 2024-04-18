import 'dart:collection';

import 'package:xochat_flutter_sdk/db/channel_member.dart';

import '../entity/channel_member.dart';

class XOChannelMemberManager {
  XOChannelMemberManager._privateConstructor();
  static final XOChannelMemberManager _instance =
      XOChannelMemberManager._privateConstructor();
  static XOChannelMemberManager get shared => _instance;

  HashMap<String, Function(List<XOChannelMember>)>? _newMembersBack;
  HashMap<String, Function(XOChannelMember, bool)>? _refreshMembersBack;
  HashMap<String, Function(List<XOChannelMember>)>? _deleteMembersBack;

  Future<int> getMaxVersion(String channelID, int channelType) async {
    return ChannelMemberDB.shared.getMaxVersion(channelID, channelType);
  }

  Future<List<XOChannelMember>?> getMembers(
      String channelID, int channelType) async {
    return ChannelMemberDB.shared.queryWithChannel(channelID, channelType);
  }

  Future<XOChannelMember?> getMember(
      String channelID, int channelType, String memberUID) {
    return ChannelMemberDB.shared
        .queryWithUID(channelID, channelType, memberUID);
  }

  saveOrUpdateList(List<XOChannelMember> list) async {
    if (list.isEmpty) return;
    String channelID = list[0].channelID;
    int channelType = list[0].channelType;

    List<XOChannelMember> addList = [];
    List<XOChannelMember> deleteList = [];
    List<XOChannelMember> updateList = [];

    List<XOChannelMember> existList = [];
    List<String> uidList = [];
    for (XOChannelMember channelMember in list) {
      if (uidList.length == 200) {
        List<XOChannelMember> tempList = await ChannelMemberDB.shared
            .queryWithUIDs(
                channelMember.channelID, channelMember.channelType, uidList);
        if (tempList.isNotEmpty) {
          existList.addAll(tempList);
        }

        uidList.clear();
      }
      uidList.add(channelMember.memberUID);
    }

    if (uidList.isNotEmpty) {
      List<XOChannelMember> tempList = await ChannelMemberDB.shared
          .queryWithUIDs(channelID, channelType, uidList);
      if (tempList.isNotEmpty) {
        existList.addAll(tempList);
      }

      uidList.clear();
    }

    for (XOChannelMember channelMember in list) {
      bool isNewMember = true;
      for (int i = 0, size = existList.length; i < size; i++) {
        if (channelMember.memberUID == existList[i].memberUID) {
          isNewMember = false;
          if (channelMember.isDeleted == 1) {
            deleteList.add(channelMember);
          } else {
            if (existList[i].isDeleted == 1) {
              isNewMember = true;
            } else {
              updateList.add(channelMember);
            }
          }
          break;
        }
      }
      if (isNewMember) {
        addList.add(channelMember);
      }
    }

    // 先保存或修改成员
    ChannelMemberDB.shared.insertOrUpdateList(list, existList);

    if (addList.isNotEmpty) {
      setOnNewChannelMember(addList);
    }
    if (deleteList.isNotEmpty) {
      setDeleteChannelMember(deleteList);
    }

    if (updateList.isNotEmpty) {
      for (int i = 0, size = updateList.length; i < size; i++) {
        setRefreshChannelMember(updateList[i], i == updateList.length - 1);
      }
    }
  }

  setRefreshChannelMember(XOChannelMember member, bool isEnd) {
    if (_refreshMembersBack != null) {
      _refreshMembersBack!.forEach((key, back) {
        back(member, isEnd);
      });
    }
  }

  addOnRefreshMemberListener(String key, Function(XOChannelMember, bool) back) {
    _refreshMembersBack ??= HashMap();
    _refreshMembersBack![key] = back;
  }

  removeRefreshMemberListener(String key) {
    if (_refreshMembersBack != null) {
      _refreshMembersBack!.remove(key);
    }
  }

  setDeleteChannelMember(List<XOChannelMember> list) {
    if (_deleteMembersBack != null) {
      _deleteMembersBack!.forEach((key, back) {
        back(list);
      });
    }
  }

  addOnDeleteMemberListener(String key, Function(List<XOChannelMember>) back) {
    _deleteMembersBack ??= HashMap();
    _deleteMembersBack![key] = back;
  }

  removeDeleteMemberListener(String key) {
    if (_deleteMembersBack != null) {
      _deleteMembersBack!.remove(key);
    }
  }

  setOnNewChannelMember(List<XOChannelMember> list) {
    if (_newMembersBack != null) {
      _newMembersBack!.forEach((key, back) {
        back(list);
      });
    }
  }

  addOnNewMemberListener(String key, Function(List<XOChannelMember>) back) {
    _newMembersBack ??= HashMap();
    _newMembersBack![key] = back;
  }

  removeNewMemberListener(String key) {
    if (_newMembersBack != null) {
      _newMembersBack!.remove(key);
    }
  }
}
