import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/odin_colors.dart';

/// Sheet de formulaire au-dessus de la navbar (root navigator + clavier).
Future<T?> showOdinFormSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext ctx) builder,
}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      final viewInset = MediaQuery.viewInsetsOf(ctx).bottom;
      final safe = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: viewInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: OdinColors.panelSolid,
            elevation: 12,
            shadowColor: OdinColors.shadow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
                maxWidth: 560,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: OdinColors.panelBorder,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: OdinColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: OdinColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        20 + (safe > 0 ? safe : 12),
                      ),
                      child: builder(ctx),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
