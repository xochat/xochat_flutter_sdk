import 'package:sqflite/sqflite.dart';

import '../entity/channel_member.dart';
import 'const.dart';
import 'wk_db_helper.dart';

class ChannelMemberDB {
  ChannelMemberDB._privateConstructor();
  static final ChannelMemberDB _instance =
      ChannelMemberDB._privateConstructor();
  static ChannelMemberDB get shared => _instance;
  final String channelCols =
      "${XODBConst.tableChannel}.channel_remark,${XODBConst.tableChannel}.channel_name,${XODBConst.tableChannel}.avatar,${XODBConst.tableChannel}.avatar_cache_key";

  Future<List<XOChannelMember>> queryMemberWithUIDs(
      String channelID, int channelType, List<String> uidList) async {
    List<Object> args = [];
    args.add(channelID);
    args.add(channelType);
    args.addAll(uidList);
    List<XOChannelMember> list = [];
    List<Map<String, Object?>> results = await XODBHelper.shared.getDB().query(
        XODBConst.tableChannelMember,
        where:
            "channel_id=? and channel_type=? and member_uid in (${XODBConst.getPlaceholders(uidList.length)})",
        whereArgs: args);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeChannelMember(data));
      }
    }
    return list;
  }

  Future<int> getMaxVersion(String channelID, int channelType) async {
    String sql =
        "select max(version) version from ${XODBConst.tableChannelMember} where channel_id =? and channel_type=? limit 0, 1";
    int version = 0;

    List<Map<String, Object?>> results =
        await XODBHelper.shared.getDB().rawQuery(sql, [channelID, channelType]);
    if (results.isNotEmpty) {
      dynamic data = results[0];
      version = XODBConst.readInt(data, 'version');
    }
    return version;
  }

  Future<XOChannelMember?> queryWithUID(
      String channelId, int channelType, String memberUID) async {
    String sql =
        "select ${XODBConst.tableChannelMember}.*,$channelCols from ${XODBConst.tableChannelMember} left join ${XODBConst.tableChannel} on ${XODBConst.tableChannelMember}.member_uid = ${XODBConst.tableChannel}.channel_id AND ${XODBConst.tableChannel}.channel_type=1 where (${XODBConst.tableChannelMember}.channel_id=? and ${XODBConst.tableChannelMember}.channel_type=? and ${XODBConst.tableChannelMember}.member_uid=?)";
    XOChannelMember? channelMember;
    List<Map<String, Object?>> list = await XODBHelper.shared
        .getDB()
        .rawQuery(sql, [channelId, channelType, memberUID]);
    if (list.isNotEmpty) {
      channelMember = XODBConst.serializeChannelMember(list[0]);
    }
    return channelMember;
  }

  Future<List<XOChannelMember>?> queryWithChannel(
      String channelId, int channelType) async {
    String sql =
        "select ${XODBConst.tableChannelMember}.*,$channelCols from ${XODBConst.tableChannelMember} LEFT JOIN ${XODBConst.tableChannel} on ${XODBConst.tableChannelMember}.member_uid=${XODBConst.tableChannel}.channel_id and ${XODBConst.tableChannel}.channel_type=1 where ${XODBConst.tableChannelMember}.channel_id=? and ${XODBConst.tableChannelMember}.channel_type=? and ${XODBConst.tableChannelMember}.is_deleted=0 and ${XODBConst.tableChannelMember}.status=1 order by ${XODBConst.tableChannelMember}.role=1 desc,${XODBConst.tableChannelMember}.role=2 desc,${XODBConst.tableChannelMember}.created_at asc";
    List<XOChannelMember> list = [];
    List<Map<String, Object?>> results =
        await XODBHelper.shared.getDB().rawQuery(sql, [channelId, channelType]);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeChannelMember(data));
      }
    }
    return list;
  }

  Future<List<XOChannelMember>> queryWithUIDs(
      String channelID, int channelType, List<String> uidList) async {
    List<Object> args = [];
    args.add(channelID);
    args.add(channelType);
    args.addAll(uidList);

    List<XOChannelMember> list = [];
    List<Map<String, Object?>> results = await XODBHelper.shared.getDB().query(
        XODBConst.tableChannelMember,
        where:
            "channel_id=? and channel_type=? and member_uid in (${XODBConst.getPlaceholders(uidList.length)}) ",
        whereArgs: args);
    if (results.isNotEmpty) {
      for (Map<String, Object?> data in results) {
        list.add(XODBConst.serializeChannelMember(data));
      }
    }
    return list;
  }

  insertOrUpdateList(
      List<XOChannelMember> allMemberList, List<XOChannelMember> existList) {
    List<Map<String, Object>> insertCVList = [];
    List<Map<String, Object>> updateCVList = [];
    for (XOChannelMember channelMember in allMemberList) {
      bool isAdd = true;
      for (XOChannelMember cm in existList) {
        if (channelMember.memberUID == cm.memberUID) {
          isAdd = false;
          updateCVList.add(getMap(channelMember));
          break;
        }
      }
      if (isAdd) {
        insertCVList.add(getMap(channelMember));
      }
    }
    if (insertCVList.isNotEmpty || updateCVList.isNotEmpty) {
      XODBHelper.shared.getDB().transaction((txn) async {
        if (insertCVList.isNotEmpty) {
          for (Map<String, dynamic> value in insertCVList) {
            txn.insert(XODBConst.tableChannelMember, value,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        if (updateCVList.isNotEmpty) {
          for (Map<String, dynamic> value in updateCVList) {
            txn.update(XODBConst.tableChannelMember, value,
                where: "channel_id=? and channel_type=? and member_uid=?",
                whereArgs: [
                  value['channel_id'],
                  value['channel_type'],
                  value['member_uid']
                ]);
          }
        }
      });
    }
  }

  dynamic getMap(XOChannelMember member) {
    var map = <String, Object>{};
    map['channel_id'] = member.channelID;
    map['channel_type'] = member.channelType;
    map['member_invite_uid'] = member.memberInviteUID;
    map['member_uid'] = member.memberUID;
    map['member_name'] = member.memberName;
    map['member_remark'] = member.memberRemark;
    map['member_avatar'] = member.memberAvatar;
    map['member_avatar_cache_key'] = member.memberAvatarCacheKey;
    map['role'] = member.role;
    map['is_deleted'] = member.isDeleted;
    map['version'] = member.version;
    map['status'] = member.status;
    map['robot'] = member.robot;
    map['forbidden_expiration_time'] = member.forbiddenExpirationTime;
    map['created_at'] = member.createdAt;
    map['updated_at'] = member.updatedAt;
    return map;
  }
}
