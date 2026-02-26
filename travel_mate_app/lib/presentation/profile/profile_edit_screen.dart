import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/responsive.dart';
import 'package:travel_mate_app/core/services/auth_service.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/presentation/common/profile_avatar_widget.dart';
import 'package:travel_mate_app/domain/usecases/get_user_profile.dart';
import 'package:travel_mate_app/domain/usecases/update_user_profile.dart';
import 'package:travel_mate_app/domain/usecases/upload_profile_image.dart';
import 'package:travel_mate_app/data/models/user_profile_model.dart';

/// 프로필 수정 화면. 닉네임·소개·이미지 등 편집.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _preferredDestinationsController = TextEditingController(); // Renamed for clarity

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isLoading = false;
  String? _errorMessage;

  String? _currentProfileImageUrl;
  String? _gender;
  String? _ageRange;
  final List<String> _selectedTravelStyles = [];
  final List<String> _selectedInterests = [];

  final List<String> _genders = ['남성', '여성', '기타'];
  final List<String> _ageRanges = ['10대', '20대', '30대', '40대', '50대 이상', '비공개'];
  final List<String> _availableTravelStyles = ['모험', '휴양', '문화', '맛집', '저렴한 여행', '럭셔리', '혼자 여행', '그룹 여행'];
  final List<String> _availableInterests = ['자연', '역사', '예술', '해변', '산', '도시 탐험', '사진', '쇼핑', '나이트라이프', '웰니스'];

  static const Map<String, String> _travelStyleEnToKo = {
    'Adventure': '모험', 'Relaxation': '휴양', 'Cultural': '문화', 'Foodie': '맛집',
    'Budget-friendly': '저렴한 여행', 'Luxury': '럭셔리', 'Solo Traveler': '혼자 여행', 'Group Traveler': '그룹 여행',
  };
  static const Map<String, String> _interestEnToKo = {
    'Nature': '자연', 'History': '역사', 'Art': '예술', 'Beach': '해변', 'Mountains': '산',
    'City Exploration': '도시 탐험', 'Photography': '사진', 'Shopping': '쇼핑', 'Nightlife': '나이트라이프', 'Wellness': '웰니스',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialProfileData();
  }

  Future<void> _loadInitialProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = await authService.getCurrentBackendUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }
      final getUserProfile = Provider.of<GetUserProfile>(context, listen: false);
      final profile = await getUserProfile.execute(userId);

      _nicknameController.text = profile.nickname;
      _bioController.text = profile.bio ?? '';
      _preferredDestinationsController.text = profile.preferredDestinations.join(', ');
      _currentProfileImageUrl = profile.profileImageUrl;
      _gender = profile.gender != null && _genders.contains(profile.gender) ? profile.gender! : null;
      _ageRange = profile.ageRange != null && _ageRanges.contains(profile.ageRange) ? profile.ageRange! : null;
      _selectedTravelStyles.addAll(profile.travelStyles.map((s) => _travelStyleEnToKo[s] ?? s).where((s) => _availableTravelStyles.contains(s)).toList());
      _selectedInterests.addAll(profile.interests.map((s) => _interestEnToKo[s] ?? s).where((s) => _availableInterests.contains(s)).toList());
    } catch (e) {
      setState(() {
        _errorMessage = '프로필 로드 실패: ${e.toString()}';
        developer.log('프로필 수정 에러: $_errorMessage\n${StackTrace.current}', name: 'ProfileEdit', level: 1000);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
        _pickedImageBytes = null;
      });
      try {
        final bytes = await pickedFile.readAsBytes();
        if (mounted) setState(() => _pickedImageBytes = bytes);
      } catch (_) {
        if (mounted) setState(() => _pickedImageBytes = null);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = await authService.getCurrentBackendUserId();
        if (userId == null || userId.isEmpty) {
          throw Exception('로그인이 필요합니다.');
        }

        String? newImageUrl = _currentProfileImageUrl;
        if (_pickedImage != null) {
          final uploadProfileImage = Provider.of<UploadProfileImage>(context, listen: false);
          newImageUrl = await uploadProfileImage.execute(userId, _pickedImage!);
        }

        final updatedProfile = UserProfileModel( // Using UserProfileModel to leverage toJson
          userId: userId,
          nickname: _nicknameController.text.trim(),
          bio: _bioController.text.trim(),
          gender: _gender,
          ageRange: _ageRange,
          profileImageUrl: newImageUrl,
          travelStyles: _selectedTravelStyles,
          interests: _selectedInterests,
          preferredDestinations: _preferredDestinationsController.text.split(',').map((e) => e.trim()).toList(),
        );

        final updateUserProfile = Provider.of<UpdateUserProfile>(context, listen: false);
        await updateUserProfile.execute(updatedProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로필이 저장되었습니다.')),
          );
          context.go('/profile');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = '프로필 저장 실패: ${e.toString()}';
          });
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _preferredDestinationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: '프로필 수정'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.value(context, compact: AppConstants.paddingMedium, medium: AppConstants.paddingLarge, expanded: AppConstants.paddingLarge),
                vertical: AppConstants.paddingMedium,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: AppColors.lightGrey,
                              backgroundImage: _pickedImageBytes != null
                                  ? MemoryImage(_pickedImageBytes!)
                                  : (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty
                                      ? NetworkImage(_currentProfileImageUrl!) as ImageProvider
                                      : null),
                              child: _pickedImageBytes == null && (_currentProfileImageUrl == null || _currentProfileImageUrl!.isEmpty)
                                  ? Icon(ProfileAvatar.iconForGender(_gender), size: 70, color: AppColors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.accent,
                                child: Icon(Icons.camera_alt, color: AppColors.onPrimary, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLarge),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력하세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: '소개',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    DropdownButtonFormField<String>(
                      initialValue: _gender != null && _genders.contains(_gender) ? _gender : null,
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
                          _gender = newValue;
                        });
                      },
                      validator: (value) => value == null ? '성별을 선택하세요' : null,
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    DropdownButtonFormField<String>(
                      initialValue: _ageRange != null && _ageRanges.contains(_ageRange) ? _ageRange : null,
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
                          _ageRange = newValue;
                        });
                      },
                      validator: (value) => value == null ? '연령대를 선택하세요' : null,
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    TextFormField(
                      controller: _preferredDestinationsController,
                      decoration: const InputDecoration(
                        labelText: '선호 지역 (쉼표로 구분)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLarge),
                    Text(
                      '여행 스타일',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
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
                    const SizedBox(height: AppConstants.spacingLarge),
                    Text(
                      '관심사',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
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
                    const SizedBox(height: AppConstants.spacingLarge),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                        child: SelectableText(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              child: Text(
                                '프로필 저장',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
