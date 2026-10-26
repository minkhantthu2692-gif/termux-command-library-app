import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/ai_models.dart';

/// Picks a single small text file for an explicit AI attachment. Contents are
/// only read after the user chooses a file, and are never uploaded anywhere
/// except the configured AI provider when the message is sent.
class FileAttachmentService {
  const FileAttachmentService();

  Future<AiAttachment?> pickTextFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedAttachmentExtensions,
      );
      if (file == null) return null;
      final extension = (file.extension ?? '').toLowerCase();
      if (!AppConstants.supportedAttachmentExtensions.contains(extension)) {
        throw const AppException(AppErrorCode.attachmentUnsupported);
      }
      final length = await file.length();
      if (length != null && length > AppConstants.aiMaxAttachmentBytes) {
        throw const AppException(AppErrorCode.attachmentTooLarge);
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > AppConstants.aiMaxAttachmentBytes) {
        throw const AppException(AppErrorCode.attachmentTooLarge);
      }
      String content;
      try {
        content = utf8.decode(bytes);
      } on FormatException {
        throw const AppException(AppErrorCode.attachmentUnsupported);
      }
      if (content.trim().isEmpty) {
        throw const AppException(AppErrorCode.attachmentReadFailed);
      }
      return AiAttachment(
        name: file.name,
        content: content,
        sizeBytes: bytes.length,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(AppErrorCode.attachmentReadFailed, cause: error);
    }
  }
}
