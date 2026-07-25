import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/avatar_change_sheet.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../models/scout_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/scout_provider.dart';

const _kPositions = ['BU', 'MC', 'DC', 'Ailier G', 'Ailier D', 'DG', 'DD', 'GK', 'MOC', 'MDC'];
const _kRegions = [
  'Afrique du Nord',
  'Afrique de l\'Ouest',
  'Afrique Centrale',
  'Europe',
  'Royaume-Uni',
  'Amérique du Sud',
  'Moyen-Orient',
  'Asie',
];

class ScoutSettingsScreen extends StatefulWidget {
  const ScoutSettingsScreen({super.key});

  @override
  State<ScoutSettingsScreen> createState() => _ScoutSettingsScreenState();
}

class _ScoutSettingsScreenState extends State<ScoutSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _clubCtrl = TextEditingController();
  final _leagueCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _ageMinCtrl = TextEditingController();
  final _ageMaxCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  List<String> _regions = [];
  List<String> _positions = [];
  bool _notifyProspect = true;
  bool _notifyShortlist = true;
  bool _notifyMission = true;

  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  String? _error;
  ScoutProfile? _meta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _specCtrl.dispose();
    _clubCtrl.dispose();
    _leagueCtrl.dispose();
    _countryCtrl.dispose();
    _ageMinCtrl.dispose();
    _ageMaxCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _hydrate(ScoutProfile p) {
    _meta = p;
    _nameCtrl.text = p.fullName;
    _phoneCtrl.text = p.phone;
    _specCtrl.text = p.specialization;
    _clubCtrl.text = p.clubName;
    _leagueCtrl.text = p.league;
    _countryCtrl.text = p.country;
    _ageMinCtrl.text = p.ageMin;
    _ageMaxCtrl.text = p.ageMax;
    _budgetCtrl.text = p.budgetMax;
    _regions = List.of(p.regions);
    _positions = List.of(p.positions);
    _notifyProspect = p.notifyNewProspect;
    _notifyShortlist = p.notifyShortlist;
    _notifyMission = p.notifyMissionReminder;
  }

  Future<void> _syncAvatar(ScoutProfile p) async {
    final email = p.email.isNotEmpty ? p.email : context.read<AuthProvider>().user?.email;
    final avatar = context.read<AvatarProvider>();
    await avatar.bindUser(email);
    if (p.avatarUrl.trim().isNotEmpty) {
      await avatar.syncFromRemote(p.avatarUrl);
    }
  }

  Future<void> _persistAvatarUrl(String url) async {
    try {
      final updated = await context.read<ScoutDataProvider>().updateProfile({'avatarUrl': url});
      if (!mounted) return;
      setState(() => _hydrate(updated));
    } catch (_) {
      // Local ImgBB URL already saved; backend sync may fail until redeploy.
    }
  }

  Future<void> _clearAvatarRemote() async {
    try {
      final updated = await context.read<ScoutDataProvider>().updateProfile({'avatarUrl': ''});
      if (!mounted) return;
      setState(() => _hydrate(updated));
    } catch (_) {}
  }

  Future<void> _changeAvatar() async {
    await showAvatarChangeSheet(
      context,
      onUploaded: _persistAvatarUrl,
      onCleared: _clearAvatarRemote,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await context.read<ScoutDataProvider>().refreshProfile();
      if (!mounted) return;
      await _syncAvatar(p);
      if (!mounted) return;
      setState(() {
        _hydrate(p);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final fallback = context.read<ScoutDataProvider>().profile ??
          ScoutProfile(
            fullName: auth.user?.fullName ?? auth.user?.email.split('@').first ?? 'Scout',
            email: auth.user?.email ?? '',
            clubName: auth.user?.organization?.clubName ?? '',
          );
      await _syncAvatar(fallback);
      if (!mounted) return;
      setState(() {
        _hydrate(fallback);
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom complet requis'), backgroundColor: AppColors.danger),
      );
      return;
    }
    final ageMin = int.tryParse(_ageMinCtrl.text.trim()) ?? 16;
    final ageMax = int.tryParse(_ageMaxCtrl.text.trim()) ?? 25;
    if (ageMin > ageMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Âge min doit être ≤ âge max'), backgroundColor: AppColors.danger),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    try {
      final body = {
        'fullName': name,
        'phone': _phoneCtrl.text.trim(),
        'specialization': _specCtrl.text.trim(),
        'clubName': _clubCtrl.text.trim(),
        'league': _leagueCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'regions': _regions,
        'positions': _positions,
        'budgetMax': _budgetCtrl.text.trim().isEmpty ? '25' : _budgetCtrl.text.trim(),
        'ageMin': '$ageMin',
        'ageMax': '$ageMax',
        'notifyNewProspect': _notifyProspect,
        'notifyShortlist': _notifyShortlist,
        'notifyMissionReminder': _notifyMission,
        'language': 'fr',
      };
      final updated = await context.read<ScoutDataProvider>().updateProfile(body);
      if (!mounted) return;
      setState(() {
        _hydrate(updated);
        _saving = false;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil scout enregistré ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _toggle(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final avatar = context.watch<AvatarProvider>();
    final stats = _meta?.stats ?? const ScoutProfileStats();
    final email = _meta?.email.isNotEmpty == true ? _meta!.email : (auth.user?.email ?? '');
    final club = _clubCtrl.text.trim().isNotEmpty
        ? _clubCtrl.text.trim()
        : (_meta?.clubName.isNotEmpty == true
            ? _meta!.clubName
            : (auth.user?.organization?.clubName ?? 'Club'));
    final avatarUrl = avatar.avatarUrl;

    if (_loading) {
      return const OdinBackdrop(
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
        children: [
          OdinAnimations.fadeUp(
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mon profil Scout', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text(
                        'Modifiez vos infos & préférences',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : _load,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.accent,
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            index: 0,
          ),
          const SizedBox(height: 14),
          OdinAnimations.fadeUp(
            GlassCard(
              raised: true,
              accentColor: AppColors.accent,
              child: Row(
                children: [
                  Builder(
                    builder: (_) {
                      final n = _nameCtrl.text.trim().isEmpty ? 'Scout' : _nameCtrl.text.trim();
                      final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
                      final initials = parts.isEmpty
                          ? 'S'
                          : parts.length == 1
                              ? parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase()
                              : '${parts.first[0]}${parts[1][0]}'.toUpperCase();
                      return GestureDetector(
                        onTap: avatar.uploading ? null : _changeAvatar,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: avatarUrl == null
                                    ? const LinearGradient(
                                        colors: [Color(0xFFFF9A3D), Color(0xFFE66000)],
                                      )
                                    : null,
                                image: avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(avatarUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: avatarUrl == null
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            if (avatar.uploading)
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF0B0B14), width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 11, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameCtrl.text.trim().isEmpty ? 'Scout' : _nameCtrl.text.trim(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        Text(_meta?.role ?? 'Scout', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '$club · ${_meta?.league.isNotEmpty == true ? _meta!.league : '—'}',
                          style: TextStyle(
                            color: AppColors.accent.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Appuyez sur la photo pour la changer (ImgBB)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            index: 1,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            GlassCard(
              child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 16),
          OdinAnimations.fadeUp(const ScoutSectionLabel('Informations personnelles'), index: 2),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Column(
                children: [
                  _Field(label: 'Nom complet', controller: _nameCtrl, onChanged: (_) => setState(() {})),
                  _Field(label: 'Email', initialValue: email, readOnly: true),
                  _Field(label: 'Téléphone', controller: _phoneCtrl, keyboard: TextInputType.phone),
                  _Field(label: 'Spécialisation', controller: _specCtrl),
                ],
              ),
            ),
            index: 3,
          ),
          const SizedBox(height: 16),
          OdinAnimations.fadeUp(const ScoutSectionLabel('Club (organisation)'), index: 4),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Column(
                children: [
                  _Field(label: 'Club', controller: _clubCtrl, onChanged: (_) => setState(() {})),
                  _Field(label: 'Ligue', controller: _leagueCtrl),
                  _Field(label: 'Pays', controller: _countryCtrl),
                  _InfoRow('Saison', _meta?.season ?? '2026-2027'),
                ],
              ),
            ),
            index: 5,
          ),
          const SizedBox(height: 16),
          OdinAnimations.fadeUp(const ScoutSectionLabel('Critères de recherche'), index: 6),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _Field(label: 'Âge min', controller: _ageMinCtrl, keyboard: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: _Field(label: 'Âge max', controller: _ageMaxCtrl, keyboard: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: _Field(label: 'Budget M€', controller: _budgetCtrl, keyboard: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('POSTES CIBLÉS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.4))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _kPositions.map((pos) {
                      final on = _positions.contains(pos);
                      return ChoiceChip(
                        label: Text(pos, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: on ? Colors.white : AppColors.muted)),
                        selected: on,
                        onSelected: (_) => _toggle(_positions, pos),
                        selectedColor: AppColors.accent,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        side: BorderSide(color: on ? AppColors.accent : Colors.white24),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text('RÉGIONS COUVERTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.4))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _kRegions.map((r) {
                      final on = _regions.contains(r);
                      return FilterChip(
                        label: Text(r, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: on ? AppColors.info : AppColors.muted)),
                        selected: on,
                        onSelected: (_) => _toggle(_regions, r),
                        selectedColor: AppColors.info.withValues(alpha: 0.2),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        checkmarkColor: AppColors.info,
                        side: BorderSide(color: on ? AppColors.info.withValues(alpha: 0.5) : Colors.white24),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            index: 7,
          ),
          const SizedBox(height: 16),
          OdinAnimations.fadeUp(const ScoutSectionLabel('Notifications'), index: 8),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Column(
                children: [
                  _SwitchRow(
                    label: 'Nouveau prospect correspondant',
                    value: _notifyProspect,
                    onChanged: (v) => setState(() => _notifyProspect = v),
                  ),
                  _SwitchRow(
                    label: 'Mise à jour shortlist / comité',
                    value: _notifyShortlist,
                    onChanged: (v) => setState(() => _notifyShortlist = v),
                  ),
                  _SwitchRow(
                    label: 'Rappels missions (24h avant)',
                    value: _notifyMission,
                    onChanged: (v) => setState(() => _notifyMission = v),
                  ),
                ],
              ),
            ),
            index: 9,
          ),
          const SizedBox(height: 16),
          OdinAnimations.fadeUp(const ScoutSectionLabel('Statistiques'), index: 10),
          const SizedBox(height: 8),
          SizedBox(
            height: 108,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ScoutKpiCard(label: 'Missions/mois', value: '${stats.missionsThisMonth}', icon: Icons.flag_rounded, color: AppColors.accent),
                const SizedBox(width: 10),
                ScoutKpiCard(label: 'Rapports', value: '${stats.reportsSubmitted}', icon: Icons.assignment_rounded, color: const Color(0xFF3B82F6)),
                const SizedBox(width: 10),
                ScoutKpiCard(label: 'Ce mois', value: '${stats.reportsThisMonth}', icon: Icons.calendar_today_rounded, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 10),
                ScoutKpiCard(label: 'Prospects', value: '${stats.prospectsFollowed}', icon: Icons.groups_rounded, color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OdinAnimations.fadeUp(
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_saved ? Icons.check_rounded : Icons.save_rounded),
                label: Text(
                  _saved ? 'Enregistré ✓' : _saving ? 'Enregistrement…' : 'Enregistrer le profil',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _saved ? AppColors.success : AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            index: 11,
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.keyboard,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            initialValue: controller == null ? initialValue : null,
            readOnly: readOnly,
            keyboardType: keyboard,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: readOnly ? Colors.white54 : Colors.white,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: readOnly ? 0.02 : 0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
      value: value,
      activeThumbColor: AppColors.accent,
      onChanged: onChanged,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        ],
      ),
    );
  }
}
