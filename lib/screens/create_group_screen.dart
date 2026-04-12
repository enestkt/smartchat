import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  File? _image;
  List<dynamic> _allContacts = [];
  List<dynamic> _filteredContacts = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.userId!;
      final partners = await ChatService().getChatPartners(userId);

      if (mounted) {
        setState(() {
          _allContacts = partners.where((p) => p["is_group"] == 0).toList();
          _filteredContacts = _allContacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        final name = (contact["username"] ?? "").toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter a group name');
      return;
    }
    if (_selectedIds.isEmpty) {
      _showSnackBar('Please select at least one member');
      return;
    }

    setState(() => _isCreating = true);

    final adminId = context.read<AuthProvider>().userId!;
    final groupId = await ChatService().createGroup(name, adminId, _selectedIds.toList());

    // Suggestion: Handle image upload here if groupId is not null
    // if (groupId != null && _image != null) {
    //    await ChatService().uploadGroupAvatar(groupId, _image!.path);
    // }

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (groupId != null) {
      Navigator.pop(context);
    } else {
      _showSnackBar('Failed to create group');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor; // Or your specific app color

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("New Group", style: TextStyle(color: Colors.white, fontSize: 18)),
            if (_selectedIds.isNotEmpty)
              Text(
                "${_selectedIds.length} members selected",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF008F9C),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildImagePicker(),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Enter group name...",
                      labelText: "Group Name",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSearchField(),
          const Divider(height: 1),
          Expanded(
            child: _filteredContacts.isEmpty
                ? const Center(child: Text("No contacts found"))
                : ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, i) {
                final contact = _filteredContacts[i];
                final id = contact["user_id"];
                final isSelected = _selectedIds.contains(id);
                return ListTile(
                  onTap: () => _toggleSelection(id),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  title: Text(contact["username"] ?? "Unknown"),
                  trailing: Checkbox(
                    activeColor: const Color(0xFF008F9C),
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF008F9C),
        onPressed: _isCreating ? null : _createGroup,
        child: _isCreating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _image != null ? FileImage(_image!) : null,
            child: _image == null
                ? const Icon(Icons.camera_alt, color: Colors.white, size: 30)
                : null,
          ),
          if (_image == null)
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.grey.shade600,
                child: const Icon(Icons.add, size: 14, color: Colors.white),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search contacts...",
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}