import 'package:flutter/material.dart';

class MonthlyTotalButton extends StatelessWidget {
  const MonthlyTotalButton({
    super.key,
    required this.currentMonthYear,
    required this.onPressed,
    this.totalAmount,
  });

  // La cadena que representa el mes y año actual, ej: "Octubre 2025"
  final String currentMonthYear;

  // La función que se ejecuta al presionar el botón
  final VoidCallback onPressed;

  // Opcional: El monto total, si ya ha sido calculado
  final double? totalAmount;

  // Función para formatear el monto a moneda
  String _formatAmount(double amount) {
    // Usaremos un formato simple de moneda
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    // Esquema de color: Fondo Blanco, Elementos Azules
    const Color buttonColor = Colors.white;
    const Color textColor = Colors.blue;
    const Color shadowColor = Colors.black;

    // El texto a mostrar varía si hay un monto calculado o no
    final String displayText = totalAmount != null
        ? _formatAmount(totalAmount!)
        : currentMonthYear;

    // El texto de la esquina superior derecha siempre será el mes
    final String monthLabel = currentMonthYear.toUpperCase();

    return Container(
      // Estilo de Contenedor exterior (sombra y radio)
      decoration: BoxDecoration(
        color: buttonColor, // Fondo blanco
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.2), // Sombra más sutil en blanco
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ❌ SE ELIMINA EL ConstrainedBox
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: buttonColor,
          child: InkWell(
            onTap: onPressed,
            // 💡 AJUSTE DE PADDING: Menos padding vertical para reducir altura
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0), 
              // Usamos Stack para posicionar el mes en la esquina
              child: Stack(
                // Esto asegura que el Stack solo ocupe el tamaño que necesita.
                alignment: Alignment.center, 
                children: [
                  // 1. Contenido principal (centrado: Icono + Monto)
                  // No necesitamos Center si el Stack tiene alignment: Alignment.center
                  Column(
                    mainAxisSize: MainAxisSize.min, // Esto es clave para la altura
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icono y Monto
                      Row(
                        mainAxisSize: MainAxisSize.min, // Esto es clave para el ancho
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            color: textColor,
                            size: 24.0,
                          ),
                          const SizedBox(width: 8.0),
                          Flexible(
                            child: Text(
                              // Muestra el monto o el texto genérico
                              totalAmount != null ? displayText : 'TOTAL DEL MES', 
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 2. Mes/Etiqueta (posicionado en la esquina superior derecha)
                  Positioned(
                    top: 0, // Posición desde el borde superior del Padding
                    right: 0, // Posición desde el borde derecho del Padding
                    child: Text(
                      monthLabel, // Mes/Año actual
                      style: TextStyle(
                        color: textColor.withOpacity(0.7), 
                        fontSize: 10.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}