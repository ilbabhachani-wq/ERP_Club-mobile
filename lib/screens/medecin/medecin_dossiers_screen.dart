import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/medecin_provider.dart';
import '../../models/medecin_models.dart';
import '../../core/theme/odin_colors.dart';

class MedecinDossiersScreen extends StatefulWidget {
  const MedecinDossiersScreen({super.key});

  @override
  State<MedecinDossiersScreen> createState() =>
    _MedecinDossiersScreenState();
}

class _MedecinDossiersScreenState
  extends State<MedecinDossiersScreen> {

  String _search = '';
  MedecinPlayer? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedecinProvider>().loadAll();
    });
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
          'Dossiers médicaux',
          style: TextStyle(
            color: OdinColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16, 0, 16, 10
            ),
            child: TextField(
              onChanged: (v) =>
                setState(() => _search = v),
              style: TextStyle(
                color: OdinColors.textPrimary, fontSize: 14
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher un joueur...',
                hintStyle: TextStyle(
                  color: OdinColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: OdinColors.textMuted.withValues(alpha: 0.6),
                  size: 20,
                ),
                filled: true,
                fillColor: OdinColors.panelBorder.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius:
                    BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12
                  ),
              ),
            ),
          ),
        ),
      ),
      body: prov.loading
        ? const _LoadingState()
        : prov.error != null
        ? _ErrorState(
            error: prov.error!,
            onRetry: () => prov.loadAll(),
          )
        : _selected != null
        ? _DossierDetail(
            player: _selected!,
            injuries: prov.injuries.where(
              (i) => i.name.toLowerCase() ==
                _selected!.fullName.toLowerCase()
            ).toList(),
            onBack: () =>
              setState(() => _selected = null),
          )
        : _PlayerList(
            players: prov.players.where((p) =>
              _search.isEmpty ||
              p.fullName.toLowerCase().contains(
                _search.toLowerCase()
              )
            ).toList(),
            injuries: prov.injuries,
            onSelect: (p) =>
              setState(() => _selected = p),
          ),
    );
  }
}

// ─── Player List ─────────────────────────────────

class _PlayerList extends StatelessWidget {
  const _PlayerList({
    required this.players,
    required this.injuries,
    required this.onSelect,
  });

  final List<MedecinPlayer> players;
  final List<MedecinInjury> injuries;
  final ValueChanged<MedecinPlayer> onSelect;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          'Aucun joueur trouvé',
          style: TextStyle(
            color: OdinColors.textSecondary, fontSize: 14
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: players.length,
      itemBuilder: (context, i) {
        final p = players[i];
        final hasInjury = injuries.any(
          (inj) => inj.name.toLowerCase() ==
            p.fullName.toLowerCase()
        );
        final statusColor = _statusColor(p.status);
        return _PlayerCard(
          player: p,
          hasInjury: hasInjury,
          statusColor: statusColor,
          onTap: () => onSelect(p),
        ).animate().fadeIn(
          delay: Duration(milliseconds: i * 60)
        ).slideX(begin: -0.1, end: 0);
      },
    );
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s == 'DISPONIBLE' || s == 'AVAILABLE') {
      return const Color(0xFF22C55E);
    }
    if (s == 'BLESSÉ' || s == 'BLESSE' || s == 'INJURED') {
      return const Color(0xFFEF4444);
    }
    if (s == 'LIMITÉ' || s == 'LIMITE' || s == 'LIMITED') {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF6B7280);
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.hasInjury,
    required this.statusColor,
    required this.onTap,
  });

  final MedecinPlayer player;
  final bool hasInjury;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeLabel = hasInjury
        ? 'Blessé'
        : _translateStatus(player.status);
    final badgeColor = hasInjury
        ? const Color(0xFFEF4444)
        : statusColor;

    return GestureDetector(
      onTap: onTap,
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
              color: OdinColors.inputFill,
              border: Border(
                left: BorderSide(
                  color: statusColor, width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    player.initials,
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
                        player.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _translatePosition(player.position),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textMuted,
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
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeColor,
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
      ),
    );
  }

  String _translateStatus(String s) {
    final up = s.toUpperCase();
    if (up == 'DISPONIBLE' || up == 'AVAILABLE') {
      return 'Disponible';
    }
    if (up == 'BLESSÉ' || up == 'BLESSE' || up == 'INJURED') {
      return 'Blessé';
    }
    if (up == 'LIMITÉ' || up == 'LIMITE') {
      return 'Surveillance';
    }
    return s;
  }

  String _translatePosition(String p) {
    const map = {
      'GK': 'Gardien', 'DC': 'Défenseur central',
      'LB': 'Latéral gauche',
      'RB': 'Latéral droit',
      'MC': 'Milieu central',
      'MD': 'Milieu défensif',
      'MOC': 'Milieu offensif',
      'AG': 'Ailier gauche',
      'AD': 'Ailier droit',
      'BU': 'Buteur', 'ST': 'Attaquant',
    };
    return map[p] ?? p;
  }
}

