import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/png_cutout.dart';
import '../services/imgbb_service.dart';

/// Avatar profil local (URL ImgBB) par email utilisateur.
class AvatarProvider extends ChangeNotifier {
  static const _prefix = 'odin_avatar_url_';

  String? _userKey;
  String? _avatarUrl;
  bool _uploading = false;
  String? _error;

  String? get avatarUrl => _avatarUrl;
  bool get uploading => _uploading;
  String? get error => _error;

  Future<void> bindUser(String? email) async {
    final key = email?.trim().toLowerCase();
    if (key == null || key.isEmpty) {
      _userKey = null;
      _avatarUrl = null;
      notifyListeners();
      return;
    }
    if (_userKey == key && _avatarUrl != null) return;
    _userKey = key;
    final prefs = await SharedPreferences.getInstance();
    _avatarUrl = prefs.getString('$_prefix$key');
    notifyListeners();
  }

  Future<void> pickAndUpload({required ImageSource source}) async {
    if (_userKey == null) {
      _error = 'Connectez-vous pour changer la photo';
      notifyListeners();
      return;
    }

    _error = null;
    notifyListeners();

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file == null) return;

    _uploading = true;
    notifyListeners();
    try {
      final bytes = await file.readAsBytes();
      final url = await ImgbbService.uploadBytes(
        bytes,
        name: 'odin_${_userKey}_${DateTime.now().millisecondsSinceEpoch}',
      );
      await _persist(url);
    } on ImgbbException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  /// FIFA cutout: PNG with transparent background only (no re-encode).
  Future<void> pickAndUploadFifaCutout({required ImageSource source}) async {
    if (_userKey == null) {
      _error = 'Connectez-vous pour changer la photo';
      notifyListeners();
      return;
    }

    _error = null;
    notifyListeners();

    final bytes = await _readFifaCutoutBytes(source);
    if (bytes == null) return;

    if (!isTransparentPng(bytes)) {
      _error = 'PNG transparent uniquement (fond transparent requis)';
      notifyListeners();
      throw PngCutoutException(_error!);
    }

    _uploading = true;
    notifyListeners();
    try {
      final url = await ImgbbService.uploadBytes(
        bytes,
        name: 'odin_fifa_${_userKey}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await _persist(url);
    } on ImgbbException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> _readFifaCutoutBytes(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      if (file.bytes != null && file.bytes!.isNotEmpty) return file.bytes;
      final path = file.path;
      if (path == null) return null;
      return File(path).readAsBytes();
    }

    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return null;
    return picked.readAsBytes();
  }

  Future<void> clear() async {
    if (_userKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$_userKey');
    _avatarUrl = null;
    notifyListeners();
  }

  /// Synchronise une URL serveur (ImgBB) vers le cache local.
  Future<void> syncFromRemote(String? url) async {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    if (_avatarUrl == trimmed) return;
    await _persist(trimmed);
  }

  Future<void> _persist(String url) async {
    if (_userKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$_userKey', url);
    _avatarUrl = url;
    notifyListeners();
  }
}
