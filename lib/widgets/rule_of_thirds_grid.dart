// lib/widgets/rule_of_thirds_grid.dart
import 'package:flutter/material.dart';

class RuleOfThirdsGrid extends StatelessWidget {
  const RuleOfThirdsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Líneas verticales
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Container(width: 1.0, color: Colors.white.withOpacity(0.5)),
            const Expanded(child: SizedBox()),
            Container(width: 1.0, color: Colors.white.withOpacity(0.5)),
            const Expanded(child: SizedBox()),
          ],
        ),
        // Líneas horizontales
        Column(
          children: [
            const Expanded(child: SizedBox()),
            Container(height: 1.0, color: Colors.white.withOpacity(0.5)),
            const Expanded(child: SizedBox()),
            Container(height: 1.0, color: Colors.white.withOpacity(0.5)),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}