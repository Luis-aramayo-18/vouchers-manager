import 'package:flutter/material.dart';

class GridButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isGridActive;

  const GridButton({
    super.key,
    required this.onPressed,
    required this.isGridActive,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            isGridActive ? Icons.grid_off : Icons.grid_on,
            color: Colors.white,
            size: 30,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}