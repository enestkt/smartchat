import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/color_helper.dart';
import '../theme/app_theme.dart';
import 'group_info_screen.dart';
import '../services/socket_service.dart';
import 'relationship_dashboard_screen.dart';

class ChatScreen extends StatefulWidget {
  final int senderId;
  final int receiverId;
  final String receiverName;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SocketService _socketService = SocketService();

  bool _isOtherUserTyping = false;
  Timer? _stopTypingTimer;

  List<Map<String, dynamic>> _messages = [];

  Map<String, dynamic>? _analysis;
  Timer? _typingTimer;

  Map<String, dynamic>? _aiSuggestion;
  bool _aiLoading = false;

  List<String>? _smartReplies;
  bool _smartRepliesLoading = false;

  late AnimationController _sendBtnAnim;

  @override
  void initState() {
    super.initState();
    _sendBtnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
    _loadMessages();
    _setupSocket();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _stopTypingTimer?.cancel();
    _socketService.removeListeners();
    _socketService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _sendBtnAnim.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // LOAD MESSAGES
  // ----------------------------------------------------------
  Map<String, dynamic> _formatMessage(Map<String, dynamic> m) {
    final imagePath = m["file_path"] ?? m["image_url"];
    final timestamp = m["timestamp"] ?? m["created_at"];

    return {
      "sender_username": m["sender_username"],
      "text": m["content"] ?? "",
      "image": imagePath,
      "isMe": m["sender_id"] == widget.senderId,
      "time": _formatTime(timestamp?.toString()),
    };
  }

  Future<void> _loadMessages() async {
    final data = await ChatService().fetchMessages(
      widget.senderId,
      widget.isGroup ? 0 : widget.receiverId,
      groupId: widget.isGroup ? widget.receiverId : null,
    );

    setState(() {
      _messages =
          data.map<Map<String, dynamic>>((m) => _formatMessage(m)).toList();
    });

    _scrollToBottom();

    // Sohbet açıldığında, son mesaj karşı taraftansa Akıllı Yanıtları getir
    if (_messages.isNotEmpty && widget.isGroup == false) {
      final lastMsg = _messages.last;
      if (lastMsg["isMe"] == false &&
          lastMsg["text"] != null &&
          (lastMsg["text"] as String).trim().isNotEmpty) {
        _fetchSmartReplies(lastMsg["text"]);
      }
    }
  }

  // ----------------------------------------------------------
  // TIME FORMAT
  // ----------------------------------------------------------
  String _formatTime(String? raw) {
    if (raw == null) return "";
    try {
      final dt = DateTime.parse(raw);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  void _handleTyping(String text) {
    if (_smartReplies != null) {
      setState(() => _smartReplies = null);
    }
    if (!widget.isGroup && text.trim().isNotEmpty) {
      _socketService.sendTyping(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
      );
    }

    _typingTimer?.cancel();

    _typingTimer = Timer(const Duration(seconds: 1), () async {
      if (text.trim().isEmpty) {
        setState(() => _analysis = null);
        return;
      }

      try {
        final result = await ApiService().predictMessage(
          text: text,
          senderId: widget.senderId,
          receiverId: widget.receiverId,
        );

        setState(() {
          _analysis = result;
        });
      } catch (e) {
        print("PREDICT ERROR: $e");
      }
    });
  }

  void _setupSocket() {
    _socketService.connect();

    if (!widget.isGroup) {
      _socketService.joinPrivateRoom(widget.senderId, widget.receiverId);
    }

    _socketService.onNewMessage((data) {
      if (!mounted || data == null) return;

      final incomingSenderId = data["sender_id"];
      final incomingReceiverId = data["receiver_id"];
      final incomingGroupId = data["group_id"];

      final isCurrentPrivateChat = !widget.isGroup &&
          ((incomingSenderId == widget.senderId &&
                  incomingReceiverId == widget.receiverId) ||
              (incomingSenderId == widget.receiverId &&
                  incomingReceiverId == widget.senderId));

      final isCurrentGroupChat =
          widget.isGroup && incomingGroupId == widget.receiverId;

      if (!isCurrentPrivateChat && !isCurrentGroupChat) return;

      final newMessage = {
        "sender_username": data["sender_username"],
        "text": data["content"] ?? "",
        "image": data["file_path"] ?? data["image_url"],
        "isMe": incomingSenderId == widget.senderId,
        "time": _formatTime(
          data["timestamp"]?.toString() ?? DateTime.now().toIso8601String(),
        ),
      };

      setState(() {
        final alreadyExists = _messages.any((m) =>
            m["text"] == newMessage["text"] &&
            m["time"] == newMessage["time"] &&
            m["isMe"] == newMessage["isMe"]);

        if (!alreadyExists) {
          _messages.add(newMessage);
        }
      });

      _scrollToBottom();

      if (!(newMessage["isMe"] as bool) &&
          (newMessage["text"] as String).isNotEmpty) {
        _fetchSmartReplies(newMessage["text"]);
      }
    });

    _socketService.onTyping((data) {
      if (!mounted || data == null) return;

      if (data["sender_id"] == widget.senderId) return;

      setState(() {
        _isOtherUserTyping = true;
      });

      _stopTypingTimer?.cancel();
      _stopTypingTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _isOtherUserTyping = false;
        });
      });
    });
  }

  Future<void> _testComplete() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _aiLoading = true;
      _aiSuggestion = null;
    });

    try {
      final res = await ApiService().completeMessage(
        text: text,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        receiverUsername: widget.receiverName,
      );

      debugPrint("COMPLETE RESPONSE => $res");

      setState(() {
        _aiSuggestion = res;
      });
    } catch (e) {
      debugPrint("COMPLETE ERROR => $e");
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  // ----------------------------------------------------------
  // SMART REPLIES FETCH
  // ----------------------------------------------------------
  Future<void> _fetchSmartReplies(String lastMessage) async {
    setState(() {
      _smartRepliesLoading = true;
      _smartReplies = null;
    });

    try {
      final replies = await ApiService().getSmartReplies(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        lastMessage: lastMessage,
      );

      if (mounted) {
        setState(() {
          _smartReplies = replies;
        });
      }
    } catch (e) {
      print("fetch smart replies error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _smartRepliesLoading = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // SEND MESSAGE
  // ----------------------------------------------------------
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Buton animasyonu
    _sendBtnAnim.reverse().then((_) => _sendBtnAnim.forward());

    setState(() {
      _analysis = null;
      _smartReplies = null;
    });

    final localMessage = {
      "text": text,
      "isMe": true,
      "time": _formatTime(DateTime.now().toString()),
    };

    setState(() {
      _messages.add(localMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    if (widget.isGroup) {
      _socketService.socket?.emit("send_message", {
        "sender_id": widget.senderId,
        "group_id": widget.receiverId,
        "content": text,
      });
    } else {
      _socketService.sendPrivateMessage(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        content: text,
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ----------------------------------------------------------
  // MESSAGE BUBBLE
  // ----------------------------------------------------------
  Widget _bubble(Map<String, dynamic> msg) {
    final isMe = msg["isMe"] as bool;
    final String senderUsername = msg["sender_username"] ?? "";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 60 : 12,
          right: isMe ? 12 : 60,
          top: 3,
          bottom: 3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.sentBubble : AppTheme.receivedBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grup mesajlarında kullanıcı adı
            if (widget.isGroup && !isMe && senderUsername.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  senderUsername,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: ColorHelper.getPastelColor(senderUsername),
                  ),
                ),
              ),

            // Mesaj içeriği
            msg["image"] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageWidget(msg["image"] as String),
                  )
                : Text(
                    msg["text"],
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),

            // Saat bilgisi - balonun içinde sağ alt
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                msg["time"] ?? "",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    final isHttp =
        imagePath.startsWith("http://") || imagePath.startsWith("https://");
    final isDocs = imagePath.startsWith("docs/");

    if (isHttp || isDocs) {
      final url = isHttp ? imagePath : "${ChatService.baseUrl}/$imagePath";
      return Image.network(
        url,
        width: 200,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(imagePath),
      width: 200,
      fit: BoxFit.cover,
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.chatBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 1. Mesajlar + AI panelleri
          Expanded(
            child: Stack(
              children: [
                // Mesaj listesi
                ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    bottom:
                        (_analysis != null || _aiSuggestion != null) ? 200 : 16,
                    top: 12,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final msg = _messages[i];
                    return _bubble(msg);
                  },
                ),

                // Yüzer AI panelleri
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_analysis != null) _aiPanel(),
                      if (_aiLoading)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryTeal,
                            strokeWidth: 2.5,
                          ),
                        ),
                      if (_aiSuggestion != null)
                        _buildAiSuggestionFloatingPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Smart replies
          if (_smartRepliesLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppTheme.primaryTeal,
              backgroundColor: Colors.transparent,
            ),
          if (_smartReplies != null && _smartReplies!.isNotEmpty)
            _buildSmartRepliesDrawer(),

          // 3. Input bar
          _inputBar(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // APP BAR
  // ----------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.appBarGradient),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: GestureDetector(
            onTap: () {
              if (widget.isGroup) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupInfoScreen(
                      groupId: widget.receiverId,
                      groupName: widget.receiverName,
                    ),
                  ),
                ).then((_) => _loadMessages());
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RelationshipDashboardScreen(
                      senderId: widget.senderId,
                      receiverId: widget.receiverId,
                      receiverName: widget.receiverName,
                    ),
                  ),
                );
              }
            },
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: widget.isGroup
                        ? const LinearGradient(
                            colors: [AppTheme.accentCyan, AppTheme.primaryTeal])
                        : AppTheme.avatarGradient(widget.receiverName),
                  ),
                  child: Center(
                    child: widget.isGroup
                        ? const Icon(Icons.group_rounded,
                            color: Colors.white, size: 20)
                        : Text(
                            AppTheme.initials(widget.receiverName),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.receiverName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (!widget.isGroup && !_isOtherUserTyping)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: const BoxDecoration(
                              color: AppTheme.online,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          widget.isGroup
                              ? "Grup bilgileri için dokun"
                              : (_isOtherUserTyping
                                  ? "Yazıyor..."
                                  : "Çevrimiçi"),
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: _isOtherUserTyping
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam_rounded, color: Colors.white70),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.call_rounded, color: Colors.white70),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // AI ANALYSIS PANEL
  // ----------------------------------------------------------
  Widget _aiPanel() {
    if (_analysis == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppTheme.primaryTeal, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                "AI Analiz",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _analysis = null),
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Chips satırı
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Sentiment chip
              if (_analysis!["sentiment"] != null)
                _analysisChip(
                  icon: ColorHelper.sentimentIcon(_analysis!["sentiment"]),
                  label: _analysis!["sentiment"],
                  color: ColorHelper.sentimentColor(_analysis!["sentiment"]),
                  confidence: _analysis!["sentiment_confidence"],
                ),

              // Message style chip
              if (_analysis!["style"] != null)
                _analysisChip(
                  icon: Icons.style_rounded,
                  label: _analysis!["style"],
                  color: AppTheme.accentCyan,
                ),

              // Relationship style chip
              if (_analysis!["relationship_style"] != null)
                _analysisChip(
                  icon: Icons.people_rounded,
                  label: _analysis!["relationship_style"],
                  color: AppTheme.primaryTeal,
                ),
            ],
          ),

          // Punctuation fix
          if (_analysis!["punctuation_fixed"] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.spellcheck, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _analysis!["punctuation_fixed"],
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _analysisChip({
    required IconData icon,
    required String label,
    required Color color,
    double? confidence,
  }) {
    String text = label;
    if (confidence != null) {
      text += " ${(confidence * 100).toStringAsFixed(0)}%";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // AI SUGGESTION PANEL
  // ----------------------------------------------------------
  Widget _buildAiSuggestionFloatingPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_fix_high,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                "AI Mesaj Önerisi",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              final text = _aiSuggestion!["completion"];
              _messageController.text = text;
              _messageController.selection =
                  TextSelection.fromPosition(TextPosition(offset: text.length));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _aiSuggestion!["completion"] ?? "",
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await ApiService().updateSuggestionStatus(
                      suggestionId: _aiSuggestion!["suggestion_id"],
                      accepted: false);
                  setState(() => _aiSuggestion = null);
                },
                icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                label: Text("Reddet",
                    style: GoogleFonts.inter(color: Colors.grey.shade600)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final text = _aiSuggestion!["completion"];
                  _messageController.text = text;
                  await ApiService().updateSuggestionStatus(
                      suggestionId: _aiSuggestion!["suggestion_id"],
                      accepted: true);
                  setState(() => _aiSuggestion = null);
                },
                icon: const Icon(Icons.check, size: 18),
                label: Text("Kabul Et", style: GoogleFonts.inter()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SMART REPLIES DRAWER
  // ----------------------------------------------------------
  Widget _buildSmartRepliesDrawer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _smartReplies!.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _messageController.text = reply;
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryTeal.withOpacity(0.08),
                          AppTheme.accentCyan.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryTeal.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      reply,
                      style: GoogleFonts.inter(
                        color: AppTheme.darkTeal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // INPUT BAR
  // ----------------------------------------------------------
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ➕ MEDIA
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: AppTheme.primaryTeal, size: 24),
                onPressed: _openMediaSheet,
              ),
            ),

            const SizedBox(width: 8),

            // ✍️ TEXT INPUT
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  onTap: () {
                    Future.delayed(
                        const Duration(milliseconds: 300), _scrollToBottom);
                  },
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Mesaj yaz...",
                    hintStyle: GoogleFonts.inter(
                        color: AppTheme.textHint, fontSize: 15),
                    border: InputBorder.none,
                  ),
                  onChanged: _handleTyping,
                ),
              ),
            ),

            const SizedBox(width: 6),

            // 🤖 AI TEST BUTTON
            Container(
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.auto_awesome_rounded, size: 22),
                color: AppTheme.accentCyan,
                onPressed: _aiLoading ? null : _testComplete,
              ),
            ),

            const SizedBox(width: 6),

            // 📤 SEND BUTTON
            ScaleTransition(
              scale: _sendBtnAnim,
              child: GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // MEDIA SHEET
  // ----------------------------------------------------------
  void _openMediaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Medya Paylaş",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _mediaOption(
                      Icons.camera_alt_rounded, "Kamera", AppTheme.accentCyan, _captureImage),
                  _mediaOption(
                      Icons.photo_library_rounded, "Galeri", AppTheme.primaryTeal, _pickImage),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mediaOption(
      IconData icon, String label, Color color, Future<void> Function() onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            Navigator.pop(context);
            await onTap();
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }

  // ----------------------------------------------------------
  // IMAGE PICK
  // ----------------------------------------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    // Önce ekranda hemen göster (local path)
    setState(() {
      _messages.add({
        "text": "",
        "image": picked.path,
        "isMe": true,
        "time": _formatTime(DateTime.now().toString())
      });
    });

    _scrollToBottom();

    // Sonra backend'e yükle
    await ChatService().uploadMedia(
      senderId: widget.senderId,
      receiverId: widget.isGroup ? 0 : widget.receiverId,
      groupId: widget.isGroup ? widget.receiverId : null,
      filePath: picked.path,
      mediaType: "image",
    );

    // Backend URL geldikten sonra doğru URL ile yeniden yükle
    _loadMessages();
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked == null) return;

    setState(() {
      _messages.add({
        "text": "",
        "image": picked.path,
        "isMe": true,
        "time": _formatTime(DateTime.now().toString())
      });
    });

    _scrollToBottom();

    await ChatService().uploadMedia(
      senderId: widget.senderId,
      receiverId: widget.isGroup ? 0 : widget.receiverId,
      groupId: widget.isGroup ? widget.receiverId : null,
      filePath: picked.path,
      mediaType: "image",
    );

    _loadMessages();
  }
}