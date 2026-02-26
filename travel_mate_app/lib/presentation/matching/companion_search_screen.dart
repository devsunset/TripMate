import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/app/responsive.dart';
import 'package:travel_mate_app/domain/entities/paginated_result.dart';
import 'package:travel_mate_app/domain/entities/user_profile.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/presentation/common/profile_avatar_widget.dart';
import 'package:travel_mate_app/domain/usecases/search_companions_usecase.dart';
import 'package:travel_mate_app/presentation/common/empty_state_widget.dart';

/// 동행 검색 화면.
///
/// [검색 조건]
/// - 목적지: preferredDestinations에 포함된 사용자 (서버: LIKE %목적지%)
/// - 검색어: 닉네임 또는 자기소개(bio)에 포함 (서버: LIKE %검색어%)
/// - 성별: 선택 시 일치만 (무관이면 조건 없음)
/// - 연령대: 선택 시 일치만 (무관이면 조건 없음)
/// - 여행 스타일/관심사: 선택한 항목을 가진 사용자만 (서버: Tag 또는 프로필 JSON 기준)
/// - 실제 요청 쿼리·결과는 디버그 로그([동행 검색] 요청 쿼리 / 응답) 및 백엔드 콘솔([동행 검색] 수신 쿼리 / 질의 조건 / 질의 결과)에서 확인 가능.
class CompanionSearchScreen extends StatefulWidget {
  const CompanionSearchScreen({super.key});

  @override
  State<CompanionSearchScreen> createState() => _CompanionSearchScreenState();
}

class _CompanionSearchScreenState extends State<CompanionSearchScreen> {
  static const int _pageSize = 20;
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _searchKeywordController = TextEditingController();
  final ScrollController _resultsScrollController = ScrollController();

  String? _selectedGender;
  String? _selectedAgeRange;
  final List<String> _selectedTravelStyles = [];
  final List<String> _selectedInterests = [];
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _noResults = false;
  List<UserProfile> _searchResults = [];
  int _total = 0;

  bool get _hasMore => _searchResults.length < _total;

  final List<String> _genders = ['남성', '여성', '기타', '무관'];
  final List<String> _ageRanges = ['10대', '20대', '30대', '40대', '50대 이상', '무관'];
  final List<String> _availableTravelStyles = ['모험', '휴양', '문화', '맛집', '저렴한 여행', '럭셔리', '혼자 여행', '그룹 여행'];
  final List<String> _availableInterests = ['자연', '역사', '예술', '해변', '산', '도시 탐험', '사진', '쇼핑', '나이트라이프', '웰니스'];

  @override
  void initState() {
    super.initState();
    _resultsScrollController.addListener(_onResultsScroll);
  }

  @override
  void dispose() {
    _resultsScrollController.removeListener(_onResultsScroll);
    _resultsScrollController.dispose();
    _destinationController.dispose();
    _searchKeywordController.dispose();
    super.dispose();
  }

