import 'package:flutter/material.dart';

/// Adds a visible border without inserting a second traversal stop.
class FocusHighlight extends StatefulWidget {
  const FocusHighlight({super.key, required this.child});
  final Widget child;
  @override
  State<FocusHighlight> createState() => _FocusHighlightState();
}

class _FocusHighlightState extends State<FocusHighlight> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onFocusChange: (value) {
      setState(() => _focused = value);
      if (value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _focused) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 180),
              alignment: .5,
            );
          }
        });
      }
    },
    child: AnimatedContainer(
      key: const Key('focus-highlight-border'),
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          width: 3,
          color: _focused
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withAlpha(140),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: widget.child,
    ),
  );
}

/// Follow remote focus through nested shelves without taking keys from controls.
class FocusScrollScope extends StatefulWidget {
  const FocusScrollScope({super.key, required this.child});
  final Widget child;
  @override
  State<FocusScrollScope> createState() => _FocusScrollScopeState();
}

class _FocusScrollScopeState extends State<FocusScrollScope> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_follow);
  }

  void _follow() {
    final node = FocusManager.instance.primaryFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || node != FocusManager.instance.primaryFocus) return;
      final target = node?.context;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 180),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_follow);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    policy: ReadingOrderTraversalPolicy(),
    child: widget.child,
  );
}
