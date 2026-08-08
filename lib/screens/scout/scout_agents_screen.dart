import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../models/scout_models.dart';
import '../../providers/scout_provider.dart';

class ScoutAgentsScreen extends StatefulWidget {
  const ScoutAgentsScreen({super.key});

  @override
  State<ScoutAgentsScreen> createState() => _ScoutAgentsScreenState();
}

class _ScoutAgentsScreenState extends State<ScoutAgentsScreen> {
  List<ScoutAgent> _agents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _agents = await context.read<ScoutDataProvider>().api.getAgents(refresh: refresh);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'actif' => AppColors.success,
      'inactif' => AppColors.muted,
      _ => AppColors.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: () => _load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(Text('Agents', style: tt.headlineMedium), index: 0),
            OdinAnimations.fadeUp(
              Text('Réseau mandataires & intermédiaires', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
              index: 1,
            ),
            const SizedBox(height: AppSpacing.m),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              )
            else if (_error != null)
              GlassCard(
                child: SaasEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Erreur de chargement',
                  subtitle: _error!,
                  onAction: _load,
                  compact: true,
                ),
              )
            else if (_agents.isEmpty)
              SaasEmptyState(
                title: 'Aucun agent',
                subtitle: 'Le réseau sera synchronisé prochainement',
                icon: Icons.handshake_outlined,
                onAction: _load,
              )
            else
              ...List.generate(_agents.length, (i) {
                final a = _agents[i];
                return OdinAnimations.fadeUp(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      onTap: () => HapticFeedback.selectionClick(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(a.flag.isNotEmpty ? a.flag : '🤝', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    Text(
                                      a.agency.isNotEmpty ? a.agency : a.country,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                      Text(
                                        a.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Text('${a.deals} deals', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(a.status).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _statusColor(a.status).withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  a.status.toUpperCase(),
                                  style: TextStyle(color: _statusColor(a.status), fontWeight: FontWeight.w700, fontSize: 10),
                                ),
                              ),
                              if (a.email.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    a.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (a.aiNotes?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              a.aiNotes!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.accent.withValues(alpha: 0.8), fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  index: i + 2,
                );
              }),
          ],
        ),
      ),
    );
  }
}
