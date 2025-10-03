import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFilterButton extends StatelessWidget {
  const DateFilterButton({
    super.key,
    required this.selectedDate,
    required this.onPressed,
    this.onClear,
  });

  final DateTime? selectedDate;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onPressed,
                child: Container(
                  color: selectedDate != null
                      ? Colors.blue
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 15.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 18.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        selectedDate == null
                            ? 'Filtrar por Fecha'
                            : DateFormat('dd/MM/yyyy').format(selectedDate!),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (selectedDate != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
