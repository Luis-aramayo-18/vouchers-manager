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
  final String sourceBank;
  final VoidCallback? onSave;
  final bool isRegistered;

  const TransferCard({
    super.key,
    required this.status,
    required this.amount,
    required this.clientName,
    required this.date,
    required this.time,
    required this.sourceBank,
    this.onSave,
    this.isRegistered = false,
  });

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
    // Usamos coma como separador decimal para contexto local
    return '\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // Función auxiliar para el Badge
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center, 
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    const Color savedColor = Colors.blue;

    // 🌟 RE-INCORPORAMOS Card con elevación
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                
                // Badges de estado y guardado
                IntrinsicWidth( 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, 
                    children: [
                      // El badge "GUARDADO" SÍ se muestra si está registrado
                      if (isRegistered)
                        _buildBadge('GUARDADO', savedColor),
                      
                      if (isRegistered)
                        const SizedBox(height: 8),
                        
                      _buildBadge(statusText, statusColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),

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

            Row(
              children: [
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

                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🌟 CAMBIO CLAVE: Botón Guardar solo si NO está registrado
            if (!isRegistered)
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
                    backgroundColor: onSave == null ? Colors.grey.shade400 : statusColor,
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
}
