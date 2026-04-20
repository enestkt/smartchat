import 'package:dio/dio.dart';

class ChatService {
  static const String baseUrl = "http://10.0.2.2:5000";

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {"Content-Type": "application/json"},
  ));

  /// Kullanıcı arama
  Future<Map<String, dynamic>?> searchUser(String username) async {
    try {
      final res = await _dio.get("/user_by_username/$username");

      if (res.data["success"] == true) {
        return res.data["user"];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Mesaj yükleme
  Future<List<dynamic>> fetchMessages(int senderId, int receiverId, {int? groupId}) async {
    final query = <String, dynamic>{
      "sender_id": senderId,
    };
    if (groupId != null) {
      query["group_id"] = groupId;
    } else {
      query["receiver_id"] = receiverId;
    }
    
    final res = await _dio.get(
      "/messages",
      queryParameters: query,
    );
    return res.data["messages"] ?? [];
  }

  /// Chat partner listesi
  Future<List<dynamic>> getChatPartners(int userId) async {
    final res = await _dio.get("/chat_partners/$userId");
    return res.data ?? [];
  }

  /// Mesaj gönderme (text)
  Future<bool> sendMessage(int senderId, int receiverId, String message, {int? groupId}) async {
    try {
      final data = <String, dynamic>{
        "sender_id": senderId,
        "content": message,
      };
      if (groupId != null) {
        data["group_id"] = groupId;
      } else {
        data["receiver_id"] = receiverId;
      }

      await _dio.post("/messages", data: data);
      return true;
    } catch (e) {
      print("SEND MESSAGE ERROR: $e");
      return false;
    }
  }

  // -------------------------------------------------------------
  //  MEDIA UPLOAD (image, file, audio, video)
  // -------------------------------------------------------------
  Future<bool> uploadMedia({
    required int senderId,
    required int receiverId,
    required String filePath,
    required String mediaType, int? groupId,
  }) async {
    try {
      final fileName = filePath.split('/').last;

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
        "media_type": mediaType,
        "sender_id": senderId.toString(),
      });
      
      if (groupId != null) {
        formData.fields.add(MapEntry("group_id", groupId.toString()));
      } else {
        formData.fields.add(MapEntry("receiver_id", receiverId.toString()));
      }

      final res = await _dio.post(
        "/upload_media",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
        ),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("UPLOAD MEDIA ERROR: $e");
      return false;
    }
  }
  
  // -------------------------------------------------------------
  //  GROUPS
  // -------------------------------------------------------------
  Future<int?> createGroup(String groupName, int adminId, List<int> memberIds) async {
    try {
      final res = await _dio.post("/groups", data: {
        "group_name": groupName,
        "admin_id": adminId,
        "member_ids": memberIds,
      });
      return res.data["group_id"];
    } catch (e) {
      print("CREATE GROUP ERROR: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getGroup(int groupId) async {
    try {
      final res = await _dio.get("/groups/$groupId");
      return res.data["group"];
    } catch (e) {
      return null;
    }
  }
  
  Future<bool> removeGroupMember(int groupId, int userId) async {
    try {
      final res = await _dio.delete("/groups/$groupId/members/$userId");
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> updateGroup(int groupId, String groupName) async {
    try {
      final res = await _dio.patch("/groups/$groupId", data: {
        "group_name": groupName,
      });
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
