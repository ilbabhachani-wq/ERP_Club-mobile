import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';
import '../../services/joueur_api.dart';

class JoueurDocumentsScreen extends StatelessWidget {
  const JoueurDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<JoueurDataProvider>();

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Mes Documents'),
          if (data.documents.isEmpty)
            const GlassCard(child: Text('Aucun document', style: TextStyle(color: OdinColors.textMuted)))
          else
            ...data.documents.asMap().entries.map((e) {
              final d = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OdinAnimations.fadeUp(
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, color: OdinColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${d.docType} · ${d.docDate} · ${d.size}', style: const TextStyle(color: OdinColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: OdinColors.danger, size: 20),
                          onPressed: () => _delete(context, d.id),
                        ),
                      ],
                    ),
                  ),
                  index: e.key,
                ),
              );
            }),
        ],
      ),
    );
  }

  static Future<void> _delete(BuildContext context, String docId) async {
    try {
      await ClubApi(context.read<AuthProvider>().api).deleteDocument(docId);
      await context.read<JoueurDataProvider>().refetchDocuments();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document supprimé')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
