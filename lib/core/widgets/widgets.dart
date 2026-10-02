import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Full-screen dreamy gradient. Installed once via MaterialApp.builder so every
/// transparent Scaffold shows the sky behind it.
class AnimeBackdrop extends StatelessWidget {
  const AnimeBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: dark ? Sakura.duskGradient : Sakura.goldenGradient),
      child: Stack(children: [
        // Soft "bokeh" glows, static on purpose (battery friendly).
        Positioned(top: -90, right: -70, child: _Glow(size: 280, color: (dark ? Sakura.lavender : Sakura.pink).withAlpha(dark ? 55 : 90))),
        Positioned(bottom: 120, left: -110, child: _Glow(size: 300, color: (dark ? Sakura.pink : Sakura.peach).withAlpha(dark ? 40 : 110))),
        Positioned.fill(child: child),
      ]),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withAlpha(0)])),
        ),
      );
}

/// Frosted-glass card with a glowing pastel border and 22px corners.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.glow = false,
    this.radius = Sakura.radius,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool glow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final r = BorderRadius.circular(radius);
    final tint = dark ? Colors.white.withAlpha(22) : Colors.white.withAlpha(165);
    final border = (dark ? Sakura.pink : scheme.primary).withAlpha(glow ? 190 : 95);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [BoxShadow(color: (dark ? Sakura.pink : scheme.primary).withAlpha(glow ? 70 : 28), blurRadius: glow ? 26 : 14, spreadRadius: glow ? 1 : 0)],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: r,
                color: tint,
                border: Border.all(color: border, width: glow ? 1.4 : 1),
              ),
              child: InkWell(borderRadius: r, onTap: onTap, child: Padding(padding: padding, child: child)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Existing screens keep using AppCard; it is now a glass card.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.glow = false});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool glow;

  @override
  Widget build(BuildContext context) => GlassCard(onTap: onTap, padding: padding, glow: glow, child: child);
}

/// Pink-to-lavender gradient button with a soft glow. Wraps a real FilledButton
/// so accessibility, tests and disabled state behave normally.
class GlowButton extends StatelessWidget {
  const GlowButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onGrad = dark ? Sakura.midnight : const Color(0xFF3A1D3F);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          gradient: Sakura.glowGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled ? [BoxShadow(color: Sakura.pink.withAlpha(110), blurRadius: 22, offset: const Offset(0, 6))] : const [],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: onGrad,
            disabledForegroundColor: onGrad,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label),
          ]),
        ),
      ),
    );
  }
}

/// Small rounded status label (LIVE / OFFLINE / NEW).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(36),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(150)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        ]),
      );
}

/// Frosted bottom bar for the NavigationBar.
class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(Sakura.radius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dark ? Sakura.midnight.withAlpha(150) : Colors.white.withAlpha(170),
            border: Border(top: BorderSide(color: Sakura.pink.withAlpha(dark ? 110 : 160))),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Static placeholder line shown while live content loads.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width = double.infinity, this.height = 14});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: Sakura.pink.withAlpha(45), borderRadius: BorderRadius.circular(8)),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class MonoBox extends StatelessWidget {
  const MonoBox(this.text, {super.key, this.copyable = false});
  final String text;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1933),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33FFB7C5)),
      ),
      child: Stack(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsets.only(right: copyable ? 36 : 0),
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5, color: Color(0xFFFFF5F6)),
            ),
          ),
        ),
        if (copyable)
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              tooltip: 'Copy code',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy, size: 18, color: Color(0xFFC9B8E8)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
              },
            ),
          ),
      ]),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: t.colorScheme.primary, size: 22),
            const SizedBox(height: 8),
            Text(value, style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: t.textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}

IconData courseIcon(String key) {
  switch (key) {
    case 'terminal':
      return Icons.terminal;
    case 'lan':
      return Icons.lan_outlined;
    case 'code':
      return Icons.code;
    default:
      return Icons.shield_outlined;
  }
}
