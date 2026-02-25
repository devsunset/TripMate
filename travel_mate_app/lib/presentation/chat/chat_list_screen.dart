import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/domain/entities/chat_room_info.dart';
import 'package:travel_mate_app/domain/usecases/get_chat_rooms.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/presentation/common/empty_state_widget.dart';

/// 채팅방 목록 화면. 신청한/신청받은 채팅방만 표시(채팅방 찾기 조건 없음).
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoomInfo> _rooms = [];
  bool _loading = true;
  String? _error;

  String _timeAgo(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금';
  }

  Future<void> _loadRooms() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = await authService.getCurrentBackendUserId();
    if (currentUserId == null || currentUserId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final getChatRooms = Provider.of<GetChatRooms>(context, listen: false);
      final rooms = await getChatRooms.execute(currentUserId);
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '채팅 목록을 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRooms());
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: const AppAppBar(title: '채팅'),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return Scaffold(
      appBar: const AppAppBar(title: '채팅'),
      body: RefreshIndicator(
        onRefresh: _loadRooms,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? EmptyStateWidget(
                    icon: Icons.cloud_off_rounded,
                    title: _error!,
                    isError: true,
                    onRetry: _loadRooms,
                  )
                : _rooms.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: '채팅방이 없습니다',
                        subtitle: '채팅을 요청한 대화나 신청받은 대화가 여기 표시됩니다. 동행 찾기에서 상대를 선택해 채팅 요청을 보내 보세요.',
                        actionLabel: '동행 찾기',
                        onAction: () => context.go('/matching/search'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
                        itemCount: _rooms.length,
                        itemBuilder: (context, index) {
                          final room = _rooms[index];
                          final displayName = room.partnerNickname ?? room.otherParticipantId;
                          return _ChatRoomTile(
                            room: room,
                            timeAgo: _timeAgo(room.lastMessageAt),
                            onTap: () {
                              context.push(
                                '/chat/room/${Uri.encodeComponent(room.chatRoomId)}',
                                extra: displayName,
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoomInfo room;
  final String timeAgo;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.room,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = room.partnerNickname ?? room.otherParticipantId;
    final imageUrl = room.partnerProfileImageUrl;
    final label = room.isRequestedByMe ? '내가 신청' : '신청받음';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: AppConstants.paddingExtraSmall,
      ),
      elevation: 0.5,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
              ? NetworkImage(imageUrl)
              : null,
          child: (imageUrl == null || imageUrl.isEmpty)
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        title: Row(
          children: [
            Expanded(child: Text(displayName)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: room.isRequestedByMe
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: room.isRequestedByMe ? AppColors.primary : AppColors.secondary,
                    ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          room.lastMessage.isEmpty ? '(메시지 없음)' : room.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          timeAgo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        onTap: onTap,
      ),
    );
  }
}
