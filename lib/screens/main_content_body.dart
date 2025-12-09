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

class _MainContentBodyState extends State<MainContentBody> with RouteAware {
  final List<dynamic> _receipts = [];

  DateTime? _selectedDate;

  double? _monthlyTotal;
  String _currentMonthYear = '';

  final int _pageSize = 10;

  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  // Bandera para asegurar que la carga inicial solo ocurra una vez en initState
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _updateCurrentMonthYear(DateTime.now());
    _loadReceipts();
    _loadMonthlyTotal(DateTime.now(), initializeButton: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Si no es la carga inicial, forzamos la recarga al volver a la pantalla
    if (!_isInitialLoad) {
      final Route? route = ModalRoute.of(context);
      
      if (route?.isCurrent == true) {
        // Recargamos la lista y el total cuando la pantalla se vuelve activa
        _loadReceipts(reset: true);
        _loadMonthlyTotal(DateTime.now(), initializeButton: true);
      }
    }
    
    _isInitialLoad = false;
  }

  @override
  void dispose() {
    // Si usaras RouteObserver (que es la forma más robusta)
    // RouteObserver.of(context).unsubscribe(this);
    super.dispose();
  }

  // -----------------------------------------------------------
  // LÓGICA DE CÁLCULO DE TOTALES 
  // -----------------------------------------------------------
  void _updateCurrentMonthYear(DateTime date) {
    setState(() {
      final formatter = data_service.getDateFormat('MMMM yyyy');
      _currentMonthYear = formatter.format(date);
    });
  }

  Future<void> _loadMonthlyTotal(DateTime date, {bool initializeButton = false}) async {
    try {
      final Map<String, dynamic> result = await data_service.calculateMonthlyTotal(date);

      if (!mounted) return;

      _updateCurrentMonthYear(date);

      setState(() {
        _monthlyTotal = result['total_amount'];
      });

      if (!initializeButton) {
        _showTotalModal(
          total: result['total_amount'],
          count: result['receipt_count'],
          monthYear: _currentMonthYear,
        );
      }
    } catch (e) {
      debugPrint('Error al cargar el total mensual: $e');
      
      if (!mounted) return; 

      setState(() {
        _monthlyTotal = 0.0;
      });

      if (!initializeButton) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al obtener los totales del mes.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMonthlyTotalPressed() async {
    final SelectedMonth? selected = await showDialog<SelectedMonth>(
      context: context,
      builder: (context) => const MonthPickerModal(),
    );

    if (selected != null) {
      _loadMonthlyTotal(selected.date);
    }
  }

  // -----------------------------------------------------------
  // WIDGET MODAL DE RESULTADOS (Sin cambios)
  // -----------------------------------------------------------

  void _showTotalModal({required double total, required int count, required String monthYear}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
  // FUNCIÓN DE DATEPICKER CON TEMA (Sin cambios)
  // -----------------------------------------------------------

  Future<DateTime?> _showThemeDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    const Color primaryColor = Colors.blue; 

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,  
              onPrimary: Colors.white, 
              surface: Colors.white,    
              onSurface: Colors.black87, 
            ),
            // --- Estilos de Botones de acción (OK, Cancelar) ---
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), 
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }


  // -----------------------------------------------------------
  // LÓGICA DE CARGA Y PAGINACIÓN (Sin cambios funcionales)
  // -----------------------------------------------------------

  // 🚀 Implementamos la lógica de refresco:
  Future<void> _handleRefresh() async {
    // 1. Recarga los recibos (reseteando la paginación)
    await _loadReceipts(reset: true);
    
    // 2. Recarga el total mensual (para la fecha actual)
    await _loadMonthlyTotal(DateTime.now(), initializeButton: true);

    // El Future se completa cuando ambas cargas terminan.
  }

  Future<void> _loadReceipts({bool reset = false}) async {
    // Si ya estamos cargando y no estamos reseteando, salimos.
    if (_isLoading && !reset) return; 
    // Si no hay más datos y no estamos reseteando, salimos.
    if (!_hasMore && !reset) return;

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

    // Se calcula la paginación según el estado actual
    final int from = _currentPage * _pageSize;
    final int to = from + _pageSize - 1;

    try {
      final List<dynamic> newReceipts = await data_service.loadReceiptsData(
        from: from,
        to: to,
        dateFilter: _selectedDate,
      );

      // Si el widget ya no está montado, salimos.
      if (!mounted) return;

      setState(() {
        _receipts.addAll(newReceipts);
        _hasMore = newReceipts.length == _pageSize;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar recibos: $e');
      if (!mounted) return;
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
  // WIDGET BUILDER
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final double fullButtonWidth = MediaQuery.of(context).size.width - 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 30.0, bottom: 10.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 1. BOTÓN DE TOTAL MENSUAL (ARRIBA)
              SizedBox(
                width: fullButtonWidth,
                child: MonthlyTotalButton(
                  currentMonthYear: _currentMonthYear,
                  totalAmount: _monthlyTotal,
                  onPressed: _onMonthlyTotalPressed,
                ),
              ),
              
              const SizedBox(height: 10),

              // 2. Botón de Filtro de Fecha (ABAJO)
              SizedBox(
                width: fullButtonWidth, // Ancho completo
                child: DateFilterButton(
                  selectedDate: _selectedDate,
                  onPressed: () async {
                    final DateTime? pickedDate = await _showThemeDatePicker( 
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

        // 3. Lista de Recibos envuelta en RefreshIndicator
        if (!_isLoading || _receipts.isNotEmpty)
          Expanded(
            // 💡 APLICACIÓN DEL PULL-TO-REFRESH
            child: RefreshIndicator(
              onRefresh: _handleRefresh, // Llama a la nueva función de recarga
              color: Colors.blue, // Color del indicador de progreso
              child: ListView.builder(
                // Establecemos physics para que el indicador de refresco funcione siempre, 
                // incluso si la lista no es lo suficientemente larga para ser scrollable.
                physics: const AlwaysScrollableScrollPhysics(), 
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _receipts.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _receipts.length) {
                    if (_isLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                    } else if (_hasMore) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0, bottom: 60.0),
                          child: Center(
                              child: ElevatedButton(
                                  onPressed: _loadMore,
                                  style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                  ),
                                  child: const Text('Ver más'),
                              ),
                          ),
                        );
                    }
                    return const SizedBox.shrink();
                  }
                  
                  final receipt = _receipts[index];
                  return ReceiptItem(receipt: receipt);
                },
              ),
            ),
          ),

        if (!_isLoading && _receipts.isEmpty)
          const Expanded(
            child: Center(child: Text('No hay recibos disponibles con este criterio.')),
          ),
      ],
    );
  }
}