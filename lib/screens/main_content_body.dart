// lib/screens/main_content_body.dart
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:vouchers_manager/widgets/date_filter_button.dart';
import 'package:vouchers_manager/services/data_service.dart';
import 'package:vouchers_manager/widgets/receipt_item.dart';

class MainContentBody extends StatefulWidget {
  const MainContentBody({super.key});

  @override
  State<MainContentBody> createState() => _MainContentBodyState();
}

class _MainContentBodyState extends State<MainContentBody> {
  late Future<List<dynamic>> _receiptsDataFuture;
  List<dynamic> _allReceipts = [];
  List<dynamic> _filteredReceipts =
      []; // Nueva lista para los resultados filtrados
  DateTime? _selectedDate;

  int _itemsToShow = 5;

  @override
  void initState() {
    super.initState();
    _receiptsDataFuture = loadReceiptsData();
  }

  void _loadMore() {
    setState(() {
      _itemsToShow = _itemsToShow + 5;
    });
  }

  void _hideItems() {
    setState(() {
      _itemsToShow = 5;
    });
  }

  void _filterByDate(DateTime? date) {
    setState(() {
      _selectedDate = date;
      if (date == null) {
        _filteredReceipts = _allReceipts;
        _itemsToShow = 5;
      } else {
        _filteredReceipts = _allReceipts.where((receipt) {
          final receiptDate = DateTime.parse(receipt['fecha']).toLocal();
          return receiptDate.year == date.year &&
              receiptDate.month == date.month &&
              receiptDate.day == date.day;
        }).toList();
        _itemsToShow = _filteredReceipts.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery.of(context).size.width * 0.9;

    return FutureBuilder<List<dynamic>>(
      future: _receiptsDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          if (_allReceipts.isEmpty) {
            _allReceipts = snapshot.data!;
            _allReceipts.sort(
              (a, b) => DateTime.parse(
                b['fecha'],
              ).compareTo(DateTime.parse(a['fecha'])),
            );
            _filteredReceipts = _allReceipts;
          }

          final List<dynamic> displayedList = _filteredReceipts.sublist(
            0,
            min(_itemsToShow, _filteredReceipts.length),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60.0, bottom: 10.0), 
                child: Center(
                  child: SizedBox(
                    width: buttonWidth,
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
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: displayedList.length,
                  itemBuilder: (context, index) {
                    final receipt = displayedList[index];
                    return ReceiptItem(receipt: receipt);
                  },
                ),
              ),
              if (_itemsToShow < _filteredReceipts.length)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 10.0,
                    bottom: 60.0,
                  ),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _loadMore,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text('Ver más'),
                    ),
                  ),
                ),
              if (_itemsToShow >= _filteredReceipts.length &&
                  _filteredReceipts.length > 5 &&
                  _selectedDate == null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 8.0,
                    bottom: 60.0,
                  ),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _hideItems,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text('Ocultar'),
                    ),
                  ),
                ),
            ],
          );
        } else {
          return const Center(child: Text('No hay recibos disponibles.'));
        }
      },
    );
  }
}
