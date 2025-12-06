import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  // 1. Definir el callback (la función a ejecutar al cerrar sesión)
  final VoidCallback onLogout;

  const MainDrawer({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              // Usaremos el mismo color que la HomePage para mantener la consistencia
              color: Colors.blue, 
            ),
            child: const Text(
              'Vouchers Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.receipt),
            title: Text('Mis Recibos'),
          ),
          const Divider(), // Separador visual

          // 2. Botón de Cierre de Sesión al final del Drawer
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              // Primero cerramos el Drawer
              Navigator.pop(context); 
              // Luego ejecutamos la función de cierre de sesión
              onLogout(); 
            },
          ),
        ],
      ),
    );
  }
}
