import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/avatar_provider.dart';
import '../../services/imgbb_service.dart';
import '../theme/odin_colors.dart';
import '../utils/png_cutout.dart';

/// Bottom sheet galerie / caméra / supprimer + upload ImgBB.
///
/// [fifaCutout] — PNG transparent only (carte FIFA).
Future<void> showAvatarChangeSheet(
  BuildContext context, {
  Future<void> Function(String url)? onUploaded,
  Future<void> Function()? onCleared,
  bool fifaCutout = false,
}) async {
  HapticFeedback.selectionClick();
  final avatar = context.read<AvatarProvider>();
  final source = await showModalBottomSheet<ImageSource?>(
    context: context,
    backgroundColor: OdinColors.panelSolid,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              fifaCutout ? 'Photo carte FIFA' : 'Photo de profil',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              fifaCutout
                  ? 'PNG transparent uniquement (sans fond)'
                  : 'Upload via ImgBB',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: OdinColors.textMuted),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: OdinColors.accent),
              title: const Text('Galerie', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: fifaCutout
                  ? const Text('Fichier .png avec fond transparent', style: TextStyle(fontSize: 12))
                  : null,
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: OdinColors.accent),
              title: const Text('Caméra', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: fifaCutout
                  ? const Text('Doit produire un PNG transparent', style: TextStyle(fontSize: 12))
                  : null,
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (avatar.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: OdinColors.danger),
                title: const Text('Supprimer la photo', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  await avatar.clear();
                  if (onCleared != null) await onCleared();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    ),
  );

  if (source == null || !context.mounted) return;

  Future<void> upload() async {
    if (fifaCutout) {
      await avatar.pickAndUploadFifaCutout(source: source);
    } else {
      await avatar.pickAndUpload(source: source);
    }
    final url = avatar.avatarUrl;
    if (url != null && onUploaded != null) await onUploaded(url);
  }

  try {
    await upload();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo mise à jour ✓'), backgroundColor: Color(0xFF22C55E)),
      );
    }
  } on PngCutoutException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: OdinColors.danger),
      );
    }
  } on ImgbbException catch (e) {
    if (!context.mounted) return;
    if (e.needsApiKey) {
      final saved = await _askImgbbKey(context);
      if (saved && context.mounted) {
        try {
          await upload();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo mise à jour ✓'), backgroundColor: Color(0xFF22C55E)),
            );
          }
        } catch (err) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$err'), backgroundColor: OdinColors.danger),
            );
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: OdinColors.danger),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: OdinColors.danger),
      );
    }
  }
}

Future<bool> _askImgbbKey(BuildContext context) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: OdinColors.panelSolid,
      title: const Text('Clé API ImgBB'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Créez une clé gratuite sur api.imgbb.com puis collez-la ici.',
            style: TextStyle(fontSize: 13, color: OdinColors.textMuted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Votre clé ImgBB',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: OdinColors.accent),
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
  if (ok == true && controller.text.trim().isNotEmpty) {
    await ImgbbService.saveApiKey(controller.text.trim());
    return true;
  }
  return false;
}
