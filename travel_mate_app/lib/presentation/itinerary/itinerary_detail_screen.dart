import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/domain/usecases/get_itinerary.dart';
import 'package:travel_mate_app/domain/usecases/delete_itinerary.dart';
import 'package:travel_mate_app/presentation/common/report_button_widget.dart';

/// 일정 상세 화면. 지도·일차별 활동·수정/삭제/신고.
class ItineraryDetailScreen extends StatefulWidget {
  final String itineraryId; // ID of the itinerary to display

  const ItineraryDetailScreen({Key? key, required this.itineraryId}) : super(key: key);

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Itinerary? _itinerary;
  String? _currentUserId;

  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  LatLng _center = const LatLng(37.5665, 126.9780); // Default to Seoul

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _loadItineraryDetails();
  }

  Future<void> _loadItineraryDetails() async {
    if (widget.itineraryId.isEmpty) {
      setState(() {
        _errorMessage = '일정을 찾을 수 없습니다.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      _currentUserId = await authService.getCurrentBackendUserId();
      final getItinerary = Provider.of<GetItinerary>(context, listen: false);
      final fetchedItinerary = await getItinerary.execute(widget.itineraryId);

      if (mounted) {
        setState(() {
          _itinerary = fetchedItinerary;
        _isLoading = false;
        if (_itinerary != null && _itinerary!.mapData.isNotEmpty) {
          _markers = _itinerary!.mapData
              .where((data) {
                final lat = data['latitude'];
                final lng = data['longitude'];
                return lat != null && lng != null;
              })
              .map((data) {
                final lat = data['latitude']!;
                final lng = data['longitude']!;
                final latLng = LatLng(lat, lng);
                return Marker(
                  markerId: MarkerId(latLng.toString()),
                  position: latLng,
                  infoWindow: InfoWindow(title: '위치: ${latLng.latitude.toStringAsFixed(2)}, ${latLng.longitude.toStringAsFixed(2)}'),
                );
              })
              .toSet();
          if (_markers.isNotEmpty) {
            _center = _markers.first.position;
          }
        }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '일정을 불러오지 못했습니다: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItinerary() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text(
          '이 일정을 삭제하시겠습니까? 삭제된 일정은 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final deleteItinerary = Provider.of<DeleteItinerary>(context, listen: false);
        await deleteItinerary.execute(widget.itineraryId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 삭제되었습니다.')),
          );
          context.go('/itinerary'); // Go back to itinerary list
        }
      } catch (e) {
        setState(() {
          _errorMessage = '일정 삭제 실패: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;
    final isAuthor = _itinerary?.authorId == currentUserId;

    return Scaffold(
      appBar: AppAppBar(
        title: _itinerary?.title ?? '일정',
        actions: [
          if (isAuthor) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.go('/itinerary/${widget.itineraryId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteItinerary,
            ),
          ],
          if (!isAuthor && _itinerary != null)
            ReportButtonWidget(entityType: ReportEntityType.itinerary, entityId: widget.itineraryId),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _itinerary == null
                  ? Center(
                      child: Text(
                        '일정을 찾을 수 없습니다.',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _itinerary!.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppConstants.spacingSmall),
                          Text(
                            '${_itinerary!.startDate.toLocal().toString().split(' ')[0]} ~ ${_itinerary!.endDate.toLocal().toString().split(' ')[0]}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                          if (_itinerary!.authorNickname != null || _itinerary!.authorId.isNotEmpty) ...[
                            const SizedBox(height: AppConstants.spacingSmall),
                            Text(
                              '작성자 ${_itinerary!.authorNickname ?? _itinerary!.authorId}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: AppConstants.spacingMedium),
                          if (_itinerary!.imageUrls.isNotEmpty)
                            SizedBox(
                              height: 200, // Adjust height as needed
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _itinerary!.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                      child: CachedNetworkImage(
                                        imageUrl: _itinerary!.imageUrls[index],
                                        width: 250, // Adjust width as needed
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          Text(
                            _itinerary!.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppConstants.spacingLarge),
                          Text(
                            '지도 보기',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              border: Border.all(color: AppColors.lightGrey),
                            ),
                            child: GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(
                                target: _center,
                                zoom: 11.0,
                              ),
                              markers: _markers,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingLarge),
                          Text(
                            '일별 일정',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          Text('아직 일별 일정이 없습니다.', style: Theme.of(context).textTheme.bodyLarge),
                          // TODO: Integrate comments section here
                          const SizedBox(height: AppConstants.spacingLarge),
                          Text(
                            '댓글',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          Text('아직 댓글이 없습니다.', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
    );
  }
}
