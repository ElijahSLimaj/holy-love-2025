import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

/// Result of image upload operation
class ImageUploadResult {
  final String originalUrl;
  final String thumbnailUrl;
  final String fileName;
  final int originalSize;
  final int compressedSize;

  const ImageUploadResult({
    required this.originalUrl,
    required this.thumbnailUrl,
    required this.fileName,
    required this.originalSize,
    required this.compressedSize,
  });

  double get compressionRatio => compressedSize / originalSize;
}

/// Service for handling image uploads with compression and thumbnail generation
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const int _maxImageSize =
      1920; // Max width/height for full-size images
  static const int _thumbnailSize = 300; // Thumbnail size
  static const int _compressionQuality = 85; // JPEG quality (0-100)
  static const int _thumbnailQuality = 80; // Thumbnail JPEG quality

  /// Upload a single profile image with compression and thumbnail generation
  static Future<ImageUploadResult?> uploadProfileImage(
    File imageFile,
    String userId, {
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    try {
      final originalSize = await imageFile.length();
      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 'profile_$timestamp.jpg';
      final thumbnailFileName = 'thumb_$fileName';
      // Compress image for full-size version
      final compressedImage = await _compressImage(
        imageFile,
        _maxImageSize,
        _compressionQuality,
      );
      if (compressedImage == null) {
        return null;
      }

      // Create thumbnail
      final thumbnailImage = await _compressImage(
        imageFile,
        _thumbnailSize,
        _thumbnailQuality,
      );
      if (thumbnailImage == null) {
        return null;
      }
      // Upload both images in parallel
      final results = await Future.wait([
        _uploadToFirebase(
            compressedImage, 'profile_images/$userId/$fileName', onProgress),
        _uploadToFirebase(
            thumbnailImage, 'profile_images/$userId/$thumbnailFileName'),
      ]);

      final originalUrl = results[0];
      final thumbnailUrl = results[1];

      if (originalUrl == null || thumbnailUrl == null) {
        return null;
      }

      return ImageUploadResult(
        originalUrl: originalUrl,
        thumbnailUrl: thumbnailUrl,
        fileName: fileName,
        originalSize: originalSize,
        compressedSize: compressedImage.length,
      );
    } catch (e) {
      return null;
    }
  }

  /// Upload multiple profile images
  static Future<List<ImageUploadResult>> uploadMultipleImages(
    List<File> imageFiles,
    String userId, {
    Function(int current, int total)? onProgressUpdate,
  }) async {
    final results = <ImageUploadResult>[];

    for (int i = 0; i < imageFiles.length; i++) {
      onProgressUpdate?.call(i, imageFiles.length);

      final result = await uploadProfileImage(
        imageFiles[i],
        userId,
        customFileName:
            'profile_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (result != null) {
        results.add(result);
      } else {}
    }

    onProgressUpdate?.call(imageFiles.length, imageFiles.length);
    return results;
  }

  /// Delete an image from Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete all images for a user
  static Future<void> deleteAllUserImages(String userId) async {
    try {
      final ref = _storage.ref('profile_images/$userId');
      final listResult = await ref.listAll();

      final deleteFutures = listResult.items.map((item) => item.delete());
      await Future.wait(deleteFutures);
    } catch (e) {}
  }

  /// Pick images using ImagePicker
  static Future<List<File>> pickImages({
    int maxImages = 6,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = ImagePicker();

      if (source == ImageSource.camera) {
        final pickedFile = await picker.pickImage(source: ImageSource.camera);
        if (pickedFile != null) {
          return [File(pickedFile.path)];
        }
      } else {
        final pickedFiles = await picker.pickMultiImage(limit: maxImages);
        final files = pickedFiles.map((file) => File(file.path)).toList();
        return files;
      }
    } catch (e) {}

    return [];
  }

  /// Validate image file
  static bool isValidImage(File imageFile) {
    final extension = path.extension(imageFile.path).toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.heic'];

    final isValid = validExtensions.contains(extension);
    return isValid;
  }

  /// Get image file size in MB
  static Future<double> getImageSizeInMB(File imageFile) async {
    final size = await imageFile.length();
    return size / (1024 * 1024);
  }

  // Private helper methods

  /// Compress image to specified dimensions and quality
  static Future<Uint8List?> _compressImage(
    File imageFile,
    int maxSize,
    int quality,
  ) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: maxSize,
        minHeight: maxSize,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Upload compressed image data to Firebase Storage
  static Future<String?> _uploadToFirebase(
    Uint8List imageData,
    String storagePath, [
    Function(double)? onProgress,
  ]) async {
    try {
      final ref = _storage.ref(storagePath);
      final uploadTask = ref.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      // Monitor upload progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }
}

/// Extension for File to add image utilities
extension ImageFileExtension on File {
  /// Check if file is a valid image format
  bool get isValidImage => ImageUploadService.isValidImage(this);

  /// Get file size in MB
  Future<double> get sizeInMB => ImageUploadService.getImageSizeInMB(this);
}
