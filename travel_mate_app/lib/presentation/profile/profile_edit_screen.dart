import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/domain/entities/user_profile.dart';
import 'package:travel_mate_app/domain/usecases/get_user_profile.dart';
import 'package:travel_mate_app/domain/usecases/update_user_profile.dart';
import 'package:travel_mate_app/domain/usecases/upload_profile_image.dart';
import 'package:travel_mate_app/data/models/user_profile_model.dart';

/// 프로필 수정 화면. 닉네임·소개·이미지 등 편집.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _preferredDestinationsController = TextEditingController(); // Renamed for clarity

  File? _pickedImage;
  bool _isLoading = false;
  String? _errorMessage;

  String? _currentProfileImageUrl;
  String? _gender;
  String? _ageRange;
  final List<String> _selectedTravelStyles = [];
  final List<String> _selectedInterests = [];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _ageRanges = ['10s', '20s', '30s', '40s', '50s+', 'N/A'];
  final List<String> _availableTravelStyles = ['Adventure', 'Relaxation', 'Cultural', 'Foodie', 'Budget-friendly', 'Luxury', 'Solo Traveler', 'Group Traveler'];
  final List<String> _availableInterests = ['Nature', 'History', 'Art', 'Beach', 'Mountains', 'City Exploration', 'Photography', 'Shopping', 'Nightlife', 'Wellness'];


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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in.');
      }
      final getUserProfile = Provider.of<GetUserProfile>(context, listen: false);
      final profile = await getUserProfile.execute(currentUser.uid);

      _nicknameController.text = profile.nickname;
      _bioController.text = profile.bio ?? '';
      _preferredDestinationsController.text = profile.preferredDestinations.join(', ');
      _currentProfileImageUrl = profile.profileImageUrl;
      _gender = profile.gender;
      _ageRange = profile.ageRange;
      _selectedTravelStyles.addAll(profile.travelStyles);
      _selectedInterests.addAll(profile.interests);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile data: ${e.toString()}';
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
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('User not logged in.');
        }

        String? newImageUrl = _currentProfileImageUrl;
        if (_pickedImage != null) {
          final uploadProfileImage = Provider.of<UploadProfileImage>(context, listen: false);
          newImageUrl = await uploadProfileImage.execute(currentUser.uid, _pickedImage!.path);
        }

        final updatedProfile = UserProfileModel( // Using UserProfileModel to leverage toJson
          userId: currentUser.uid,
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
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          context.pop(); // Go back to profile detail screen
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to save profile: ${e.toString()}';
        });
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
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
                              backgroundImage: _pickedImage != null
                                  ? FileImage(_pickedImage!)
                                  : (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty
                                      ? NetworkImage(_currentProfileImageUrl!) as ImageProvider
                                      : const AssetImage('images/default_avatar.png')
                                  ),
                              child: _pickedImage == null && (_currentProfileImageUrl == null || _currentProfileImageUrl!.isEmpty)
                                  ? Icon(Icons.person, size: 70, color: AppColors.grey)
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
                        labelText: 'Nickname',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your nickname';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
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
                      validator: (value) => value == null ? 'Please select your gender' : null,
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    DropdownButtonFormField<String>(
                      value: _ageRange,
                      decoration: const InputDecoration(
                        labelText: 'Age Range',
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
                      validator: (value) => value == null ? 'Please select your age range' : null,
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    TextFormField(
                      controller: _preferredDestinationsController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Destinations (comma-separated)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLarge),
                    Text(
                      'Travel Styles',
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
                      'Interests',
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
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
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
                                'Save Profile',
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
