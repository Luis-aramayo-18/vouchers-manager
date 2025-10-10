import 'package:flutter/material.dart';
import 'package:vouchers_manager/widgets/date_filter_button.dart';
import 'package:vouchers_manager/widgets/monthly_total_button.dart';
import 'package:vouchers_manager/widgets/month_picker_modal.dart';
import 'package:vouchers_manager/services/data_service.dart' as data_service;
import 'package:vouchers_manager/widgets/receipt_item.dart';

class MainContentBody extends StatefulWidget {
  const MainContentBody({super.key});

  @override
  State<MainContentBody> createState() => _MainContentBodyState();
}

class _MainContentBodyState extends State<MainContentBody> {
  // Lista que contendrá los recibos cargados (incrementalmente)
  List<dynamic> _receipts = [];

  // Filtro de fecha seleccionado por el usuario
  DateTime? _selectedDate;

  // 🌟 ESTADO PARA EL TOTAL MENSUAL
  double? _monthlyTotal;
  String _currentMonthYear = ''; // Ej: "Octubre 2025"
  DateTime _currentTotalDate = DateTime.now(); // La fecha usada para el cálculo

  // Variables de Paginación del lado del servidor
  final int _pageSize = 10;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true; // Indica si hay más items para cargar del servidor

  @override
  void initState() {
    super.initState();
    // Inicializar el mes y año actual
    _updateCurrentMonthYear(DateTime.now());
    // Cargamos la primera página al iniciar.
    _loadReceipts();
    // Cargamos el total del mes actual al iniciar (solo para inicializar el botón)
    _loadMonthlyTotal(DateTime.now(), initializeButton: true);
  }

  // -----------------------------------------------------------
  // LÓGICA DE CÁLCULO DE TOTALES
  // -----------------------------------------------------------

  // Actualiza el texto del botón al mes y año seleccionado
  void _updateCurrentMonthYear(DateTime date) {
    setState(() {
      // Usamos getDateFormat porque esta es para la fecha (ej: "Octubre 2025")
      final formatter = data_service.getDateFormat('MMMM yyyy');
      _currentMonthYear = formatter.format(date);
      _currentTotalDate = date; // Guardamos la fecha para el cálculo
    });
  }

