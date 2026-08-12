import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/medecin_provider.dart';
import '../../models/medecin_models.dart';
import '../../core/theme/odin_colors.dart';

class MedecinTraitementsScreen extends StatefulWidget {
  const MedecinTraitementsScreen({super.key});

  @override
  State<MedecinTraitementsScreen> createState() =>
    _MedecinTraitementsScreenState();
}

class _MedecinTraitementsScreenState
  extends State<MedecinTraitementsScreen> {

  // Treatment data stored per injury ID
  // Map<injuryId, TreatmentData>
  final Map<String, _TreatmentData> _treatments = {};
  String? _selectedInjuryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedecinProvider>().loadAll();
    });
  }

  _TreatmentData _getTreatment(
    String injuryId, int phase
  ) {
    if (!_treatments.containsKey(injuryId)) {
      _treatments[injuryId] = _TreatmentData(
        protocol: phase == 1
          ? ['Cryothérapie','Anti-inflammatoires',
             'Physiothérapie','Repos']
          : phase == 2
          ? ['Renforcement musculaire',
             'Proprioception','Reprise cardio']
          : ['Entraînement spécifique',
             'Tests physiques',
             'Validation médicale'],
        objectives: phase == 1
          ? ['Douleur < 2/10',
             'Réduire l\'œdème',
             'Amplitude ≥ 85%']
          : phase == 2
          ? ['Force ≥ 90% côté sain',
             'Tests fonctionnels réussis',
             'Course sans douleur']
          : ['Entraînement complet',
             'Aucune douleur',
             'Performance atteinte'],
        objectivesDone: [],
        allowed: ['Vélo stationnaire',
          'Musculation haut du corps'],
        restricted: ['Sprint','Match','Contact'],
        notes: '',
        history: ['Traitement démarré'],
      );
    }
    return _treatments[injuryId]!;
  }

  int _getPhase(MedecinInjury inj) {
    final days = inj.daysRemaining;
    if (days == null) return 1;
    if (days < 0) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MedecinProvider>();

    return Scaffold(
      backgroundColor: OdinColors.canvas,
      appBar: AppBar(
        backgroundColor: OdinColors.canvas2,
        elevation: 0,
        title: Text(
          'Traitements',
          style: TextStyle(
            color: OdinColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: prov.loading
        ? const _LoadingWidget()
        : prov.error != null
        ? _ErrorWidget(
            error: prov.error!,
            onRetry: prov.loadAll,
          )
        : prov.injuries.isEmpty
        ? const _EmptyWidget()
        : _selectedInjuryId != null
        ? _TreatmentDetail(
            injury: prov.injuries.firstWhere(
              (i) => i.id == _selectedInjuryId,
              orElse: () => prov.injuries.first,
            ),
            data: _getTreatment(
              _selectedInjuryId!,
              _getPhase(
                prov.injuries.firstWhere(
                  (i) => i.id == _selectedInjuryId,
                  orElse: () => prov.injuries.first,
                ),
              ),
            ),
            onBack: () => setState(
              () => _selectedInjuryId = null
            ),
            onUpdate: (data) => setState(
              () => _treatments[_selectedInjuryId!]
                = data
            ),
          )
        : _InjuryList(
            injuries: prov.injuries,
            treatments: _treatments,
            getPhase: _getPhase,
            getTreatment: _getTreatment,
            onSelect: (id) => setState(
              () => _selectedInjuryId = id
            ),
          ),
    );
  }
}

// ─── Treatment Data Model ─────────────────────────

class _TreatmentData {
  _TreatmentData({
    required this.protocol,
    required this.objectives,
    required this.objectivesDone,
    required this.allowed,
    required this.restricted,
    required this.notes,
    required this.history,
  });

  List<String> protocol;
  List<String> objectives;
  List<String> objectivesDone;
  List<String> allowed;
  List<String> restricted;
  String notes;
  List<String> history;

  _TreatmentData copyWith({
    List<String>? protocol,
    List<String>? objectives,
    List<String>? objectivesDone,
    List<String>? allowed,
    List<String>? restricted,
    String? notes,
    List<String>? history,
  }) => _TreatmentData(
    protocol: protocol ?? this.protocol,
    objectives: objectives ?? this.objectives,
    objectivesDone:
      objectivesDone ?? this.objectivesDone,
    allowed: allowed ?? this.allowed,
    restricted: restricted ?? this.restricted,
    notes: notes ?? this.notes,
    history: history ?? this.history,
  );

  int get progressPercent {
    if (objectives.isEmpty) return 0;
    return ((objectivesDone.length /
      objectives.length) * 100).round();
  }
}

// ─── Injury List ──────────────────────────────────

class _InjuryList extends StatelessWidget {
  const _InjuryList({
    required this.injuries,
    required this.treatments,
    required this.getPhase,
    required this.getTreatment,
    required this.onSelect,
  });

  final List<MedecinInjury> injuries;
  final Map<String, _TreatmentData> treatments;
  final int Function(MedecinInjury) getPhase;
  final _TreatmentData Function(String, int)
    getTreatment;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: injuries.length,
      itemBuilder: (_, i) {
        final inj = injuries[i];
        final phase = getPhase(inj);
        final data = getTreatment(inj.id, phase);
        final phaseColor = phase == 1
          ? const Color(0xFF3B82F6)
          : phase == 2
          ? const Color(0xFF8B5CF6)
          : const Color(0xFF22C55E);

        return GestureDetector(
          onTap: () => onSelect(inj.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: OdinColors.glassPanel,
                  border: Border(
                    left: BorderSide(color: phaseColor, width: 3),
                    top: BorderSide(
                      color: OdinColors.panelBorder.withValues(alpha: 0.5),
                    ),
                    right: BorderSide(
                      color: OdinColors.panelBorder.withValues(alpha: 0.5),
                    ),
                    bottom: BorderSide(
                      color: OdinColors.panelBorder.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        inj.name.isNotEmpty
                            ? inj.name
                                .split(' ')
                                .where((s) => s.isNotEmpty)
                                .map((s) => s[0])
                                .take(2)
                                .join()
                                .toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: phaseColor,
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
                            inj.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: OdinColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            inj.injury,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: OdinColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${data.progressPercent}%',
                      style: TextStyle(
                        color: phaseColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Phase $phase',
                        style: TextStyle(
                          color: phaseColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: OdinColors.textMuted.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: i * 70),
          ).slideX(begin: -0.05),
        );
      },
    );
  }
}

// ─── Treatment Detail ─────────────────────────────

class _TreatmentDetail extends StatefulWidget {
  const _TreatmentDetail({
    required this.injury,
    required this.data,
    required this.onBack,
    required this.onUpdate,
  });

  final MedecinInjury injury;
  final _TreatmentData data;
  final VoidCallback onBack;
  final ValueChanged<_TreatmentData> onUpdate;

  @override
  State<_TreatmentDetail> createState() =>
    _TreatmentDetailState();
}

class _TreatmentDetailState
  extends State<_TreatmentDetail> {

  late _TreatmentData _data;
  final _notesCtrl = TextEditingController();
  final _newItemCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _notesCtrl.text = _data.notes;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _newItemCtrl.dispose();
    super.dispose();
  }

  void _save(VoidCallback fn) {
    setState(fn);
    widget.onUpdate(_data);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6)
                    .withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF3B82F6)
                  .withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: OdinColors.panelBorder,
                      borderRadius:
                        BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: OdinColors.textPrimary, size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                      CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.injury.name,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.injury.injury,
                        style: TextStyle(
                          color: OdinColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 48, height: 48,
                      child: CircularProgressIndicator(
                        value: _data.progressPercent
                          / 100,
                        backgroundColor:
                          OdinColors.panelBorder,
                        valueColor:
                          const AlwaysStoppedAnimation(
                            Color(0xFF3B82F6)
                          ),
                        strokeWidth: 3,
                      ),
                    ),
                    Text(
                      '${_data.progressPercent}%',
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Protocol section
        _SectionHeader(
          title: 'Protocole de traitement',
          icon: Icons.medical_services_outlined,
          color: const Color(0xFF3B82F6),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding:
              const EdgeInsets.symmetric(
                horizontal: 16
              ),
            child: Column(
              children: [
                ..._data.protocol.map(
                  (item) => _ProtocolItem(
                    text: item,
                    onDelete: () => _save(() {
                      _data = _data.copyWith(
                        protocol: _data.protocol
                          .where((e) => e != item)
                          .toList(),
                      );
                    }),
                  )
                ),
                _AddItemRow(
                  controller: _newItemCtrl,
                  hint: 'Ajouter un traitement...',
                  color: const Color(0xFF3B82F6),
                  onAdd: () {
                    if (_newItemCtrl.text
                      .trim().isEmpty) {
                      return;
                    }
                    _save(() {
                      _data = _data.copyWith(
                        protocol: [
                          ..._data.protocol,
                          _newItemCtrl.text.trim(),
                        ],
                        history: [
                          ..._data.history,
                          'Ajouté: '
                          '${_newItemCtrl.text.trim()}',
                        ],
                      );
                      _newItemCtrl.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 16)
        ),

        // Objectives section
        _SectionHeader(
          title: 'Objectifs thérapeutiques',
          icon: Icons.flag_outlined,
          color: const Color(0xFF8B5CF6),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding:
              const EdgeInsets.symmetric(
                horizontal: 16
              ),
            child: Column(
              children: _data.objectives.map(
                (obj) {
                  final done = _data.objectivesDone
                    .contains(obj);
                  return GestureDetector(
                    onTap: () => _save(() {
                      final updated = List<String>.from(
                        _data.objectivesDone
                      );
                      if (done) {
                        updated.remove(obj);
                      } else {
                        updated.add(obj);
                      }
                      _data = _data.copyWith(
                        objectivesDone: updated
                      );
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(
                        bottom: 8
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: done
                          ? const Color(0xFF22C55E)
                            .withValues(alpha: 0.08)
                          : OdinColors.glassPanel,
                        borderRadius:
                          BorderRadius.circular(12),
                        border: Border.all(
                          color: done
                            ? const Color(0xFF22C55E)
                              .withValues(alpha: 0.25)
                            : OdinColors.panelBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              color: done
                                ? const Color(
                                    0xFF22C55E
                                  )
                                : Colors.transparent,
                              borderRadius:
                                BorderRadius.circular(5),
                              border: Border.all(
                                color: done
                                  ? const Color(
                                      0xFF22C55E
                                    )
                                  : OdinColors.textMuted.withValues(alpha: 0.4),
                              ),
                            ),
                            child: done
                              ? Icon(
                                  Icons.check,
                                  color: OdinColors.textPrimary,
                                  size: 12,
                                )
                              : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              obj,
                              style: TextStyle(
                                color: done
                                  ? OdinColors.textSecondary
                                  : OdinColors.textPrimary,
                                fontSize: 12,
                                decoration: done
                                  ? TextDecoration
                                    .lineThrough
                                  : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              ).toList(),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 16)
        ),

        // Restrictions
        _SectionHeader(
          title: 'Restrictions médicales',
          icon: Icons.block_outlined,
          color: const Color(0xFFF59E0B),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding:
              const EdgeInsets.symmetric(
                horizontal: 16
              ),
            child: Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                // Allowed
                Text(
                  '✅ Autorisé',
                  style: TextStyle(
                    color: const Color(0xFF22C55E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ..._data.allowed.map(
                  (item) => _RestrictionItem(
                    text: item,
                    color: const Color(0xFF22C55E),
                    onDelete: () => _save(() {
                      _data = _data.copyWith(
                        allowed: _data.allowed
                          .where((e) => e != item)
                          .toList(),
                      );
                    }),
                  )
                ),
                const SizedBox(height: 12),
                // Restricted
                Text(
                  '❌ Interdit',
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ..._data.restricted.map(
                  (item) => _RestrictionItem(
                    text: item,
                    color: const Color(0xFFEF4444),
                    onDelete: () => _save(() {
                      _data = _data.copyWith(
                        restricted: _data.restricted
                          .where((e) => e != item)
                          .toList(),
                      );
                    }),
                  )
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 16)
        ),

        // Notes
        _SectionHeader(
          title: 'Notes cliniques',
          icon: Icons.note_outlined,
          color: const Color(0xFFFF7A00),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 4,
              style: TextStyle(
                color: OdinColors.textPrimary, fontSize: 13
              ),
              onChanged: (v) => _save(
                () => _data = _data.copyWith(
                  notes: v
                )
              ),
              decoration: InputDecoration(
                hintText:
                  'Observations cliniques...',
                hintStyle: TextStyle(
                  color: OdinColors.textMuted.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: OdinColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius:
                    BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFFFF7A00)
                      .withValues(alpha: 0.25),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                    BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFFFF7A00)
                      .withValues(alpha: 0.20),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                    BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF7A00),
                  ),
                ),
                contentPadding: const EdgeInsets.all(
                  14
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 16)
        ),

        // History
        _SectionHeader(
          title: 'Historique du traitement',
          icon: Icons.history,
          color: const Color(0xFF0D9488),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final item = _data.history.reversed
                .toList()[i];
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 8
                ),
                child: Row(
                  crossAxisAlignment:
                    CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0D9488
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < _data.history.length-1)
                          Container(
                            width: 1, height: 24,
                            color: OdinColors.panelBorder,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding:
                          const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(
                          bottom: 4
                        ),
                        decoration: BoxDecoration(
                          color: OdinColors.glassPanel,
                          borderRadius:
                            BorderRadius.circular(10),
                          border: Border.all(
                            color: OdinColors.panelBorder.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: OdinColors.textPrimary.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: _data.history.length,
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 32)
        ),
      ],
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) =>
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16, 0, 16, 10
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: OdinColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
}

class _ProtocolItem extends StatelessWidget {
  const _ProtocolItem({
    required this.text,
    required this.onDelete,
  });
  final String text;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) =>
    Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 10
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6)
          .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF3B82F6)
            .withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: OdinColors.textPrimary, fontSize: 12
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              color: OdinColors.textMuted.withValues(alpha: 0.5),
              size: 16,
            ),
          ),
        ],
      ),
    );
}

class _RestrictionItem extends StatelessWidget {
  const _RestrictionItem({
    required this.text,
    required this.color,
    required this.onDelete,
  });
  final String text;
  final Color color;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) =>
    Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 10
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: OdinColors.textPrimary, fontSize: 12
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              color: OdinColors.textMuted.withValues(alpha: 0.5),
              size: 16,
            ),
          ),
        ],
      ),
    );
}

