import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Definición de la estructura de datos que se retorna al seleccionar un mes.
class SelectedMonth {
  final int month;
  final int year;
  final DateTime date;

  // La fecha se construye usando el año proporcionado (que será el año actual)
  SelectedMonth(this.month, this.year) : date = DateTime(year, month);
}

class MonthPickerModal extends StatefulWidget {
  // Renombrado a Modal
  const MonthPickerModal({super.key});

  @override
  State<MonthPickerModal> createState() => _MonthPickerModalState();
}

class _MonthPickerModalState extends State<MonthPickerModal> {
  // Estado inicial: Solo Mes actual
  late int _selectedMonth;

  // El año es implícitamente el año actual (para el filtro y para el resultado)
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Inicializamos con el mes actual
    _selectedMonth = _now.month;
  }

  /// Define si un mes está en el futuro (siempre asumiendo el año actual).
  bool _isFutureMonth(int month) {
    // La fecha seleccionada usa el año actual (_now.year)
    final selectedDate = DateTime(_now.year, month);
    // Compara solo Año y Mes (ignora el día y la hora)
    return selectedDate.isAfter(DateTime(_now.year, _now.month));
  }

  // Nombres de los meses en español usando el locale 'es'
  final List<String> _monthNames = List.generate(12, (index) {
    // Asegúrate de tener configurado el locale 'es' en tu aplicación
    return DateFormat.MMMM('es').format(DateTime(2023, index + 1));
  });

  @override
  Widget build(BuildContext context) {
    // 💡 AJUSTE CLAVE: Cálculo del ancho estimado para el botón.
    
    // 1. Estimamos el ancho máximo que tomará el AlertDialog (ej: 75% del ancho de la pantalla)
    final double dialogWidth = MediaQuery.of(context).size.width * 0.75; 
    
    // 2. Restamos el padding horizontal del contenido (16.0 * 2 = 32.0)
    const double contentPadding = 16.0 * 2; 
    
    // 3. Restamos el espacio horizontal entre los 3 botones (spacing: 8.0 * 2 = 16.0)
    const double spacingWidth = 8.0 * 2; 

    // Ancho utilizable para los 3 botones
    final double availableWidth = dialogWidth - contentPadding - spacingWidth;

    // Ancho calculado para un solo botón
    final double buttonWidth = availableWidth / 3;

    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Año ${_now.year}',
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.all(16.0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grid de Meses (3x4)
            Wrap(
              spacing: 8.0, // Espacio horizontal
              runSpacing: 8.0, // Espacio vertical
              children: List.generate(12, (index) {
                final monthIndex = index + 1;
                final isSelected = monthIndex == _selectedMonth;
                final isFuture = _isFutureMonth(monthIndex);

                return InkWell(
                  onTap: isFuture
                      ? null
                      : () {
                          setState(() {
                            _selectedMonth = monthIndex;
                          });
                        },
                  child: Container(
                    // ⚠️ Utilizamos el ancho calculado para forzar 3 columnas.
                    width: buttonWidth, 
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.8) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[index], // Nombre del mes
                      style: TextStyle(
                        color: isFuture
                            ? Colors.grey[400]
                            : isSelected
                                ? Colors.white
                                : Colors.blueGrey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cierra el diálogo sin seleccionar
          child: const Text('CANCELAR', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () {
            // Retorna el mes seleccionado, usando el año actual (_now.year)
            Navigator.of(context).pop(SelectedMonth(_selectedMonth, _now.year));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}