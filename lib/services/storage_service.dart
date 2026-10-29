// services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // Upload profile picture with progress tracking
  Future<String> uploadProfilePicture(File file) async {
    final ext = path.extension(file.path);
    final ref = _storage.ref('users/$_uid/profile$ext');

    // Set metadata for proper content type
    final metadata = SettableMetadata(
      contentType: 'image/${ext.replaceAll('.', '')}',
      customMetadata: {
        'uploadedBy': _uid,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    // Upload with progress monitoring
    final uploadTask = ref.putFile(file, metadata);
    uploadTask.snapshotEvents.listen((event) {
      final progress = event.bytesTransferred / event.totalBytes;
      print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
    });

    // Wait for upload to complete
    await uploadTask;

    // Return download URL
    return await ref.getDownloadURL();
  }

  // Upload any file (documents, images, etc.)
  Future<String> uploadFile({
    required File file,
    required String folder,
    String? customName,
  }) async {
    final fileName = customName ?? path.basename(file.path);
    final ref = _storage.ref('users/$_uid/$folder/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Pick and upload image from gallery
  Future<String?> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024, // Resize to save storage costs
      maxHeight: 1024,
      imageQuality: 80, // Compress to save bandwidth
    );

    if (pickedFile == null) return null;
    final file = File(pickedFile.path);
    return await uploadProfilePicture(file);
  }

  // Delete a file by its download URL
  Future<void> deleteFile(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }

  // List all files in a folder
  Future<List<Reference>> listFiles(String folder) async {
    final result = await _storage.ref('users/$_uid/$folder').listAll();
    return result.items;
  }
}