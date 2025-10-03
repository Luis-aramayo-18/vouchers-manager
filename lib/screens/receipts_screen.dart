
import 'package:flutter/material.dart';
import 'package:vouchers_manager/services/data_service.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  late Future<List<dynamic>> _receiptsDataFuture;

  @override
  void initState() {
    super.initState();
    _receiptsDataFuture = loadReceiptsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Recibos'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _receiptsDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } 
          else if (snapshot.hasData) {
            final receipts = snapshot.data!;
            return ListView.builder(
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return ListTile(
                  title: Text(receipt['cliente_name']),
                  subtitle: Text('Monto: \$${receipt['monto']} - Estado: ${receipt['estado_de_pago']}'),
                );
              },
            );
          } 
          else {
            return const Center(child: Text('No hay recibos disponibles.'));
          }
        },
      ),
    );
  }
}