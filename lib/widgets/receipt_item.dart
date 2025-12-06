import 'package:flutter/material.dart';
import 'package:vouchers_manager/widgets/transfer_details_modal_view.dart';

class ReceiptItem extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const ReceiptItem({super.key, required this.receipt});

  // Función para determinar el TransferStatus
  TransferStatus _mapStatus(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'approved') {
      return TransferStatus.completed;
    } else if (lowerStatus == 'pending') {
      return TransferStatus.pending;
    } else {
      return TransferStatus.failed;
    }
  }

  // Función para obtener el color basado en el TransferStatus (para List Item)
  Color _getItemStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return Colors.green.shade700;
      case TransferStatus.pending:
        return Colors.amber.shade700;
      case TransferStatus.failed:
        return Colors.red.shade700;
    }
  }

  // Función para obtener el texto del estado (para List Item)
  String _getItemStatusText(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return 'COMPLETADA';
      case TransferStatus.pending:
        return 'PENDIENTE';
      case TransferStatus.failed:
        return 'FALLIDA';
    }
  }

  void _showDetailsModal(BuildContext context) {
    final String dateString = receipt['date_approved_local'] as String? ?? '';
    final DateTime dateTime = (dateString.isNotEmpty)
        ? DateTime.parse(dateString)
        : DateTime.now();

    final TransferStatus transferStatus = _mapStatus(
        receipt['full_data']['status'] as String? ?? 'Desconocido');
    final double amount = (receipt['amount'] as num?)?.toDouble() ?? 0.00;
    final String clientName = receipt['sender_name'] as String? ?? 'Cliente Desconocido';
    final String sourceBank = receipt['full_data']['source_bank'] as String? ?? 'Banco Desconocido';
    
    final String dateFormatted = "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
    final String timeFormatted = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    // -------------------------------------

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: TransferDetailsModalView(
              status: transferStatus,
              amount: amount,
              clientName: clientName,
              date: dateFormatted,
              time: timeFormatted,
              sourceBank: sourceBank,
            ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Lógica de extracción de datos (para List Item) ---
    final String dateString = receipt['date_approved_local'] as String? ?? '';
    final DateTime dateTime = (dateString.isNotEmpty)
        ? DateTime.parse(dateString).toLocal()
        : DateTime.now();
    final String formattedDate =
        "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";

    final TransferStatus transferStatus = _mapStatus(
        receipt['full_data']['status'] as String? ?? 'Desconocido');
    final Color statusColor = _getItemStatusColor(transferStatus);
    final String displayStatus = _getItemStatusText(transferStatus);
    final IconData statusIcon = transferStatus == TransferStatus.completed 
        ? Icons.check 
        : Icons.warning_amber;


    final double amount = (receipt['amount'] as num?)?.toDouble() ?? 0.00;
    final String? clientName = receipt['sender_name'] as String?;
    final String clientCuil =
        receipt['sender_cuil'] as String? ?? 'CUIL Desconocido';
    final String clientDisplayTitle =
        (clientName != null && clientName.isNotEmpty && clientName != "Desconocido") ? clientName : clientCuil;


    return Card(
      elevation: 4.0, 
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            statusIcon,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                clientDisplayTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayStatus,
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
            Text(
              'Monto: \$${amount.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              'Fecha: $formattedDate',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _showDetailsModal(context);
        },
      ),
    );
  }
}