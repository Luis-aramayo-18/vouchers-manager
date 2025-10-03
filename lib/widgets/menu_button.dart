// lib/widgets/menu_button.dart
import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 60, left: 16),
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          child: const Icon(Icons.menu, color: Colors.blue),
        ),
      ),
    );
  }
}