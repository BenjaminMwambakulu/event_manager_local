import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Pick an image from the device gallery
  Future<File?> pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  /// Upload a banner image and return its URL
  Future<String?> uploadBannerImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final maxSize = 2 * 1024 * 1024; // 2MB

      if (bytes.length > maxSize) {
        throw Exception('Image size should be less than 2MB');
      }

      final String fileName =
          'banners/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('banners').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final String url = _supabase.storage.from('banners').getPublicUrl(fileName);
      return url;
    } catch (e) {
      throw Exception('Failed to upload banner: ${e.toString()}');
    }
  }
}