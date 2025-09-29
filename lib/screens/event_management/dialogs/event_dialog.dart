import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/services/storage_service.dart';
import 'package:event_manager_local/screens/event_map/event_location_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_manager_local/utils/image_utils.dart';

class EventDialog {
  static Future<void> showCreateEventDialog(
    BuildContext context,
    String organizerId,
    Function(Event) onCreate,
  ) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime startDateTime = DateTime.now().add(const Duration(hours: 1));
    DateTime endDateTime = DateTime.now().add(const Duration(days: 7, hours: 3));
    bool isFeatured = false;
    File? bannerImage;
    LatLng? selectedLocation;
    final storageService = StorageService();

    Future<void> pickImage() async {
      try {
        final image = await storageService.pickImage();
        if (image != null) {
          // Update the dialog state
          // We'll need to handle this through a callback or state management
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick image: $e')),
          );
        }
      }
    }

    Future<String?> uploadBannerImage() async {
      if (bannerImage == null) return null;

      try {
        return await storageService.uploadBannerImage(bannerImage!);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload banner: $e')),
          );
        }
        return null;
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                // Add map location button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventLocationMap(),
                      ),
                    );

                    if (result != null && result is LatLng) {
                      setState(() {
                        selectedLocation = result;
                        // Convert coordinates to a string representation
                        locationController.text =
                            'Lat: ${result.latitude.toStringAsFixed(6)}, Lng: ${result.longitude.toStringAsFixed(6)}';
                      });
                    }
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Select on Map'),
                ),
                if (selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Selected: Lat ${selectedLocation!.latitude.toStringAsFixed(6)}, Lng ${selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(startDateTime),
                            );
                            if (time != null) {
                              setState(() {
                                startDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date & Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy - HH:mm')
                                .format(startDateTime),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDateTime,
                            firstDate: startDateTime,
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endDateTime),
                            );
                            if (time != null) {
                              setState(() {
                                endDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date & Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy - HH:mm')
                                .format(endDateTime),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isFeatured,
                      onChanged: (value) {
                        setState(() {
                          isFeatured = value ?? false;
                        });
                      },
                    ),
                    const Text('Featured Event'),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Banner',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final image = await storageService.pickImage();
                        if (image != null) {
                          setState(() {
                            bannerImage = image;
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: bannerImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  bannerImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Tap to select banner image'),
                                  const Text(
                                    'Max size: 2MB',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (bannerImage != null)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            bannerImage = null;
                          });
                        },
                        child: const Text('Remove Image'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  String? bannerUrl;
                  if (bannerImage != null) {
                    bannerUrl = await uploadBannerImage();
                    if (bannerUrl == null) {
                      // Failed to upload, show error and don't create event
                      return;
                    }
                  }

                  final event = Event(
                    id: '',
                    title: titleController.text,
                    description: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : null,
                    location: locationController.text.isNotEmpty
                        ? locationController.text
                        : null,
                    bannerUrl: bannerUrl,
                    organiserId: organizerId,
                    startDateTime: startDateTime,
                    endDateTime: endDateTime,
                    isFeatured: isFeatured,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  Navigator.pop(context);
                  onCreate(event);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showEditEventDialog(
    BuildContext context,
    Event event,
    Function(Event) onUpdate,
  ) async {
    final titleController = TextEditingController(text: event.title);
    final descriptionController =
        TextEditingController(text: event.description ?? '');
    final locationController =
        TextEditingController(text: event.location ?? '');
    DateTime startDateTime = event.startDateTime;
    DateTime endDateTime = event.endDateTime;
    bool isFeatured = event.isFeatured;
    File? bannerImage;
    String? existingBannerUrl = event.bannerUrl;
    LatLng? selectedLocation;
    final storageService = StorageService();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                // Add map location button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventLocationMap(),
                      ),
                    );

                    if (result != null && result is LatLng) {
                      setState(() {
                        selectedLocation = result;
                        // Convert coordinates to a string representation
                        locationController.text =
                            'Lat: ${result.latitude.toStringAsFixed(6)}, Lng: ${result.longitude.toStringAsFixed(6)}';
                      });
                    }
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Select on Map'),
                ),
                if (selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Selected: Lat ${selectedLocation!.latitude.toStringAsFixed(6)}, Lng ${selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  TimeOfDay.fromDateTime(startDateTime),
                            );
                            if (time != null) {
                              setState(() {
                                startDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date & Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy - HH:mm')
                                .format(startDateTime),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDateTime,
                            firstDate: startDateTime,
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endDateTime),
                            );
                            if (time != null) {
                              setState(() {
                                endDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date & Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy - HH:mm')
                                .format(endDateTime),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isFeatured,
                      onChanged: (value) {
                        setState(() {
                          isFeatured = value ?? false;
                        });
                      },
                    ),
                    const Text('Featured Event'),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Banner',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final image = await storageService.pickImage();
                        if (image != null) {
                          setState(() {
                            bannerImage = image;
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: bannerImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  bannerImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : (existingBannerUrl != null &&
                                    existingBannerUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: ImageUtils.fixImageUrl(
                                        existingBannerUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Tap to select banner image'),
                                      const Text(
                                        'Max size: 2MB',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (bannerImage != null ||
                        (existingBannerUrl != null &&
                            existingBannerUrl!.isNotEmpty))
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            bannerImage = null;
                            existingBannerUrl = null;
                          });
                        },
                        child: const Text('Remove Image'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  String? bannerUrl = existingBannerUrl;
                  if (bannerImage != null) {
                    try {
                      bannerUrl = await storageService.uploadBannerImage(bannerImage!);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to upload banner: $e')),
                        );
                      }
                      return;
                    }
                  }

                  final updatedEvent = Event(
                    id: event.id,
                    title: titleController.text,
                    description: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : null,
                    location: locationController.text.isNotEmpty
                        ? locationController.text
                        : null,
                    bannerUrl: bannerUrl,
                    organiserId: event.organiserId,
                    startDateTime: startDateTime,
                    endDateTime: endDateTime,
                    isFeatured: isFeatured,
                    createdAt: event.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  Navigator.pop(context);
                  onUpdate(updatedEvent);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}