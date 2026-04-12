import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';

class GroupInfoScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupInfoScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _group;
  List<dynamic> _members = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchGroupInfo();
  }

  Future<void> _fetchGroupInfo() async {
    final groupData = await ChatService().getGroup(widget.groupId);
    if (groupData != null) {
      final currentUserId = context.read<AuthProvider>().userId;
      setState(() {
        _group = groupData;
        _members = groupData["members"] ?? [];
        _isAdmin = groupData["admin_id"] == currentUserId;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateGroupName() async {
    final controller = TextEditingController(text: _group!["group_name"]);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Group Name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text("Save")),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      final success = await ChatService().updateGroup(widget.groupId, newName);
      if (success) _fetchGroupInfo();
    }
  }

  Future<void> _kickMember(int userId) async {
    final success = await ChatService().removeGroupMember(widget.groupId, userId);
    if (success) _fetchGroupInfo();
  }

  Future<void> _leaveGroup() async {
    final currentUserId = context.read<AuthProvider>().userId!;
    final success = await ChatService().removeGroupMember(widget.groupId, currentUserId);
    if (success) {
      Navigator.popUntil(context, ModalRoute.withName('/list'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Info", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF008F9C),
        actions: [
          if (_isAdmin)
            IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _updateGroupName),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF008F9C),
            child: Icon(Icons.group, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(_group!["group_name"] ?? widget.groupName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Members", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, i) {
                final member = _members[i];
                final isMemberAdmin = member["user_id"] == _group!["admin_id"];

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Row(
                    children: [
                      Text(member["username"]),
                      if (isMemberAdmin)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.stars, color: Colors.amber, size: 16),
                        )
                    ],
                  ),
                  trailing: _isAdmin && !isMemberAdmin
                      ? IconButton(
                          icon: const Icon(Icons.person_remove, color: Colors.red),
                          onPressed: () => _kickMember(member["user_id"]),
                        )
                      : null,
                );
              },
            ),
          ),
          if (!_isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _leaveGroup,
                  child: const Text("Leave Group", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}