// ─── Dossier Detail ───────────────────────────────

class _DossierDetail extends StatelessWidget {
  const _DossierDetail({
    required this.player,
    required this.injuries,
    required this.onBack,
  });

  final MedecinPlayer player;
  final List<MedecinInjury> injuries;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(player.status);

    return CustomScrollView(
      slivers: [
        // App bar with player info
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.08
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withValues(
                  alpha: 0.25
                ),
              ),
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: OdinColors.panelBorder,
                      borderRadius:
                        BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: OdinColors.textPrimary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.20
                    ),
                    borderRadius:
                      BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    player.initials,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                      CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(
                            alpha: 0.15
                          ),
                          borderRadius:
                            BorderRadius.circular(99),
                        ),
                        child: Text(
                          _translateStatus(
                            player.status
                          ),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(
            begin: -0.1, end: 0
          ),
        ),

        // Info grid
        SliverToBoxAdapter(
          child: Padding(
            padding:
              const EdgeInsets.symmetric(
                horizontal: 16
              ),
            child: Row(
              children: [
                _InfoCard(
                  label: 'Poste',
                  value: _translatePosition(
                    player.position
                  ),
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 10),
                _InfoCard(
                  label: 'Blessures actives',
                  value: '${injuries.length}',
                  color: injuries.isEmpty
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 16)
        ),

        // Feux tricolores
        SliverToBoxAdapter(
          child: Padding(
            padding:
              const EdgeInsets.symmetric(
                horizontal: 16
              ),
            child: _FauxTricolores(
              status: player.status,
              hasInjury: injuries.isNotEmpty,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 16)
        ),

        // Injuries list
        if (injuries.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16
              ),
              child: Text(
                'Blessures actives',
                style: TextStyle(
                  color: OdinColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 10)
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final inj = injuries[i];
                return Padding(
                  padding:
                    const EdgeInsets.fromLTRB(
                      16, 0, 16, 10
                    ),
                  child: _InjuryCard(injury: inj),
                ).animate().fadeIn(
                  delay: Duration(
                    milliseconds: i * 80
                  )
                );
              },
              childCount: injuries.length,
            ),
          ),
        ] else
          SliverToBoxAdapter(
            child: Padding(
              padding:
                const EdgeInsets.symmetric(
                  horizontal: 16
                ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E)
                    .withValues(alpha: 0.08),
                  borderRadius:
                    BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF22C55E)
                      .withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment:
                    MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF22C55E),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Aucune blessure active',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 32)
        ),
      ],
    );
  }

  Color _statusColor(String s) {
    final up = s.toUpperCase();
    if (up == 'DISPONIBLE' || up == 'AVAILABLE') {
      return const Color(0xFF22C55E);
    }
    if (up == 'BLESSÉ' || up == 'BLESSE' || up == 'INJURED') {
      return const Color(0xFFEF4444);
    }
    if (up == 'LIMITÉ' || up == 'LIMITE' || up == 'LIMITED') {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF6B7280);
  }

  String _translateStatus(String s) {
    final up = s.toUpperCase();
    if (up == 'DISPONIBLE' || up == 'AVAILABLE') {
      return 'Disponible';
    }
    if (up == 'BLESSÉ' || up == 'BLESSE' || up == 'INJURED') {
      return 'Blessé';
    }
    if (up == 'LIMITÉ' || up == 'LIMITE') {
      return 'Surveillance';
    }
    return s;
  }

  String _translatePosition(String p) {
    const map = {
      'GK': 'Gardien', 'DC': 'Défenseur central',
      'LB': 'Latéral gauche',
      'RB': 'Latéral droit',
      'MC': 'Milieu central',
      'MD': 'Milieu défensif',
      'MOC': 'Milieu offensif',
      'AG': 'Ailier gauche',
      'AD': 'Ailier droit',
      'BU': 'Buteur', 'ST': 'Attaquant',
    };
    return map[p] ?? p;
  }
}

