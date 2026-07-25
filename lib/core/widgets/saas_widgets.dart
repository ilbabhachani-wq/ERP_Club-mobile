import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_tokens.dart';
import '../theme/odin_colors.dart';

/// Empty state SaaS pro — icon + titre + sous-titre + CTA.
class SaasEmptyState extends StatelessWidget {
  const SaasEmptyState({
    super.key,
    required this.title,
    this.subtitle = 'Les données seront synchronisées dès que possible',
    this.icon = Icons.insights_outlined,
    this.actionLabel = 'Actualiser',
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: compact ? AppSpacing.l : AppSpacing.xl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 72 : 88,
            height: compact ? 72 : 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: compact ? 36 : 44, color: AppColors.muted),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
          SizedBox(height: AppSpacing.m),
          Text(
            title,
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.text,
            ),
          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1, end: 0),
          SizedBox(height: AppSpacing.s),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 140.ms),
          if (onAction != null) ...[
            SizedBox(height: AppSpacing.l),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onAction!();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),
          ],
        ],
      ),
    );
  }
}

/// Carte module SaaS — gradient, sous-titre, hauteur fixe, press scale.
class SaasModuleCard extends StatefulWidget {
  const SaasModuleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.height = 140,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double height;

  @override
  State<SaasModuleCard> createState() => _SaasModuleCardState();
}

class _SaasModuleCardState extends State<SaasModuleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: widget.height,
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withValues(alpha: 0.18),
                widget.color.withValues(alpha: 0.04),
                AppColors.card.withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(color: widget.color.withValues(alpha: 0.32)),
            boxShadow: AppShadows.soft(widget.color),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.16),
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: widget.color.withValues(alpha: 0.3)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.muted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton sync avec loading spinner intégré.
class SaasSyncButton extends StatelessWidget {
  const SaasSyncButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.icon = Icons.sync_rounded,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed?.call();
            },
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 18),
      label: Text(loading ? 'Synchronisation…' : label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }
}

/// Skeleton shimmer pour grilles de cards.
class SaasCardSkeleton extends StatelessWidget {
  const SaasCardSkeleton({super.key, this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: OdinColors.panelSolid,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: AppRadius.smAll,
            ),
          ),
          const Spacer(),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
