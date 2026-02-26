import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/domain/entities/chat_message.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';
import 'package:travel_mate_app/domain/usecases/get_chat_messages.dart';
import 'package:travel_mate_app/domain/usecases/send_chat_message.dart';

/// 채팅방 화면. 메시지 스트림 표시 및 발송.
class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String? receiverNickname;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
    this.receiverNickname,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false; // Renamed from _isLoading to be more specific
  String? _errorMessage;

  User? _currentUser;
  String? _myBackendId;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = context.read<AuthService>();
      final id = await authService.getCurrentBackendUserId();
      if (mounted) setState(() => _myBackendId = id);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          // Scrolled to bottom
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    if (_currentUser == null) {
      setState(() {
        _errorMessage = '로그인한 후 메시지를 보낼 수 있습니다.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final myId = _myBackendId;
      if (myId == null || myId.isEmpty) {
        setState(() => _errorMessage = '사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해 주세요.');
        return;
      }
      final sendChatMessage = Provider.of<SendChatMessage>(context, listen: false);
      final ids = widget.chatRoomId.split('_');
      final receiverId = ids.where((id) => id != myId).isEmpty
          ? (ids.isNotEmpty ? ids.first : '')
          : ids.firstWhere((id) => id != myId);
      if (receiverId.isEmpty) {
        setState(() {
          _errorMessage = '대화 상대를 확인할 수 없습니다.';
        });
        return;
      }

      await sendChatMessage.execute(
        chatRoomId: widget.chatRoomId,
        senderId: myId,
        receiverId: receiverId,
        content: _messageController.text.trim(),
      );

      if (mounted) {
        _messageController.clear();
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '메시지 전송 실패: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final getChatMessages = Provider.of<GetChatMessages>(context);

    return Scaffold(
      appBar: AppAppBar(title: widget.receiverNickname ?? '채팅'),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: getChatMessages.execute(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Text(
                        'Error loading messages: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Start a conversation!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }

                final messages = snapshot.data!;
                // Ensure messages are sorted by time for correct display
                messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

                // Scroll to bottom after new messages are loaded
                // This is a simple approach, more sophisticated solution might involve a `NotificationListener`
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());


                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message.senderId == _myBackendId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primaryLight.withOpacity(0.8) : AppColors.lightGrey.withOpacity(0.8),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isMe ? AppColors.onPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: isMe ? AppColors.onPrimary.withOpacity(0.7) : AppColors.textSecondary.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.lightGrey.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium, vertical: AppConstants.paddingSmall),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSmall),
                _isSending
                    ? const CircularProgressIndicator()
                    : FloatingActionButton(
                        onPressed: _sendMessage,
                        mini: true,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.send, color: AppColors.onPrimary),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
