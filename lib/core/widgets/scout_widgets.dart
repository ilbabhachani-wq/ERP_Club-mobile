import 'package:flutter/material.dart';
import '../theme/odin_colors.dart';
import '../utils/scout_player_photos.dart';

/// Shared scout UI chrome — badges, section labels, prospect tiles.
class ScoutSectionLabel extends StatelessWidget {
  const ScoutSectionLabel(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: OdinColors.textMuted.withValues(alpha: OdinColors.isDark ? 0.9 : 1),
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ScoutPriorityBadge extends StatelessWidget {
  const ScoutPriorityBadge(this.priority, {super.key});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final p = priority.toUpperCase();
    final color = switch (p) {
      'A' => const Color(0xFFEF4444),
      'B' => const Color(0xFFF59E0B),
      _ => const Color(0xFF3B82F6),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Prio $p',
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}

class ScoutWorkflowBadge extends StatelessWidget {
  const ScoutWorkflowBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'new' => 'Nouveau',
      'analysis' => 'Analyse',
      'validation' => 'Validation',
      'signature' => 'Signature',
      'done' => 'Terminé',
      _ => status,
    };
    final color = switch (status) {
      'new' => const Color(0xFF3B82F6),
      'analysis' => const Color(0xFFF59E0B),
      'validation' => const Color(0xFF8B5CF6),
      'signature' => const Color(0xFFFF7A00),
      'done' => const Color(0xFF22C55E),
      _ => Colors.white54,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

class ScoutKpiCard extends StatelessWidget {
  const ScoutKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.04),
            const Color(0xFF16162A),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class ScoutPlayerAvatar extends StatefulWidget {
  const ScoutPlayerAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.size = 44,
    this.flag,
  });

  final String? photoUrl;
  final String name;
  final double size;
  final String? flag;

  @override
  State<ScoutPlayerAvatar> createState() => _ScoutPlayerAvatarState();
}

class _ScoutPlayerAvatarState extends State<ScoutPlayerAvatar> {
  String? _resolved;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ScoutPlayerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name || oldWidget.photoUrl != widget.photoUrl) {
      _failed = false;
      _resolve();
    }
  }

  void _resolve() {
    final immediate = resolveScoutPhotoUrl(widget.name, direct: widget.photoUrl);
    if (immediate != _resolved || _failed) {
      _resolved = immediate;
      _failed = false;
    }
    if (immediate != null) {
      // Rebuild if we resolved after first frame / update
      if (mounted) setState(() {});
      return;
    }

    fetchScoutPlayerPhoto(widget.name).then((url) {
      if (!mounted || url == null) return;
      setState(() {
        _resolved = url;
        _failed = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    final url = (!_failed && _resolved != null && _resolved!.isNotEmpty) ? _resolved : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.28),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: url != null
                  ? [
                      const Color(0xFFFF7A00).withValues(alpha: 0.12),
                      const Color(0xFF080618),
                    ]
                  : const [Color(0xFFFF7A00), Color(0xFFEF4444)],
            ),
            border: Border.all(
              color: url != null
                  ? const Color(0xFFFF7A00).withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: url != null
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  // Image.network utilise <img> sur web → pas de blocage CORS cache
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) {
                    // Essai fallback api-sports si cutout TheSportsDB échoue
                    final fallback = apiSportsPhotoUrl(widget.name);
                    if (fallback != null && fallback != url) {
                      return Image.network(
                        fallback,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, _, _) => _Initials(initials: initials, size: widget.size),
                      );
                    }
                    return _Initials(initials: initials, size: widget.size);
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: widget.size * 0.35,
                        height: widget.size * 0.35,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  },
                )
              : _Initials(initials: initials, size: widget.size),
        ),
        if (widget.flag != null && widget.flag!.isNotEmpty)
          Positioned(
            right: -4,
            bottom: -4,
            child: Text(widget.flag!, style: TextStyle(fontSize: widget.size * 0.28)),
          ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: size * 0.32,
          color: Colors.white,
        ),
      ),
    );
  }
}
