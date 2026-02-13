import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'package:travel_mate_app/core/io_stub/file_stub.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_mate_app/core/io_stub/picked_image_widget_io.dart' if (dart.library.html) 'package:travel_mate_app/core/io_stub/picked_image_widget_web.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';
import 'package:travel_mate_app/domain/entities/itinerary.dart';
import 'package:travel_mate_app/domain/usecases/create_itinerary.dart';
import 'package:travel_mate_app/domain/usecases/update_itinerary.dart';
import 'package:travel_mate_app/domain/usecases/upload_itinerary_image.dart';
import 'package:travel_mate_app/domain/usecases/get_itinerary.dart';
import 'package:travel_mate_app/data/models/itinerary_model.dart';

/// 일정 작성·수정 화면. itineraryId가 null이면 새 일정, 있으면 수정.
class ItineraryWriteScreen extends StatefulWidget {
  final String? itineraryId;

  const ItineraryWriteScreen({Key? key, this.itineraryId}) : super(key: key);

  @override
  State<ItineraryWriteScreen> createState() => _ItineraryWriteScreenState();
}

class _ItineraryWriteScreenState extends State<ItineraryWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<File> _pickedImages = [];
  List<String> _existingImageUrls = []; // For editing existing itinerary

  bool _isLoading = false;
  String? _errorMessage;
  Itinerary? _loadedItinerary; // When editing, store loaded itinerary for createdAt etc.

  // For map
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  LatLng _center = const LatLng(37.5665, 126.9780); // Default to Seoul

  @override
  void initState() {
    super.initState();
    if (widget.itineraryId != null) {
      _loadItineraryForEditing();
    }
  }

  Future<void> _loadItineraryForEditing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getItinerary = Provider.of<GetItinerary>(context, listen: false);
      final fetchedItinerary = await getItinerary.execute(widget.itineraryId!);
      _loadedItinerary = fetchedItinerary;

      _titleController.text = fetchedItinerary.title;
      _descriptionController.text = fetchedItinerary.description;
      _startDate = fetchedItinerary.startDate;
      _endDate = fetchedItinerary.endDate;
      _existingImageUrls = List.from(fetchedItinerary.imageUrls);
      _markers = fetchedItinerary.mapData.map((data) {
        final latLng = LatLng(data['latitude']!, data['longitude']!);
        return Marker(
          markerId: MarkerId(latLng.toString()),
          position: latLng,
          infoWindow: InfoWindow(title: 'Location: ${latLng.latitude.toStringAsFixed(2)}, ${latLng.longitude.toStringAsFixed(2)}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      }).toSet();
      if (_markers.isNotEmpty) {
        _center = _markers.first.position;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load itinerary for editing: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      List<File> compressedFiles = [];
      for (XFile image in pickedFiles) {
        final filePath = image.path;
        final targetPath = '${filePath}_compressed.jpg';
        final compressedImage = await FlutterImageCompress.compressAndGetFile(
          filePath,
          targetPath,
          quality: 80,
          minWidth: 1024,
          minHeight: 1024,
          format: CompressFormat.jpeg,
        );
        if (compressedImage != null) {
          compressedFiles.add(File(compressedImage.path));
        }
      }

      setState(() {
        _pickedImages.addAll(compressedFiles);
      });
    }
  }

  void _removePickedImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  void _removeExistingImage(String url) {
    setState(() {
      _existingImageUrls.remove(url);
    });
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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _addMarker(LatLng latLng) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(latLng.toString()),
          position: latLng,
          infoWindow: InfoWindow(title: 'Location: ${latLng.latitude.toStringAsFixed(2)}, ${latLng.longitude.toStringAsFixed(2)}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  Future<void> _submitItinerary() async {
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
        if (_startDate == null || _endDate == null) {
          throw Exception('Please select a start and end date.');
        }

        // 1. 새 이미지를 백엔드에 업로드
        List<String> uploadedImageUrls = [];
        final uploadItineraryImage = Provider.of<UploadItineraryImage>(context, listen: false);
        for (File image in _pickedImages) {
          final imageUrl = await uploadItineraryImage.execute(widget.itineraryId ?? currentUser.uid, image.path); // Use itineraryId or current user UID for path
          uploadedImageUrls.add(imageUrl);
        }

        // Combine existing and new image URLs
        List<String> allImageUrls = [..._existingImageUrls, ...uploadedImageUrls];

        // 2. Create Itinerary entity
        final ItineraryModel itinerary = ItineraryModel(
          id: widget.itineraryId ?? '', // If new, backend will assign ID
          authorId: currentUser.uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          imageUrls: allImageUrls,
          mapData: _markers.map((e) => {'latitude': e.position.latitude, 'longitude': e.position.longitude}).toList(), // Example map data
          createdAt: _loadedItinerary?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 3. Call CreateItinerary or UpdateItinerary usecase
        if (widget.itineraryId == null) {
          final createItinerary = Provider.of<CreateItinerary>(context, listen: false);
          await createItinerary.execute(itinerary);
        } else {
          final updateItinerary = Provider.of<UpdateItinerary>(context, listen: false);
          await updateItinerary.execute(itinerary);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.itineraryId == null ? 'Itinerary created successfully!' : 'Itinerary updated successfully!')),
          );
          context.pop(); // Go back to itinerary list screen
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to submit itinerary: ${e.toString()}';
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
    _titleController.dispose();
    _descriptionController.dispose();
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: widget.itineraryId == null ? '일정 만들기' : '일정 수정'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    ListTile(
                      title: Text(
                        _startDate == null && _endDate == null
                            ? 'Select Date Range'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      ),
                      leading: const Icon(Icons.calendar_today),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _selectDateRange(context),
                    ),
                    const SizedBox(height: AppConstants.spacingLarge),
                    Text(
                      'Images',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    if (_existingImageUrls.isNotEmpty)
                      Wrap(
                        spacing: AppConstants.spacingSmall,
                        runSpacing: AppConstants.spacingSmall,
                        children: _existingImageUrls.map((url) {
                          return Stack(
                            children: [
                              Image.network(
                                url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => _removeExistingImage(url),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    Wrap(
                      spacing: AppConstants.spacingSmall,
                      runSpacing: AppConstants.spacingSmall,
                      children: _pickedImages.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final File image = entry.value;
                        return Stack(
                          children: [
                            widgetForPickedFile(image, width: 100, height: 100, fit: BoxFit.cover),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _removePickedImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Add Images'),
                    ),
                    const SizedBox(height: AppConstants.spacingLarge),
                    Text(
                      'Map Route',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
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
                        onTap: _addMarker,
                        markers: _markers,
                      ),
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
                              onPressed: _submitItinerary,
                              child: Text(
                                widget.itineraryId == null ? 'Create Itinerary' : 'Update Itinerary',
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