  // Carga el total y la cantidad de comprobantes para un mes específico
  Future<void> _loadMonthlyTotal(DateTime date, {bool initializeButton = false}) async {
    try {
      // ⚠️ Llamada al servicio que devuelve un mapa con el monto y la cantidad.
      final Map<String, dynamic> result = await data_service.calculateMonthlyTotal(date);

      _updateCurrentMonthYear(date); // Actualiza el botón con el mes seleccionado

      setState(() {
        _monthlyTotal = result['total_amount'];
      });

      // SOLO mostramos el modal si NO estamos en la inicialización (solo cuando el usuario presiona OK)
      if (!initializeButton) {
        _showTotalModal(
          total: result['total_amount'],
          count: result['receipt_count'],
          monthYear: _currentMonthYear,
        );
      }
    } catch (e) {
      print('Error al cargar el total mensual: $e');
      setState(() {
        _monthlyTotal = 0.0;
      });
      if (!initializeButton) {
        // Muestra una alerta en caso de error de cálculo/conexión
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al obtener los totales del mes.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Lógica que se ejecuta al presionar el botón de total
  void _onMonthlyTotalPressed() async {
    // 1. Mostrar el selector de mes personalizado
    final SelectedMonth? selected = await showDialog<SelectedMonth>(
      context: context,
      builder: (context) => const MonthPickerModal(), // 🌟 Usando la clase renombrada
    );

    // 2. Si se seleccionó un mes (el usuario presionó OK)
    if (selected != null) {
      // Llamamos a cargar el total para la fecha seleccionada
      _loadMonthlyTotal(selected.date);
    }
  }

  // -----------------------------------------------------------
  // WIDGET MODAL DE RESULTADOS
  // -----------------------------------------------------------

  void _showTotalModal({required double total, required int count, required String monthYear}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // 🟢 LÍNEA CORREGIDA: Se usa getNumberFormat para formatear el 'double' (monto total)
        final String formattedTotal = data_service.getNumberFormat('###,##0.00').format(total);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Resumen de ${monthYear.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Divider(color: Colors.grey),
              _buildModalRow(
                icon: Icons.attach_money,
                label: 'Monto Total Recibido:',
                value: '\$ $formattedTotal',
                valueColor: Colors.green,
              ),
              const SizedBox(height: 15),
              _buildModalRow(
                icon: Icons.receipt_long,
                label: 'Cantidad de Comprobantes:',
                value: count.toString(),
                valueColor: Colors.orange,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CERRAR', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Widget auxiliar para las filas del modal
  Widget _buildModalRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: valueColor, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // LÓGICA DE CARGA Y PAGINACIÓN (Sin cambios)
  // -----------------------------------------------------------

  Future<void> _loadReceipts({bool reset = false}) async {
    if (_isLoading || (!_hasMore && !reset)) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _receipts.clear();
        _currentPage = 0;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    final int from = _currentPage * _pageSize;
    final int to = from + _pageSize - 1;

    try {
      final List<dynamic> newReceipts = await data_service.loadReceiptsData(
        from: from,
        to: to,
        dateFilter: _selectedDate,
      );

      setState(() {
        _receipts.addAll(newReceipts);
        _hasMore = newReceipts.length == _pageSize;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar recibos: $e');
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  void _loadMore() => _loadReceipts();

  void _filterByDate(DateTime? date) {
    if (_selectedDate == date) return;

    setState(() {
      _selectedDate = date;
    });
    _loadReceipts(reset: true);
  }

  // -----------------------------------------------------------
  // WIDGET BUILDER CORREGIDO (Los botones están en Column ahora)
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Calculamos el ancho completo (ancho de pantalla menos el padding horizontal de 16.0*2)
    final double fullButtonWidth = MediaQuery.of(context).size.width - 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. BOTONES SUPERIORES (TOTAL MENSUAL Y FILTRO DE FECHA)
        Padding(
          padding: const EdgeInsets.only(top: 60.0, bottom: 10.0, left: 16.0, right: 16.0),
          // ⚠️ CAMBIO CLAVE: Column para apilar los botones verticalmente
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 1. BOTÓN DE TOTAL MENSUAL (ARRIBA)
              SizedBox(
                width: fullButtonWidth, // Ancho completo
                child: MonthlyTotalButton(
                  currentMonthYear: _currentMonthYear,
                  totalAmount: _monthlyTotal, // Pasamos el total calculado
                  onPressed: _onMonthlyTotalPressed, // La acción al presionar
                ),
              ),
              
              const SizedBox(height: 10), // Espacio entre botones

              // 2. Botón de Filtro de Fecha (ABAJO)
              SizedBox(
                width: fullButtonWidth, // Ancho completo
                child: DateFilterButton(
                  selectedDate: _selectedDate,
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      _filterByDate(pickedDate);
                    }
                  },
                  onClear: () => _filterByDate(null),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Indicador de carga inicial
        if (_isLoading && _receipts.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator())),

        // 3. Lista de Recibos
        if (!_isLoading || _receipts.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _receipts.length,
              itemBuilder: (context, index) {
                final receipt = _receipts[index];
                return ReceiptItem(receipt: receipt);
              },
            ),
          ),

        // 4. Botón "Ver más" / Indicador de carga de más
        if (_hasMore || (_isLoading && _receipts.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0, bottom: 60.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loadMore,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                ),
                child: _isLoading && _receipts.isNotEmpty
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ver más'),
              ),
            ),
          ),
        // 5. Mensaje si no hay recibos
        if (!_isLoading && _receipts.isEmpty)
          const Expanded(
            child: Center(child: Text('No hay recibos disponibles con este criterio.')),
          ),
      ],
    );
  }
}