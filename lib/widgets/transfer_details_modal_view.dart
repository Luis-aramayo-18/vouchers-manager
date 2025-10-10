import 'package:flutter/material.dart';

// Definición local del Enum para no depender de transfer_card.dart
enum TransferStatus {
  completed, // Completada
  pending, // Pendiente
  failed, // Fallida
}

/// Widget dedicado a mostrar los detalles de una transferencia
/// en un modal de solo lectura, sin depender de TransferCard.
class TransferDetailsModalView extends StatelessWidget {
  final TransferStatus status;
  final double amount;
  final String clientName;
  final String date;
  final String time;
  final String sourceBank;

  const TransferDetailsModalView({
    super.key,
    required this.status,
    required this.amount,
    required this.clientName,
    required this.date,
    required this.time,
    required this.sourceBank,
  });

  // --- MÉTODOS AUXILIARES COPIADOS PARA INDEPENDENCIA ---

  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return Colors.green.shade700;
      case TransferStatus.pending:
        return Colors.amber.shade700;
      case TransferStatus.failed:
        return Colors.red.shade700;
    }
  }

  String _getStatusText(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return 'COMPLETADA';
      case TransferStatus.pending:
        return 'PENDIENTE';
      case TransferStatus.failed:
        return 'FALLIDA';
    }
  }

  String _formatAmount(double amount) {
    return '\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- CONSTRUCCIÓN DE LA INTERFAZ SIN TRANSFERCARD ---

  // En lib/widgets/transfer_details_modal_view.dart

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    const Color savedColor = Colors.blue;

    return Container(
      // 1. Contenedor principal del modal con bordes redondeados y fondo blanco
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
        // 2. Añadimos la elevación (sombra) aquí para simular la Card
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // 3. Utilizamos SingleChildScrollView directamente dentro del Container
      child: SingleChildScrollView(
        // 4. Mantenemos el padding general del modal.
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        // 5. El contenido de la antigua Card (el Padding y Column) va directamente aquí
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Padding que estaba dentro de la Card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contenido restante...
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Monto
                  Expanded(
                    child: Text(
                      _formatAmount(amount),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  // Badges (Guardado + Estado)
                  IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🌟 Badge "GUARDADO"
                        _buildBadge('GUARDADO', savedColor),
                        const SizedBox(height: 8),
                        // Badge de Estado
                        _buildBadge(statusText, statusColor),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 12),

              // Detalles
              _buildDetailRow(
                context,
                label: 'Cliente',
                value: clientName,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                label: 'Banco de Origen',
                value: sourceBank,
                icon: Icons.account_balance,
              ),
              const SizedBox(height: 16),

              // Fecha y Hora
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(date, style: TextStyle(color: Colors.grey.shade700)),

                  const SizedBox(width: 20),

                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: TextStyle(color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
