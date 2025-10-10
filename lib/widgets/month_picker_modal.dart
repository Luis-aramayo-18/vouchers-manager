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

class MonthPickerModal extends StatefulWidget { // Renombrado a Modal
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
  /// Esto asegura que los meses posteriores al actual están bloqueados.
  bool _isFutureMonth(int month) {
    // La fecha seleccionada usa el año actual (_now.year)
    final selectedDate = DateTime(_now.year, month);
    // Compara solo Año y Mes (ignora el día y la hora)
    return selectedDate.isAfter(DateTime(_now.year, _now.month));
  }
  
  // Nombres de los meses en español usando el locale 'es'
  final List<String> _monthNames = List.generate(12, (index) {
    // Usamos 2023 o cualquier año para obtener el nombre correcto del mes
    return DateFormat.MMMM('es').format(DateTime(2023, index + 1)); 
  });


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seleccionar Mes', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          // Muestra el año de referencia para aclarar que es el año actual
          Text('Año ${_now.year}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
      contentPadding: const EdgeInsets.all(16.0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Se elimina el Selector de Año, solo se muestra la cuadrícula de meses.

            // Grid de Meses (3x4)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(12, (index) {
                final monthIndex = index + 1; // Meses de 1 a 12
                final isSelected = monthIndex == _selectedMonth;
                // Usamos la función simplificada, asumiendo el año actual
                final isFuture = _isFutureMonth(monthIndex); 
                
                return InkWell(
                  onTap: isFuture
                      ? null // Deshabilitado si es futuro
                      : () {
                          setState(() {
                            _selectedMonth = monthIndex;
                          });
                        },
                  child: Container(
                    width: 70, 
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withOpacity(0.8) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent, 
                        width: 2
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[index], // Nombre del mes
                      style: TextStyle(
                        color: isFuture
                            ? Colors.grey[400]
                            : isSelected ? Colors.white : Colors.blueGrey[700],
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
            // Esto es crucial para que la función de cálculo del total sepa qué mes y año buscar.
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
