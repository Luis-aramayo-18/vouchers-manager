// lib/widgets/receipt_item.dart
import 'package:flutter/material.dart';

class ReceiptItem extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const ReceiptItem({
    super.key,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime dateTime = DateTime.parse(receipt['fecha']);
    
    final String formattedDate = 
      "${dateTime.day.toString().padLeft(2, '0')}-"
      "${dateTime.month.toString().padLeft(2, '0')}-"
      "${dateTime.year}";

    final String status = receipt['estado_de_pago'];
    final Color statusColor = status == 'Pagado' ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            status == 'Pagado' ? Icons.check : Icons.warning_amber,
            color: Colors.white,
          ),
        ),
        // Fila 1: Nombre y estado (con Row)
        title: Row(
          children: [
            Text(
              receipt['cliente_name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(), 
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto: \$${receipt['monto']}'),
            Text('Fecha: $formattedDate'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}