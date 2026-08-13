import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_form_sheet.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../models/medecin_models.dart';
import '../../providers/medecin_provider.dart';

class MedecinBlessuresScreen extends StatefulWidget {
  const MedecinBlessuresScreen({super.key});

  @override
  State<MedecinBlessuresScreen> createState() =>
    _MedecinBlessuresScreenState();
}

class _MedecinBlessuresScreenState
  extends State<MedecinBlessuresScreen> {

  String _filter = 'Tous';
  MedecinInjury? _selected;
  Set<String> _resolvedIds = {};

  static const _filters = [
    'Tous', 'Active', 'En rééducation', 'Terminée'
  ];

  @override
  void initState() {
    super.initState();
    _loadResolvedIds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedecinProvider>().loadAll();
    });
  }

  Future<void> _loadResolvedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('odin_resolved_injuries');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        if (!mounted) return;
        setState(() {
          _resolvedIds = list.map((e) => e.toString()).toSet();
        });
      }
    } catch (_) {}
  }

  String _computeStatus(MedecinInjury inj) {
    if (_resolvedIds.contains(inj.id)) {
      return 'Terminée';
    }
    final days = inj.daysRemaining;
    if (days == null) return 'Active';
    if (days < 0) return 'En rééducation';
    return 'Active';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active': return const Color(0xFFEF4444);
      case 'En rééducation':
        return const Color(0xFFF59E0B);
      case 'Terminée': return const Color(0xFF22C55E);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MedecinProvider>();

    final filtered = prov.injuries.where((inj) {
      if (_filter == 'Tous') return true;
      return _computeStatus(inj) == _filter;
    }).toList();

    // KPIs — computed from records (web kpis.injured = unique players)
    final totalCas = prov.injuries.length;
    final casActifs = prov.injuries
      .where((i) => _computeStatus(i) == 'Active')
      .length;
    final enReeducation = prov.injuries
      .where((i) =>
        _computeStatus(i) == 'En rééducation')
      .length;
    final highRisk = prov.injuries
      .where((i) => i.riskIA >= 7)
      .length;

    return OdinBackdrop(
      child: Stack(
        children: [
          Positioned.fill(
            child: prov.loading
        ? const _LoadingWidget()
        : prov.error != null
        ? _ErrorWidget(
            error: prov.error!,
            onRetry: prov.loadAll,
          )
        : _selected != null
        ? _InjuryDetail(
            injury: _selected!,
            status: _computeStatus(_selected!),
            onBack: () =>
              setState(() => _selected = null),
            onUpdate: (body) async {
              await prov.addInjury(body);
              setState(() => _selected = null);
            },
          )
        : CustomScrollView(
            slivers: [
              // KPIs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScoutSectionLabel('Blessures'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _KpiCard(
                            label: 'Total',
                            value: '$totalCas',
                            color: AppColors.info,
                            icon: Icons.healing_rounded,
                          ),
                          const SizedBox(width: 10),
                          _KpiCard(
                            label: 'Actives',
                            value: '$casActifs',
                            color: AppColors.danger,
                            icon: Icons.warning_amber_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _KpiCard(
                            label: 'Rééducation',
                            value: '$enReeducation',
                            color: AppColors.warning,
                            icon: Icons.fitness_center_rounded,
                          ),
                          const SizedBox(width: 10),
                          _KpiCard(
                            label: 'Risque élevé',
                            value: '$highRisk',
                            color: const Color(0xFF8B5CF6),
                            icon: Icons.monitor_heart_rounded,
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(),
                ),
              ),

              // Filter pills
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.page, 12, AppSpacing.page, 0),
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) =>
                      const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(
                          () => _filter = f
                        ),
                        child: Container(
                          padding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          decoration: BoxDecoration(
                            color: active
                              ? OdinColors.accent
                              : OdinColors.inputFill,
                            borderRadius:
                              BorderRadius.circular(99),
                            border: Border.all(
                              color: active
                                ? OdinColors.accent
                                : OdinColors.panelBorder,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: active
                                ? Colors.white
                                : OdinColors.textSecondary,
                              fontSize: 12,
                              fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 12)
              ),

              // Injuries list
              filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize:
                          MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: const Color(
                              0xFF22C55E
                            ),
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'Tous'
                              ? 'Aucune blessure'
                              : 'Aucune blessure $_filter'
                                .toLowerCase(),
                            style: TextStyle(
                              color: OdinColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate:
                      SliverChildBuilderDelegate(
                      (context, i) {
                        final inj = filtered[i];
                        final status =
                          _computeStatus(inj);
                        final sc =
                          _statusColor(status);
                        return Padding(
                          padding:
                            const EdgeInsets.fromLTRB(
                              AppSpacing.page, 0, AppSpacing.page, 8
                            ),
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _selected = inj
                            ),
                            child: _InjuryRow(
                              injury: inj,
                              status: status,
                              statusColor: sc,
                            ),
                          ),
                        ).animate().fadeIn(
                          delay: Duration(
                            milliseconds: i * 60
                          )
                        ).slideX(begin: -0.05);
                      },
                      childCount: filtered.length,
                    ),
                  ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.bottomNav)
              ),
            ],
          ),
          ),
          if (_selected == null)
            Positioned(
              right: 16,
              bottom: AppSpacing.fabBottom(context),
              child: FloatingActionButton(
                backgroundColor: OdinColors.accent,
                onPressed: () => _showAddInjurySheet(context, prov),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddInjurySheet(
    BuildContext context,
    MedecinProvider prov,
  ) {
    String? selectedPlayerName;
    String selectedInjuryType = 'Hamstring';
    String selectedBodyPart = 'Genou gauche';
    DateTime? selectedDate;
    double riskScore = 5;

    const injuryTypes = [
      'Hamstring',
      'Fracture',
      'Contusion',
      'Entorse',
      'Déchirure musculaire',
      'Inflammation',
      'Tendinite',
      'Luxation',
      'Commotion',
      'Autre',
    ];

    const bodyParts = [
      'Tête',
      'Épaule gauche',
      'Épaule droite',
      'Bras gauche',
      'Bras droit',
      'Genou gauche',
      'Genou droit',
      'Cheville gauche',
      'Cheville droite',
      'Cuisse gauche',
      'Cuisse droite',
      'Ischio-jambiers',
      'Dos',
      'Aine',
      'Pied gauche',
      'Pied droit',
    ];

    showOdinFormSheet<void>(
      context: context,
      title: 'Enregistrer une blessure',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DropdownLabel(label: 'JOUEUR'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: OdinColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OdinColors.panelBorder),
                  ),
                  child: DropdownButton<String>(
                    value: selectedPlayerName,
                    hint: Text(
                      'Sélectionner un joueur...',
                      style: TextStyle(
                        color: OdinColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    dropdownColor: OdinColors.canvas2,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: OdinColors.textMuted,
                    ),
                    style: TextStyle(
                      color: OdinColors.textPrimary,
                      fontSize: 13,
                    ),
                    items: prov.players
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.fullName,
                            child: Text(p.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setSheet(() => selectedPlayerName = v),
                  ),
                ),
                const SizedBox(height: 14),
                const _DropdownLabel(label: 'TYPE DE BLESSURE'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: OdinColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OdinColors.panelBorder),
                  ),
                  child: DropdownButton<String>(
                    value: selectedInjuryType,
                    dropdownColor: OdinColors.canvas2,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: OdinColors.textMuted,
                    ),
                    style: TextStyle(
                      color: OdinColors.textPrimary,
                      fontSize: 13,
                    ),
                    items: injuryTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setSheet(
                      () => selectedInjuryType = v ?? selectedInjuryType,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _DropdownLabel(label: 'ZONE'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: OdinColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OdinColors.panelBorder),
                  ),
                  child: DropdownButton<String>(
                    value: selectedBodyPart,
                    dropdownColor: OdinColors.canvas2,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: OdinColors.textMuted,
                    ),
                    style: TextStyle(
                      color: OdinColors.textPrimary,
                      fontSize: 13,
                    ),
                    items: bodyParts
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(b),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setSheet(
                      () => selectedBodyPart = v ?? selectedBodyPart,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _DropdownLabel(label: 'RETOUR PRÉVU'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: OdinColors.accent,
                            surface: OdinColors.canvas2,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setSheet(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OdinColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OdinColors.panelBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: OdinColors.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          selectedDate == null
                              ? 'Sélectionner une date'
                              : '${selectedDate!.day.toString().padLeft(2, '0')}/'
                                  '${selectedDate!.month.toString().padLeft(2, '0')}/'
                                  '${selectedDate!.year}',
                          style: TextStyle(
                            color: selectedDate == null
                                ? OdinColors.textMuted
                                : OdinColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SCORE RISQUE IA',
                      style: TextStyle(
                        color: OdinColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: OdinColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${riskScore.round()}/10',
                        style: TextStyle(
                          color: OdinColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(ctx).copyWith(
                          activeTrackColor: riskScore >= 7
                              ? const Color(0xFFEF4444)
                              : riskScore >= 4
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF22C55E),
                          inactiveTrackColor: OdinColors.panelBorder,
                          thumbColor: OdinColors.accent,
                          overlayColor:
                              OdinColors.accent.withValues(alpha: 0.20),
                        ),
                        child: Slider(
                          value: riskScore,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          onChanged: (v) => setSheet(() => riskScore = v),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Faible',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Moyen',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Critique',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedPlayerName == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Sélectionnez un joueur'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      await prov.addInjury({
                        'playerName': selectedPlayerName,
                        'injuryType': selectedInjuryType,
                        'bodyPart': selectedBodyPart,
                        'returnDate': selectedDate == null
                            ? null
                            : '${selectedDate!.day.toString().padLeft(2, '0')}/'
                                '${selectedDate!.month.toString().padLeft(2, '0')}/'
                                '${selectedDate!.year}',
                        'riskScore': riskScore.round(),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OdinColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _DropdownLabel extends StatelessWidget {
  const _DropdownLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          color: OdinColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      );
}

// ─── Injury Row ───────────────────────────────────

class _InjuryRow extends StatelessWidget {
  const _InjuryRow({
    required this.injury,
    required this.status,
    required this.statusColor,
  });

  final MedecinInjury injury;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final days = injury.daysRemaining;
    final daysLabel = days == null
        ? status
        : days < 0
            ? '${days.abs()}j dépassé'
            : 'J-$days';
    final initials = injury.name.isNotEmpty
        ? injury.name
            .split(' ')
            .map((n) => n.isNotEmpty ? n[0] : '')
            .join()
            .toUpperCase()
            .substring(
              0,
              injury.name.split(' ').length >= 2 ? 2 : 1,
            )
        : '?';

    return GlassCard(
      accentColor: statusColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      injury.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: OdinColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    ),
                    Text(
                      '${injury.injury} · ${injury.bodyPart}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: OdinColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  daysLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: OdinColors.textMuted,
                size: 20,
              ),
            ],
          ),
    );
  }
}

// ─── Injury Detail ────────────────────────────────

class _InjuryDetail extends StatelessWidget {
  const _InjuryDetail({
    required this.injury,
    required this.status,
    required this.onBack,
    required this.onUpdate,
  });

  final MedecinInjury injury;
  final String status;
  final VoidCallback onBack;
  final Future<void> Function(
    Map<String, dynamic>
  ) onUpdate;

  @override
  Widget build(BuildContext context) {
    final days = injury.daysRemaining;
    final sc = status == 'Active'
      ? const Color(0xFFEF4444)
      : status == 'En rééducation'
      ? const Color(0xFFF59E0B)
      : const Color(0xFF22C55E);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  sc.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                BorderRadius.circular(20),
              border: Border.all(
                color: sc.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: OdinColors.panelBorder,
                          borderRadius:
                            BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: OdinColors.textPrimary,
                          size: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        injury.name,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                      decoration: BoxDecoration(
                        color: sc.withValues(
                          alpha: 0.15
                        ),
                        borderRadius:
                          BorderRadius.circular(99),
                        border: Border.all(
                          color: sc.withValues(
                            alpha: 0.30
                          ),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: sc,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  injury.injury,
                  style: TextStyle(
                    color: OdinColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  injury.bodyPart,
                  style: TextStyle(
                    color: OdinColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(
            begin: -0.1, end: 0
          ),
        ),

        // Stats grid
        SliverToBoxAdapter(
          child: Padding(
            padding:
              const EdgeInsets.symmetric(
                horizontal: 16
              ),
            child: Row(
              children: [
                _DetailStat(
                  label: 'Retour estimé',
                  value: injury.returnDate,
                  color: const Color(0xFF3B82F6),
                  icon: Icons.calendar_today,
                ),
                const SizedBox(width: 10),
                _DetailStat(
                  label: 'Risque IA',
                  value: '${injury.riskPercent}%',
                  color: injury.riskPercent >= 70
                    ? const Color(0xFFEF4444)
                    : injury.riskPercent >= 40
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF22C55E),
                  icon: Icons.warning_amber,
                ),
                const SizedBox(width: 10),
                _DetailStat(
                  label: 'Jours restants',
                  value: days == null
                    ? '—'
                    : days < 0
                    ? '${days.abs()}j\ndépassé'
                    : '$days j',
                  color: days != null && days < 0
                    ? const Color(0xFFEF4444)
                    : days != null && days <= 7
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF3B82F6),
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 16)
        ),

        // Countdown visual
        SliverToBoxAdapter(
          child: Padding(
            padding:
              const EdgeInsets.symmetric(
                horizontal: 16
              ),
            child: _CountdownCard(
              days: days,
              returnDate: injury.returnDate,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 32)
        ),
      ],
    );
  }
}

// ─── Countdown Card ───────────────────────────────

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.days,
    required this.returnDate,
  });
  final int? days;
  final String returnDate;

  @override
  Widget build(BuildContext context) {
    final Color c = days == null
      ? const Color(0xFF6B7280)
      : days! < 0
      ? const Color(0xFFEF4444)
      : days! <= 7
      ? const Color(0xFF22C55E)
      : const Color(0xFF3B82F6);

    final String title = days == null
      ? 'Date de retour non définie'
      : days! < 0
      ? '⚠ Retour en retard'
      : days! == 0
      ? '✅ Retour aujourd\'hui'
      : days! <= 7
      ? '🔜 Retour imminent'
      : '📅 Retour estimé';

    final String sub = days == null
      ? 'Aucune date renseignée'
      : days! < 0
      ? 'Évaluation médicale requise'
      : days! <= 3
      ? 'Préparer le test de reprise'
      : 'Continuer le protocole';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: c.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: c.withValues(alpha: 0.40),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  days == null
                    ? '—'
                    : '${days!.abs()}',
                  style: TextStyle(
                    color: c,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  'jours',
                  style: TextStyle(
                    color: c.withValues(alpha: 0.70),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: OdinColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  returnDate,
                  style: TextStyle(
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: TextStyle(
                    color: OdinColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small Widgets ────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
        child: SizedBox(
          height: 112,
          child: GlassCard(
            raised: true,
            accentColor: color,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: OdinColors.textMuted,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
}

// ─── Loading / Error ─────────────────────────────

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();
  @override
  Widget build(BuildContext context) =>
    Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: OdinColors.accent, strokeWidth: 2
          ),
          SizedBox(height: 12),
          Text(
            'Chargement des blessures...',
            style: TextStyle(
              color: OdinColors.textSecondary, fontSize: 13
            ),
          ),
        ],
      ),
    );
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
    Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFEF4444), size: 40
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(
              color: OdinColors.textSecondary, fontSize: 13
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Réessayer',
              style: TextStyle(
                color: OdinColors.accent
              ),
            ),
          ),
        ],
      ),
    );
}
