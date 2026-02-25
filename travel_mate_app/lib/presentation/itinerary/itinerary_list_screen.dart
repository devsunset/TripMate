import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/domain/usecases/get_itineraries.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/presentation/common/empty_state_widget.dart';

/// 일정 목록 화면. 일정 생성·상세 이동.
class ItineraryListScreen extends StatefulWidget {
  final String backgroundImageUrl;

  const ItineraryListScreen({Key? key, required this.backgroundImageUrl}) : super(key: key);

  @override
  State<ItineraryListScreen> createState() => _ItineraryListScreenState();
}

class _ItineraryListScreenState extends State<ItineraryListScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmpty = false;
  List<Itinerary> _itineraries = [];

  @override
  void initState() {
    super.initState();
    _loadItineraries();
  }

  Future<void> _loadItineraries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isEmpty = false;
    });

    try {
      final getItineraries = Provider.of<GetItineraries>(context, listen: false);
      final fetchedItineraries = await getItineraries.execute();

      setState(() {
        _itineraries = fetchedItineraries;
        _isLoading = false;
        _isEmpty = _itineraries.isEmpty;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '일정 목록을 불러오지 못했습니다.';
        _isLoading = false;
        _isEmpty = false;
      });
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.network(
              widget.backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1E1E32)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E1E32).withOpacity(0.25),
                    const Color(0xFF1E1E32).withOpacity(0.45),
                    const Color(0xFF1E1E32).withOpacity(0.65),
                  ],
                ),
              ),
            ),
          ),
          _isLoading
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
                    itemCount: _itineraries.length,
                    itemBuilder: (context, index) {
                      final itinerary = _itineraries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
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
        ],
      ),
    );
  }
}
