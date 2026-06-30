import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/theme/turan_theme.dart';

const turanHeaderPrimary = TuranColors.primary;
const turanHeaderPrimaryDark = TuranColors.primaryDark;
const turanHeaderPrimaryLight = TuranColors.primary;

class TuranHeaderAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const TuranHeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class TuranHeader extends StatelessWidget {
  final UserInfo? user;
  final String title;
  final String subtitle;
  final String pageLabel;
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  final List<TuranHeaderAction> actions;
  final Widget? bottom;

  const TuranHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pageLabel,
    this.user,
    this.onBack,
    this.onLogout,
    this.actions = const [],
    this.bottom,
  });

  String get _initials {
    final current = user;
    if (current == null) return 'TS';
    return '${current.name.isNotEmpty ? current.name[0] : ''}'
            '${current.surname.isNotEmpty ? current.surname[0] : ''}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: turanHeaderPrimary,
        boxShadow: [
          BoxShadow(
            color: turanHeaderPrimary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/brand/turan_pattern.png',
                repeat: ImageRepeat.repeat,
                alignment: Alignment.topRight,
                scale: 4.0,
              ),
            ),
          ),
          Positioned(
            right: -50,
            top: -70,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;
                final metaLine = user == null
                    ? (subtitle.trim().isNotEmpty && subtitle.trim() != pageLabel
                        ? subtitle.trim()
                        : '')
                    : (user!.role.trim());
                final showMetaLine = metaLine.isNotEmpty;
                final showBottomSubtitle = subtitle.trim().isNotEmpty &&
                    subtitle.trim() != metaLine &&
                    subtitle.trim() != title.trim() &&
                    subtitle.trim() != pageLabel.trim();
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 22,
                    compact ? 12 : 18,
                    compact ? 16 : 22,
                    compact ? 12 : 18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (onBack != null) ...[
                            _CircleButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: onBack!,
                              compact: compact,
                            ),
                            SizedBox(width: compact ? 8 : 12),
                          ],
                          _Avatar(initials: _initials, compact: compact),
                          SizedBox(width: compact ? 8 : 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user == null
                                      ? pageLabel
                                      : '${user!.name} ${user!.surname}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 14 : 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (showMetaLine) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    metaLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.70),
                                      fontSize: compact ? 11 : 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                SizedBox(height: compact ? 8 : 10),
                                if (title.trim().isNotEmpty &&
                                    title.trim() != pageLabel.trim())
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 21 : 27,
                                      height: 1,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                if (showBottomSubtitle) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.78),
                                      fontSize: compact ? 11 : 13,
                                      height: 1.1,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (onLogout != null) ...[
                            _CircleButton(
                              icon: Icons.logout_rounded,
                              onTap: onLogout!,
                              compact: compact,
                            ),
                            SizedBox(width: compact ? 8 : 12),
                          ],
                          _LogoCard(pageLabel: pageLabel, compact: compact),
                        ],
                      ),
                      if (actions.isNotEmpty) ...[
                        SizedBox(height: compact ? 10 : 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...actions.map(
                              (action) => _HeaderPill(
                                icon: action.icon,
                                label: action.label,
                                onTap: action.onTap,
                                compact: compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (bottom != null) ...[
                        SizedBox(height: compact ? 10 : 12),
                        bottom!,
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final bool compact;

  const _Avatar({required this.initials, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 38 : 46,
      height: compact ? 38 : 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  final String pageLabel;
  final bool compact;

  const _LogoCard({required this.pageLabel, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/brand/turan_symbol.png',
            width: compact ? 30 : 42,
            height: compact ? 30 : 42,
            fit: BoxFit.contain,
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            const Text(
              'TuranSAT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: compact ? 38 : 42,
          height: compact ? 38 : 42,
          child: Icon(icon, color: Colors.white, size: compact ? 19 : 21),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.13),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 13,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.88), size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
                  fontSize: compact ? 11 : 12,
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
