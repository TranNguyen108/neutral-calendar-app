import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

import '../models/attachment.dart';

/// Service for managing file attachments
class AttachmentService extends GetxService {
  final ImagePicker _imagePicker = ImagePicker();

  static const String _attachmentsFolderName = 'attachments';
  static const String _thumbnailsFolderName = 'thumbnails';
  static const int _thumbnailSize = 200; // pixels

  /// Get the attachments directory
  Future<Directory> _getAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/$_attachmentsFolderName');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  /// Get the thumbnails directory
  Future<Directory> _getThumbnailsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final thumbsDir = Directory('${appDir.path}/$_thumbnailsFolderName');
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }
    return thumbsDir;
  }

  /// Pick image from gallery
  Future<Attachment?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _processImageFile(image);
    } catch (e) {
      Get.log('Error picking image: $e', isError: true);
      return null;
    }
  }

  /// Pick image from camera
  Future<Attachment?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _processImageFile(image);
    } catch (e) {
      Get.log('Error capturing image: $e', isError: true);
      return null;
    }
  }

  /// Pick file from device
  Future<Attachment?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Documents
          'pdf', 'doc', 'docx', 'txt', 'rtf',
          // Images (as fallback)
          'jpg', 'jpeg', 'png', 'gif',
          // Audio
          'mp3', 'wav', 'aac', 'm4a',
        ],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      return await _processFile(file);
    } catch (e) {
      Get.log('Error picking file: $e', isError: true);
      return null;
    }
  }

  /// Process an image file
  Future<Attachment> _processImageFile(XFile xFile) async {
    final file = File(xFile.path);
    final fileName = path.basename(file.path);
    final fileSize = await file.length();

    // Copy file to attachments directory
    final attachmentsDir = await _getAttachmentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${timestamp}_$fileName';
    final newPath = '${attachmentsDir.path}/$newFileName';
    final newFile = await file.copy(newPath);

    // Generate thumbnail
    final thumbnailPath = await _generateThumbnail(newFile);

    final attachment = Attachment(
      id: timestamp.toString(),
      fileName: fileName,
      filePath: newPath,
      type: Attachment.getTypeFromFileName(fileName),
      fileSizeBytes: fileSize,
      thumbnailPath: thumbnailPath,
    );

    Get.log('Image attachment created: ${attachment.fileName}');
    return attachment;
  }

  /// Process a generic file
  Future<Attachment> _processFile(File file) async {
    final fileName = path.basename(file.path);
    final fileSize = await file.length();

    // Copy file to attachments directory
    final attachmentsDir = await _getAttachmentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${timestamp}_$fileName';
    final newPath = '${attachmentsDir.path}/$newFileName';
    final newFile = await file.copy(newPath);

    // Generate thumbnail if it's an image
    String? thumbnailPath;
    final type = Attachment.getTypeFromFileName(fileName);
    if (type == AttachmentType.image) {
      thumbnailPath = await _generateThumbnail(newFile);
    }

    final attachment = Attachment(
      id: timestamp.toString(),
      fileName: fileName,
      filePath: newPath,
      type: type,
      fileSizeBytes: fileSize,
      thumbnailPath: thumbnailPath,
    );

    Get.log('File attachment created: ${attachment.fileName}');
    return attachment;
  }

  /// Generate thumbnail for an image
  Future<String?> _generateThumbnail(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      // Create thumbnail
      final thumbnail = img.copyResize(
        image,
        width: image.width > image.height ? _thumbnailSize : null,
        height: image.height > image.width ? _thumbnailSize : null,
      );

      // Save thumbnail
      final thumbsDir = await _getThumbnailsDirectory();
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final thumbPath = '${thumbsDir.path}/${fileName}_thumb.jpg';
      final thumbFile = File(thumbPath);
      await thumbFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 85));

      Get.log('Thumbnail generated: $thumbPath');
      return thumbPath;
    } catch (e) {
      Get.log('Error generating thumbnail: $e', isError: true);
      return null;
    }
  }

  /// Delete an attachment and its thumbnail
  Future<bool> deleteAttachment(Attachment attachment) async {
    try {
      // Delete main file
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete thumbnail if exists
      if (attachment.thumbnailPath != null) {
        final thumbFile = File(attachment.thumbnailPath!);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }

      Get.log('Attachment deleted: ${attachment.fileName}');
      return true;
    } catch (e) {
      Get.log('Error deleting attachment: $e', isError: true);
      return false;
    }
  }

  /// Get total size of all attachments
  Future<int> getTotalAttachmentsSize() async {
    try {
      final attachmentsDir = await _getAttachmentsDirectory();
      if (!await attachmentsDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in attachmentsDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      Get.log('Error calculating attachments size: $e', isError: true);
      return 0;
    }
  }

  /// Clean up orphaned attachments (not referenced by any task)
  Future<void> cleanupOrphanedAttachments(List<String> referencedPaths) async {
    try {
      final attachmentsDir = await _getAttachmentsDirectory();
      if (!await attachmentsDir.exists()) return;

      int deletedCount = 0;
      await for (final entity in attachmentsDir.list()) {
        if (entity is File) {
          if (!referencedPaths.contains(entity.path)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      // Clean up orphaned thumbnails
      final thumbsDir = await _getThumbnailsDirectory();
      if (await thumbsDir.exists()) {
        await for (final entity in thumbsDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      Get.log('Cleaned up $deletedCount orphaned attachments');
    } catch (e) {
      Get.log('Error cleaning up attachments: $e', isError: true);
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      return await File(filePath).length();
    } catch (e) {
      return 0;
    }
  }
}
