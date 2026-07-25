import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../models/scout_models.dart';
import '../../providers/scout_provider.dart';
import 'widgets/scout_bubble_map.dart';
import 'widgets/scout_map_geo.dart';

enum _MapLevel { continents, countries, teams, squad }

class ScoutMapScreen extends StatefulWidget {
  const ScoutMapScreen({super.key});

  @override
  State<ScoutMapScreen> createState() => _ScoutMapScreenState();
}

class _ScoutMapScreenState extends State<ScoutMapScreen> {
  _MapLevel _level = _MapLevel.continents;
  bool _loading = true;
  String? _error;
  String? _season;
  int _totalClubs = 0;

  ScoutMapContinent? _continent;
  ScoutMapCountry? _country;
  ScoutMapTeam? _team;
  String? _selectedId;

  List<ScoutMapContinent> _continents = [];
  List<ScoutMapCountry> _countries = [];
  List<ScoutMapTeam> _teams = [];
  List<ScoutSquadPlayer> _squad = [];

  int get _step => _level.index;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContinents());
  }

  Future<void> _loadContinents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ScoutDataProvider>().api;
      final overview = await api.getMapOverview();
      _continents = (overview['continents'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ScoutMapContinent.fromJson)
              .toList() ??
          [];
      _season = overview['season']?.toString();
      final stats = overview['stats'];
      if (stats is Map<String, dynamic>) {
        _totalClubs = (stats['clubs'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCountries(ScoutMapContinent c) async {
    setState(() {
      _loading = true;
      _error = null;
      _continent = c;
      _country = null;
      _team = null;
      _selectedId = c.id;
      _level = _MapLevel.countries;
    });
    try {
      final api = context.read<ScoutDataProvider>().api;
      _countries = await api.getMapCountries(c.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTeams(ScoutMapCountry c) async {
    setState(() {
      _loading = true;
      _error = null;
      _country = c;
      _team = null;
      _selectedId = c.id;
      _level = _MapLevel.teams;
    });
    try {
      final api = context.read<ScoutDataProvider>().api;
      _teams = await api.getMapTeams(c.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSquad(ScoutMapTeam t, {bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _team = t;
      _selectedId = t.id;
      _level = _MapLevel.squad;
    });
    try {
      final api = context.read<ScoutDataProvider>().api;
      _squad = await api.getTeamSquad(t.id, refresh: refresh);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    setState(() {
      _error = null;
      switch (_level) {
        case _MapLevel.squad:
          _level = _MapLevel.teams;
          _team = null;
          _selectedId = _country?.id;
        case _MapLevel.teams:
          _level = _MapLevel.countries;
          _country = null;
          _selectedId = _continent?.id;
        case _MapLevel.countries:
          _level = _MapLevel.continents;
          _continent = null;
          _selectedId = null;
        case _MapLevel.continents:
          break;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _level = _MapLevel.continents;
      _continent = null;
      _country = null;
      _team = null;
      _countries = [];
      _teams = [];
      _squad = [];
      _selectedId = null;
      _error = null;
    });
  }

  Future<void> _refresh() async {
    switch (_level) {
      case _MapLevel.continents:
        await _loadContinents();
      case _MapLevel.countries:
        if (_continent != null) await _loadCountries(_continent!);
      case _MapLevel.teams:
        if (_country != null) await _loadTeams(_country!);
      case _MapLevel.squad:
        if (_team != null) await _loadSquad(_team!, refresh: true);
    }
  }

  void _onPlayerTap(ScoutSquadPlayer p) {
    HapticFeedback.selectionClick();
    if (p.inDatabase && (p.prospectId?.isNotEmpty ?? false)) {
      context.go('/scout/prospect/${p.prospectId}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} n\'est pas encore dans l\'annuaire club'),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    return AppColors.accent;
  }

  List<ScoutMapPin> get _pins {
    switch (_level) {
      case _MapLevel.continents:
        return _continents
            .map(
              (c) => ScoutMapPin(
                id: c.id,
                name: c.name,
                count: c.prospects,
                level: 'continent',
                color: _hexColor(c.color),
                point: mapNodeCoords(c.id, 'continent'),
                logoUrl: continentLogoUrl(c.id),
                icon: c.icon,
              ),
            )
            .toList();
      case _MapLevel.countries:
        return _countries
            .map(
              (c) => ScoutMapPin(
                id: c.id,
                name: c.name,
                count: c.prospects,
                level: 'country',
                color: AppColors.accent,
                point: mapNodeCoords(c.id, 'country'),
                logoUrl: c.leagueLogoUrl?.isNotEmpty == true
                    ? c.leagueLogoUrl
                    : countryLeagueLogoUrl(
                        c.id,
                        leagueId: c.leagueId,
                        leagueName: c.leagues.isNotEmpty ? c.leagues.first : null,
                      ),
                icon: c.flag,
              ),
            )
            .toList();
      case _MapLevel.teams:
        return _teams
            .map(
              (t) => ScoutMapPin(
                id: t.id,
                name: t.name,
                count: t.playerCount,
                level: 'team',
                color: AppColors.accent,
                point: mapNodeCoords(t.id, 'team', parentId: _country?.id, name: t.name),
                logoUrl: resolveTeamLogoUrl(t.id, teamName: t.name, directLogo: t.logoUrl),
              ),
            )
            .toList();
      case _MapLevel.squad:
        return const [];
    }
  }

  String get _hint {
    switch (_level) {
      case _MapLevel.continents:
        return 'Touchez un continent sur la carte';
      case _MapLevel.countries:
        return 'Sélectionnez un pays';
      case _MapLevel.teams:
        return 'Choisissez une équipe';
      case _MapLevel.squad:
        return '';
    }
  }

  List<String> get _stepLabels => [
        'Continent',
        _continent?.name ?? 'Pays',
        _country?.name ?? 'Équipe',
        _team?.name ?? 'Résultats',
      ];

  void _onPinSelect(ScoutMapPin pin) {
    HapticFeedback.selectionClick();
    if (pin.level == 'continent') {
      final c = _continents.where((x) => x.id == pin.id).firstOrNull;
      if (c != null) _loadCountries(c);
    } else if (pin.level == 'country') {
      final c = _countries.where((x) => x.id == pin.id).firstOrNull;
      if (c != null) _loadTeams(c);
    } else if (pin.level == 'team') {
      final t = _teams.where((x) => x.id == pin.id).firstOrNull;
      if (t != null) _loadSquad(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.public_rounded, color: AppColors.accent, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Exploration Géographique',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Continent → Pays → Équipe · $_totalClubs clubs · saison ${_season ?? '2026-2027'}',
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
                        ),
                      ],
                    ),
                  ),
                  if (_step > 0) ...[
                    _GhostBtn(icon: Icons.chevron_left_rounded, label: 'Retour', onTap: _goBack),
                    const SizedBox(width: 6),
                    _GhostBtn(icon: Icons.restart_alt_rounded, label: 'Reset', onTap: _reset),
                  ],
                ],
              ),
              index: 0,
            ),
            const SizedBox(height: 14),
            OdinAnimations.fadeUp(_StepIndicator(step: _step, labels: _stepLabels), index: 1),
            if (_continent != null || _country != null || _team != null) ...[
              const SizedBox(height: 12),
              OdinAnimations.fadeUp(
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (_continent != null)
                      _BreadcrumbChip('${_continent!.icon} ${_continent!.name}'),
                    if (_country != null)
                      _BreadcrumbChip('${_country!.flag} ${_country!.name}'),
                    if (_team != null) _BreadcrumbChip('⚽ ${_team!.name}'),
                  ],
                ),
                index: 2,
              ),
            ],
            const SizedBox(height: 14),
            if (_loading && _continents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
              )
            else if (_error != null && _continents.isEmpty)
              GlassCard(
                child: SaasEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Erreur de chargement',
                  subtitle: _error!,
                  actionLabel: 'Réessayer',
                  onAction: _refresh,
                  compact: true,
                ),
              )
            else ...[
              if (_level != _MapLevel.squad)
                OdinAnimations.scaleIn(
                  ScoutBubbleMap(
                    pins: _pins,
                    step: _step,
                    continentId: _continent?.id,
                    countryId: _country?.id,
                    selectedId: _selectedId,
                    hint: _hint,
                    onSelect: _onPinSelect,
                  ),
                )
              else
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        Icon(Icons.groups_rounded, color: AppColors.accent, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          'Effectif · ${_team?.name ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Consultez la liste ci-dessous',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                )
              else if (_error != null)
                GlassCard(
                  child: SaasEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Erreur',
                    subtitle: _error!,
                    actionLabel: 'Réessayer',
                    onAction: _refresh,
                    compact: true,
                  ),
                )
              else ...[
                Text(
                  switch (_level) {
                    _MapLevel.continents => 'CONTINENTS DISPONIBLES',
                    _MapLevel.countries => 'PAYS',
                    _MapLevel.teams => 'ÉQUIPES & CLUBS',
                    _MapLevel.squad => 'JOUEURS',
                  },
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: KeyedSubtree(
                    key: ValueKey(_level),
                    child: Column(
                      children: switch (_level) {
                        _MapLevel.continents => _buildContinents(),
                        _MapLevel.countries => _buildCountries(),
                        _MapLevel.teams => _buildTeams(),
                        _MapLevel.squad => _buildSquad(),
                      },
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContinents() {
    if (_continents.isEmpty) {
      return [
        SaasEmptyState(
          title: 'Aucun continent',
          subtitle: 'Les données cartographiques seront synchronisées',
          icon: Icons.public_off_rounded,
          onAction: _loadContinents,
        ),
      ];
    }
    return List.generate(_continents.length, (i) {
      final c = _continents[i];
      final color = _hexColor(c.color);
      final selected = _selectedId == c.id;
      return OdinAnimations.fadeUp(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            onTap: () {
              HapticFeedback.selectionClick();
              _loadCountries(c);
            },
            accentColor: color,
            child: Row(
              children: [
                _LogoTile(url: continentLogoUrl(c.id), fallback: c.icon, color: color, selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(
                        '${c.countries} pays · ${c.prospects} prospects',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${c.prospects}', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
        index: i,
      );
    });
  }

  List<Widget> _buildCountries() {
    if (_countries.isEmpty) {
      return [
        SaasEmptyState(
          title: 'Aucun pays',
          subtitle: 'Aucune donnée pour ce continent',
          icon: Icons.flag_outlined,
          onAction: _refresh,
        ),
      ];
    }
    return List.generate(_countries.length, (i) {
      final c = _countries[i];
      final leagueLogo = c.leagueLogoUrl?.isNotEmpty == true
          ? c.leagueLogoUrl
          : countryLeagueLogoUrl(
              c.id,
              leagueId: c.leagueId,
              leagueName: c.leagues.isNotEmpty ? c.leagues.first : null,
            );
      return OdinAnimations.fadeUp(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            onTap: () {
              HapticFeedback.selectionClick();
              _loadTeams(c);
            },
            child: Row(
              children: [
                _LogoTile(
                  url: leagueLogo,
                  fallback: c.flag.isNotEmpty ? c.flag : '🏆',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(
                        '${c.teamCount} clubs · ${c.prospects} prospects${c.leagues.isNotEmpty ? ' · ${c.leagues.first}' : ''}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
        index: i,
      );
    });
  }

  List<Widget> _buildTeams() {
    if (_teams.isEmpty) {
      return [
        SaasEmptyState(
          title: 'Aucun club',
          subtitle: 'Aucune équipe trouvée dans ce pays',
          icon: Icons.stadium_outlined,
          onAction: _refresh,
        ),
      ];
    }
    return List.generate(_teams.length, (i) {
      final t = _teams[i];
      return OdinAnimations.fadeUp(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            onTap: () {
              HapticFeedback.selectionClick();
              _loadSquad(t);
            },
            child: Row(
              children: [
                _LogoTile(
                  url: resolveTeamLogoUrl(t.id, teamName: t.name, directLogo: t.logoUrl),
                  fallback: '⚽',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(
                        '${t.league}${t.city.isNotEmpty ? ' · ${t.city}' : ''}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                      Text(
                        '${t.playerCount} joueurs · Pot. moy. ${t.avgPotential}',
                        style: TextStyle(color: AppColors.accent.withValues(alpha: 0.85), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (t.dbProspects > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${t.dbProspects} DB', style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
        index: i,
      );
    });
  }

  List<Widget> _buildSquad() {
    if (_squad.isEmpty) {
      return [
        SaasEmptyState(
          title: 'Effectif vide',
          subtitle: 'Aucun joueur trouvé pour ce club',
          icon: Icons.groups_outlined,
          onAction: () => _team != null ? _loadSquad(_team!, refresh: true) : _refresh,
        ),
      ];
    }
    return List.generate(_squad.length, (i) {
      final p = _squad[i];
      return OdinAnimations.fadeUp(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            onTap: () => _onPlayerTap(p),
            child: Row(
              children: [
                ScoutPlayerAvatar(name: p.name, photoUrl: p.photoUrl, flag: p.flag, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(
                        '${p.position} · ${p.age} ans · ${p.nationality}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.potential}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: p.potential >= 85 ? AppColors.success : AppColors.accent,
                      ),
                    ),
                    if (p.inDatabase)
                      const Text('En base', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700))
                    else
                      Text('Externe', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
        index: i,
      );
    });
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    const icons = ['🌍', '🏳️', '🏟️', '👤'];
    return Row(
      children: List.generate(4, (i) {
        final done = i < step;
        final active = i == step;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppColors.accent
                            : active
                                ? AppColors.accent.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: done || active ? AppColors.accent : Colors.white.withValues(alpha: 0.12),
                          width: 2,
                        ),
                        boxShadow: active
                            ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 12)]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          done ? '✓' : icons[i],
                          style: TextStyle(fontSize: done ? 14 : 13, color: done ? Colors.white : null),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < step ? AppColors.accent : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.accent),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({
    required this.url,
    required this.fallback,
    required this.color,
    this.selected = false,
  });

  final String? url;
  final String fallback;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? color : Colors.white.withValues(alpha: 0.1), width: selected ? 2 : 1),
      ),
      child: url != null && url!.isNotEmpty
          ? Image.network(
              url!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(child: Text(fallback.isNotEmpty ? fallback : '🌍', style: const TextStyle(fontSize: 18))),
            )
          : Center(child: Text(fallback.isNotEmpty ? fallback : '🌍', style: const TextStyle(fontSize: 18))),
    );
  }
}