  void _onResultsScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading || _searchResults.isEmpty) return;
    final pos = _resultsScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreCompanions();
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 years from now
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null && (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _searchCompanions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noResults = false;
      _searchResults = [];
      _total = 0;
    });

    try {
      final usecase = Provider.of<SearchCompanionsUsecase>(context, listen: false);
      final result = await _executeSearch(usecase, limit: _pageSize, offset: 0);

      if (mounted) {
        setState(() {
          _searchResults = result.items;
          _total = result.total;
          _isLoading = false;
          _noResults = result.items.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '동행 검색에 실패했습니다. 다시 시도해 주세요.';
          _isLoading = false;
          _noResults = false;
        });
      }
    }
  }

  Future<void> _loadMoreCompanions() async {
    if (!_hasMore || _isLoadingMore || _isLoading || _searchResults.isEmpty) return;
    setState(() => _isLoadingMore = true);

    try {
      final usecase = Provider.of<SearchCompanionsUsecase>(context, listen: false);
      final result = await _executeSearch(usecase, limit: _pageSize, offset: _searchResults.length);

      if (mounted) {
        final nextItems = result.items;
        setState(() {
          _searchResults = [..._searchResults, ...nextItems];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<PaginatedResult<UserProfile>> _executeSearch(SearchCompanionsUsecase usecase, {required int limit, required int offset}) {
    final destination = _destinationController.text.trim();
    final keyword = _searchKeywordController.text.trim();
    final gender = _selectedGender != null && _selectedGender != '무관' ? _selectedGender : null;
    final ageRange = _selectedAgeRange != null && _selectedAgeRange != '무관' ? _selectedAgeRange : null;
    final travelStyles = _selectedTravelStyles.isEmpty ? null : List<String>.from(_selectedTravelStyles);
    final interests = _selectedInterests.isEmpty ? null : List<String>.from(_selectedInterests);
    return usecase.execute(
      destination: destination.isEmpty ? null : destination,
      keyword: keyword.isEmpty ? null : keyword,
      gender: gender,
      ageRange: ageRange,
      travelStyles: travelStyles,
      interests: interests,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: '동행 찾기',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchCompanions,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
              vertical: AppConstants.paddingMedium,
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: '목적지',
                    hintText: '예: 파리, 서울',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                TextFormField(
                  controller: _searchKeywordController,
                  decoration: const InputDecoration(
                    labelText: '키워드 (닉네임, 소개)',
                    hintText: '예: 여행, 사진',
                    prefixIcon: Icon(Icons.text_fields),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender != null && _genders.contains(_selectedGender) ? _selectedGender : null,
                        decoration: const InputDecoration(
                          labelText: '성별',
                          prefixIcon: Icon(Icons.wc),
                        ),
                        items: _genders.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMedium),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedAgeRange != null && _ageRanges.contains(_selectedAgeRange) ? _selectedAgeRange : null,
                        decoration: const InputDecoration(
                          labelText: '연령대',
                          prefixIcon: Icon(Icons.timelapse),
                        ),
                        items: _ageRanges.map((String age) {
                          return DropdownMenuItem<String>(
                            value: age,
                            child: Text(age),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedAgeRange = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                ListTile(
                  title: Text(
                    _startDate == null && _endDate == null
                        ? '여행 기간 선택'
                        : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                  ),
                  leading: const Icon(Icons.calendar_today),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _selectDateRange(context),
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '여행 스타일',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Wrap(
                  spacing: AppConstants.spacingSmall,
                  runSpacing: AppConstants.spacingSmall,
                  children: _availableTravelStyles.map((style) {
                    final isSelected = _selectedTravelStyles.contains(style);
                    return FilterChip(
                      label: Text(style),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTravelStyles.add(style);
                          } else {
                            _selectedTravelStyles.remove(style);
                          }
                        });
                      },
                      selectedColor: AppColors.accent.withOpacity(0.3),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '관심사',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Wrap(
                  spacing: AppConstants.spacingSmall,
                  runSpacing: AppConstants.spacingSmall,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                      selectedColor: AppColors.accent.withOpacity(0.3),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _searchCompanions,
                          child: const Text('검색'),
                        ),
                      ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _noResults
                    ? EmptyStateWidget(
                        icon: Icons.person_search_rounded,
                        title: '검색 조건에 맞는 동행이 없어요',
                        subtitle: '조건을 바꿔 보시거나 잠시 후 다시 검색해 보세요.',
                      )
                    : _errorMessage != null
                        ? EmptyStateWidget(
                            icon: Icons.cloud_off_rounded,
                            title: _errorMessage!,
                            isError: true,
                            onRetry: _searchCompanions,
                          )
                        : _searchResults.isEmpty
                            ? EmptyStateWidget(
                                icon: Icons.search_rounded,
                                title: '동행을 검색해 보세요',
                                subtitle: '목적지, 성별, 연령대 등을 선택한 뒤 검색 버튼을 눌러 주세요.',
                              )
                            : ListView.builder(
                            controller: _resultsScrollController,
                            itemCount: _searchResults.length + (_hasMore && _isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _searchResults.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final user = _searchResults[index];
                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: Responsive.value(context, compact: AppConstants.paddingSmall, medium: AppConstants.paddingMedium, expanded: AppConstants.paddingMedium),
                                  vertical: AppConstants.paddingSmall,
                                ),
                                elevation: 1,
                                child: ListTile(
                                  leading: ProfileAvatar(profileImageUrl: user.profileImageUrl, gender: user.gender, radius: 20),
                                  title: Text(user.nickname),
                                  subtitle: Text('${user.gender ?? ''} ${user.ageRange ?? ''}\n${user.bio ?? ''}'.trim()),
                                  isThreeLine: true,
                                  onTap: () {
                                    if (user.userId.isNotEmpty) {
                                      context.push('/users/${Uri.encodeComponent(user.userId)}');
                                    }
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