class _AddItemRow extends StatelessWidget {
  const _AddItemRow({
    required this.controller,
    required this.hint,
    required this.color,
    required this.onAdd,
  });
  final TextEditingController controller;
  final String hint;
  final Color color;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) =>
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: OdinColors.textPrimary, fontSize: 12
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: OdinColors.textMuted.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              filled: true,
              fillColor: OdinColors.inputFill,
              border: OutlineInputBorder(
                borderRadius:
                  BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10
                ),
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius:
                BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: 0.30),
              ),
            ),
            child: Icon(
              Icons.add, color: color, size: 18
            ),
          ),
        ),
      ],
    );
}

// ─── Loading / Error / Empty ──────────────────────

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();
  @override
  Widget build(BuildContext context) =>
    Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFF7A00), strokeWidth: 2
          ),
          SizedBox(height: 12),
          Text(
            'Chargement des traitements...',
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
                color: Color(0xFFFF7A00)
              ),
            ),
          ),
        ],
      ),
    );
}

class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();
  @override
  Widget build(BuildContext context) =>
    Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Color(0xFF22C55E), size: 40
          ),
          SizedBox(height: 12),
          Text(
            'Aucune blessure active',
            style: TextStyle(
              color: OdinColors.textSecondary, fontSize: 14
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Les traitements apparaîtront\naprès enregistrement des blessures',
            style: TextStyle(
              color: OdinColors.textMuted, fontSize: 12
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
}
