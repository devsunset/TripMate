import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/domain/usecases/get_itineraries.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/app/responsive.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/presentation/common/empty_state_widget.dart';

/// 일정 목록 화면. 일정 생성·상세 이동.
class ItineraryListScreen extends StatefulWidget {
  const ItineraryListScreen({super.key});

  @override
  State<ItineraryListScreen> createState() => _ItineraryListScreenState();
}

class _ItineraryListScreenState extends State<ItineraryListScreen> {
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _isEmpty = false;
  List<Itinerary> _itineraries = [];
  int _total = 0;

  bool get _hasMore => _itineraries.length < _total;

  @override
  void initState() {
    super.initState();
    _loadItineraries();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadItineraries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isEmpty = false;
      _itineraries = [];
      _total = 0;
    });

    try {
      final getItineraries = Provider.of<GetItineraries>(context, listen: false);
      final result = await getItineraries.execute(limit: _pageSize, offset: 0);

      if (mounted) {
        setState(() {
          _itineraries = result.items;
          _total = result.total;
          _isLoading = false;
          _isEmpty = _itineraries.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '일정 목록을 불러오지 못했습니다.';
          _isLoading = false;
          _isEmpty = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _itineraries.isEmpty) return;
    setState(() => _isLoadingMore = true);

    try {
      final getItineraries = Provider.of<GetItineraries>(context, listen: false);
      final result = await getItineraries.execute(limit: _pageSize, offset: _itineraries.length);

      if (mounted) {
        setState(() {
          _itineraries = [..._itineraries, ...result.items];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: '일정',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/itinerary/new'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEmpty
              ? EmptyStateWidget(
                  icon: Icons.calendar_month_rounded,
                  title: '아직 공유된 일정이 없어요',
                  subtitle: '여행 계획을 올려 보세요!',
                  actionLabel: '일정 만들기',
                  onAction: () => context.go('/itinerary/new'),
                )
              : _errorMessage != null
                  ? EmptyStateWidget(
                      icon: Icons.cloud_off_rounded,
                      title: _errorMessage!,
                      isError: true,
                      onRetry: _loadItineraries,
                    )
                  : RefreshIndicator(
                  onRefresh: _loadItineraries,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
                      right: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
                      bottom: MediaQuery.paddingOf(context).bottom + 8,
                    ),
                    itemCount: _itineraries.length + (_hasMore && _isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _itineraries.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final itinerary = _itineraries[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
                            vertical: AppConstants.paddingSmall),
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: ListTile(
                          leading: itinerary.imageUrls.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(itinerary.imageUrls.first),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.travel_explore),
                                ),
                          title: Text(itinerary.title),
                          subtitle: Text('${itinerary.startDate.toLocal().toString().split(' ')[0]} ~ ${itinerary.endDate.toLocal().toString().split(' ')[0]}${itinerary.authorNickname != null ? ' · ${itinerary.authorNickname}' : ''}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            context.go('/itinerary/${itinerary.id}'); // Navigate to itinerary detail
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
