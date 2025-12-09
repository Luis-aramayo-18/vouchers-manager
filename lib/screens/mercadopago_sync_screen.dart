import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart' as camera;

import 'package:vouchers_manager/screens/mp_verification_screen.dart';
import 'package:vouchers_manager/providers/mp_sync_provider.dart';
import 'package:vouchers_manager/widgets/mp_qr_binding_widget.dart';

class MercadoPagoSyncScreen extends StatefulWidget {
  final List<camera.CameraDescription> cameras;
  final VoidCallback onLinkSuccess;

  const MercadoPagoSyncScreen({super.key, required this.cameras, required this.onLinkSuccess});

  @override
  State<MercadoPagoSyncScreen> createState() => _MercadoPagoSyncScreenState();
}

class _MercadoPagoSyncScreenState extends State<MercadoPagoSyncScreen> {
  late MpSyncProvider _mpSyncProvider;

  @override
  void initState() {
    super.initState();
    _mpSyncProvider = Provider.of<MpSyncProvider>(context, listen: false);

    if (_mpSyncProvider.isAccountLinked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onLinkSuccess();
        }
      });
      return;
    }

    _mpSyncProvider.addListener(_handleLinkStatusChange);
  }

  @override
  void dispose() {
    _mpSyncProvider.removeListener(_handleLinkStatusChange);
    super.dispose();
  }

  void _handleLinkStatusChange() {
    if (_mpSyncProvider.isAccountLinked && _mpSyncProvider.linkSuccessData != null && mounted) {
      widget.onLinkSuccess();
    } else if (_mpSyncProvider.linkError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mpSyncProvider.linkError!), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToVerificationScreen(BuildContext context, String snackBarMessage) {
    if (context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (c) => MpVerificationScreen(cameras: widget.cameras)));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(snackBarMessage), backgroundColor: Colors.blueGrey));
    }
  }

  void _launchInAppBinding() async {
    final provider = _mpSyncProvider;

    if (!mounted) return;

    if (provider.currentUserId == null) {
      await provider.initUserAndLinks();
    }

    await provider.launchAuthorizationUrl();
  }

  void _showQrModal() async {
    final provider = _mpSyncProvider;
    if (!mounted) return;

    if (provider.currentUserId == null) {
      await provider.initUserAndLinks();
    }

    if (!mounted) return;

    await provider.generateQrBindingToken();

    if (!mounted) return;

    if (provider.bindingToken == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return Builder(
          builder: (innerContext) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(innerContext).viewInsets.bottom),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(innerContext).size.height * 0.9,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<MpSyncProvider>(
                        builder: (context, provider, child) {
                          if (provider.bindingToken == null || provider.isProcessingLink) {
                            return const Padding(
                              padding: EdgeInsets.all(50.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final String bindingToken = provider.bindingToken!;

                          return MpQrBindingWidget(
                            bindingToken: bindingToken,
                            onNavigateToManualVerification: () {
                              Navigator.of(modalContext).pop();
                              _navigateToVerificationScreen(
                                context,
                                'Navegando a la pantalla de verificación de código.',
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MpSyncProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Mercado Pago'),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => provider.signOut(widget.onLinkSuccess),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '¡Has iniciado sesión!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                ElevatedButton.icon(
                  icon: Image.asset('assets/images/mercado-pago-logo.png', height: 34),
                  label: const Text('Vincular en un dispositivo tercero'),
                  onPressed: _showQrModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0085ca),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: Image.asset('assets/images/mercado-pago-logo.png', height: 34),
                  label: const Text('Vincular en este dispositivo'),
                  onPressed: _launchInAppBinding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE600),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                if (provider.isProcessingLink)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
