import 'package:flutter/material.dart';

enum TransferStatus {
  completed, // Completada
  pending, // Pendiente
  failed, // Fallida
}

class TransferCard extends StatelessWidget {
  final TransferStatus status;
  final double amount;
  final String clientName;
  final String date;
  final String time;
  // 🌟 NUEVA PROPIEDAD: Banco de Origen
  final String sourceBank;
  // 🌟 NUEVA PROPIEDAD: Función para guardar la transacción
  final VoidCallback onSave;

  const TransferCard({
    super.key,
    required this.status,
    required this.amount,
    required this.clientName,
    required this.date,
    required this.time,
    required this.sourceBank, // Requiere el banco
    required this.onSave, // Requiere la función de guardar
  });

  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return Colors.green.shade700;
      case TransferStatus.pending:
        return Colors.amber.shade700;
      case TransferStatus.failed:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
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
      default:
        return 'DESCONOCIDO';
    }
  }

  // Método para formatear el monto a moneda
  String _formatAmount(double amount) {
    return '\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // Reducimos el margen vertical para que se vea mejor junto a la etiqueta 'Banco de Origen'
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8), 
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección Superior: Monto y Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Monto
                Text(
                  _formatAmount(amount),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                // Estado (Badge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Separador sutil
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),

            // Sección Cliente y Banco (Información detallada)
            _buildDetailRow(
              context,
              label: 'Cliente',
              value: clientName,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            // 🌟 Mostrar el Banco de Origen
            _buildDetailRow(
              context,
              label: 'Banco de Origen',
              value: sourceBank,
              icon: Icons.account_balance,
            ),
            const SizedBox(height: 16),

            // Sección Inferior: Fecha y Hora
            Row(
              children: [
                // Fecha
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(width: 20),

                // Hora
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🌟 Botón de Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_outlined),
                label: const Text(
                  'Guardar Verificación',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor, // Usa el color de estado (verde para completada)
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget auxiliar para mejorar la presentación de los detalles
  Widget _buildDetailRow(BuildContext context, {required String label, required String value, required IconData icon}) {
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
}
