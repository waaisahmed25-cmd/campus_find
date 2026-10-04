import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/lost_found_item.dart';
import '../../services/camera_service.dart';
import '../../services/item_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final ItemService _itemService = ItemService();
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();

  String selectedType = 'lost';
  String selectedCategory = 'Electronics';

  DateTime selectedDate = DateTime.now();

  double? latitude;
  double? longitude;

  XFile? capturedImage;

  bool isLoading = false;
  bool isGettingLocation = false;
  bool isOpeningCamera = false;

  final List<String> categories = [
    'Electronics',
    'Wallet / Purse',
    'Keys',
    'ID / Cards',
    'Books / Notes',
    'Clothing',
    'Bag',
    'Accessories',
    'Other',
  ];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      isGettingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location captured successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    setState(() {
      isOpeningCamera = true;
    });

    try {
      final image = await _cameraService.captureImage();

      if (!mounted) return;

      if (image != null) {
        setState(() {
          capturedImage = image;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo captured successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the camera. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningCamera = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    setState(() {
      isOpeningCamera = true;
    });

    try {
      final image = await _cameraService.pickFromGallery();

      if (!mounted) return;

      if (image != null) {
        setState(() {
          capturedImage = image;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo selected successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the gallery. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningCamera = false;
        });
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Item Photo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text('Choose how you would like to add a photo.'),

                const SizedBox(height: 18),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _captureImage();
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take Photo'),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from Gallery'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      capturedImage = null;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Photo removed.')));
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit a report.'),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final item = LostFoundItem(
        id: '',
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        type: selectedType,
        category: selectedCategory,
        status: 'active',
        createdBy: currentUser.uid,
        eventDate: selectedDate,
        createdAt: DateTime.now(),

        // Image is displayed locally.
        // Firebase Storage is not currently being used.
        imageUrl: '',

        locationName: '',
        latitude: latitude,
        longitude: longitude,
      );

      await _itemService.createItem(item: item);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selectedType == 'lost'
                ? 'Lost item report submitted successfully!'
                : 'Found item report submitted successfully!',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit report. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

    final bool isLost = selectedType == 'lost';

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Item')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        color: Colors.white,
                        size: 34,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create a Report',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Provide clear details to help the campus community identify the item.',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const _SectionTitle(
                  title: 'Report Type',
                  subtitle: 'Was the item lost or found?',
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          selected: isLost,
                          label: 'Lost',
                          icon: Icons.search_rounded,
                          selectedColor: AppTheme.lostColor,
                          onTap: () {
                            setState(() {
                              selectedType = 'lost';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _TypeButton(
                          selected: !isLost,
                          label: 'Found',
                          icon: Icons.inventory_2_outlined,
                          selectedColor: AppTheme.foundColor,
                          onTap: () {
                            setState(() {
                              selectedType = 'found';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const _SectionTitle(
                  title: 'Item Information',
                  subtitle: 'Tell us what the item looks like.',
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Item Title',
                    hintText: 'Example: Black AirPods Case',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an item title';
                    }

                    if (value.trim().length < 3) {
                      return 'Title must be at least 3 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Colour, brand, identifying features, where it was seen, etc.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }

                    if (value.trim().length < 10) {
                      return 'Please provide a little more detail';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date Lost / Found',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                      suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    child: Text(formattedDate),
                  ),
                ),

                const SizedBox(height: 28),

                const _SectionTitle(
                  title: 'Item Photo',
                  subtitle: 'Take a photo or choose an existing image.',
                ),

                const SizedBox(height: 14),

                if (capturedImage == null)
                  InkWell(
                    onTap: isOpeningCamera ? null : _showPhotoOptions,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: isOpeningCamera
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: AppTheme.primary,
                                    size: 29,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Add Item Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Take a photo or choose one from your gallery',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(capturedImage!.path),
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isOpeningCamera
                                  ? null
                                  : _showPhotoOptions,
                              icon: const Icon(Icons.image_outlined),
                              label: const Text('Change Photo'),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 28),

                const _SectionTitle(
                  title: 'Location',
                  subtitle: 'Capture where the item was lost or found.',
                ),

                const SizedBox(height: 14),

                InkWell(
                  onTap: isGettingLocation ? null : _getLocation,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: latitude != null && longitude != null
                          ? const Color(0xFFE8F5E9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: latitude != null && longitude != null
                            ? AppTheme.foundColor.withValues(alpha: 0.45)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: latitude != null && longitude != null
                                ? AppTheme.foundColor.withValues(alpha: 0.12)
                                : AppTheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: isGettingLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(13),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  latitude != null && longitude != null
                                      ? Icons.check_circle_outline
                                      : Icons.location_on_outlined,
                                  color: latitude != null && longitude != null
                                      ? AppTheme.foundColor
                                      : AppTheme.primary,
                                ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latitude != null && longitude != null
                                    ? 'Location Captured'
                                    : 'Use Current Location',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                latitude != null && longitude != null
                                    ? 'GPS coordinates are ready.'
                                    : 'Tap to capture GPS coordinates.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ],
                    ),
                  ),
                ),

                if (latitude != null && longitude != null) ...[
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          color: AppTheme.foundColor,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GPS Coordinates',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 5),

                              Text('Latitude: ${latitude!.toStringAsFixed(6)}'),

                              Text(
                                'Longitude: ${longitude!.toStringAsFixed(6)}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                FilledButton.icon(
                  onPressed: isLoading ? null : _submitReport,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      isLoading
                          ? 'Submitting Report...'
                          : selectedType == 'lost'
                          ? 'Submit Lost Report'
                          : 'Submit Found Report',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Your report will be visible to authenticated CampusFind users.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? selectedColor.withValues(alpha: 0.40)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? selectedColor : AppTheme.textSecondary,
            ),

            const SizedBox(width: 8),

            Text(
              label,
              style: TextStyle(
                color: selected ? selectedColor : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