// ─── Widgets ─────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border(
              left: BorderSide(color: color, width: 3),
              top: BorderSide(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
              right: BorderSide(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
              bottom: BorderSide(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
              CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: OdinColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FauxTricolores extends StatelessWidget {
  const _FauxTricolores({
    required this.status,
    required this.hasInjury,
  });
  final String status;
  final bool hasInjury;

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final items = [
      (
        label: 'Entraînement',
        ok: s != 'BLESSE' && s != 'BLESSÉ',
      ),
      (
        label: 'Match',
        ok: s == 'DISPONIBLE',
      ),
      (
        label: 'Contact',
        ok: s == 'DISPONIBLE' && !hasInjury,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: OdinColors.glassPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: OdinColors.panelBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          Text(
            'Autorisation médicale',
            style: TextStyle(
              color: OdinColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(
              bottom: 6
            ),
            child: Row(
              mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: OdinColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3
                    ),
                  decoration: BoxDecoration(
                    color: item.ok
                      ? const Color(0xFF22C55E)
                        .withValues(alpha: 0.12)
                      : const Color(0xFFEF4444)
                        .withValues(alpha: 0.12),
                    borderRadius:
                      BorderRadius.circular(99),
                    border: Border.all(
                      color: item.ok
                        ? const Color(0xFF22C55E)
                          .withValues(alpha: 0.30)
                        : const Color(0xFFEF4444)
                          .withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    item.ok
                      ? '✓ Autorisé'
                      : '✗ Interdit',
                    style: TextStyle(
                      color: item.ok
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _InjuryCard extends StatelessWidget {
  const _InjuryCard({required this.injury});
  final MedecinInjury injury;

  @override
  Widget build(BuildContext context) {
    final days = injury.daysRemaining;
    final Color c = days == null
      ? const Color(0xFF6B7280)
      : days < 0
      ? const Color(0xFFEF4444)
      : days <= 7
      ? const Color(0xFF22C55E)
      : const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.withValues(alpha: 0.20),
        ),
        gradient: LinearGradient(
          colors: [
            c.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment:
          CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.healing,
                color: const Color(0xFFEF4444),
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  injury.injury,
                  style: TextStyle(
                    color: OdinColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                  const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3
                  ),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius:
                    BorderRadius.circular(99),
                ),
                child: Text(
                  days == null
                    ? '—'
                    : days < 0
                    ? '${days.abs()}j dépassé'
                    : days == 0
                    ? "Aujourd'hui"
                    : 'J-$days',
                  style: TextStyle(
                    color: c,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _InjuryMeta(
                icon: Icons.location_on_outlined,
                text: injury.bodyPart,
              ),
              const SizedBox(width: 10),
              _InjuryMeta(
                icon: Icons.calendar_today_outlined,
                text: injury.returnDate,
              ),
              const SizedBox(width: 10),
              _InjuryMeta(
                icon: Icons.warning_amber_outlined,
                text: '${injury.riskPercent}% risque',
                color: injury.riskPercent >= 70
                  ? const Color(0xFFEF4444)
                  : injury.riskPercent >= 40
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF22C55E),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InjuryMeta extends StatelessWidget {
  const _InjuryMeta({
    required this.icon,
    required this.text,
    this.color,
  });
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ??
      OdinColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c, size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: c, fontSize: 10
          ),
        ),
      ],
    );
  }
}

// ─── Loading / Error ─────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFF7A00),
            strokeWidth: 2,
          ),
          SizedBox(height: 12),
          Text(
            'Chargement des dossiers...',
            style: TextStyle(
              color: OdinColors.textSecondary, fontSize: 13
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFEF4444),
            size: 40,
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
}
