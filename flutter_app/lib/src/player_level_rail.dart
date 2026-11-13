import 'package:flutter/material.dart';

class PlayerLevelRail extends StatelessWidget {
  const PlayerLevelRail({
    super.key,
    required this.value,
    this.height = 180,
    required this.label,
    required this.icon,
    required this.onChanged,
  });
  final double value, height;
  final String label;
  final IconData icon;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      width: 52,
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Icon(
            icon,
            color: Colors.white,
            size: 20,
            shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
          ),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Slider(
                  value: value.clamp(0, 1),
                  onChanged: onChanged,
                  semanticFormatterCallback: (v) =>
                      '$label ${(v * 100).round()}٪',
                ),
              ),
            ),
          ),
          Text(
            '${(value * 100).round()}٪',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              shadows: [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
