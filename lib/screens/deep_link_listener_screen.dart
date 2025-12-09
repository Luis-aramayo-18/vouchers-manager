import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
// ¡IMPORTANTE! Reemplazamos uni_links por app_links
import 'package:app_links/app_links.dart'; 
import 'package:flutter/services.dart';
import 'package:camera/camera.dart' as camera;

import 'dart:async';
import 'package:vouchers_manager/providers/mp_sync_provider.dart';

class DeepLinkListenerScreen extends StatefulWidget {
  final List<camera.CameraDescription> cameras;
  final Widget child;

  const DeepLinkListenerScreen({
    super.key, 
    required this.cameras, 
    required this.child,
  });

  @override
  State<DeepLinkListenerScreen> createState() => _DeepLinkListenerScreenState();
}

class _DeepLinkListenerScreenState extends State<DeepLinkListenerScreen> {
  // Instancia del nuevo paquete AppLinks
  final _appLinks = AppLinks(); 
  StreamSubscription? _sub;
  bool _initialCheckDone = false;
  late MpSyncProvider _mpSyncProvider;

  @override
  void initState() {
    super.initState();
    debugPrint('➡️ DeepLinkListener: START - Inicializando el estado.'); 
    
    // El Provider.of debe hacerse en initState con listen: false
    _mpSyncProvider = Provider.of<MpSyncProvider>(context, listen: false);
    
    _initDeepLinks(); // Renombramos el método para reflejar el nuevo paquete
  }

  @override
  void dispose() {
    debugPrint('⬅️ DeepLinkListener: DISPOSE - Cancelando la suscripción al stream.');
    _sub?.cancel();
    super.dispose();
  }

  void _finishInitialCheck() {
    if (mounted) {
      setState(() {
        _initialCheckDone = true;
        debugPrint('✅ DeepLinkListener: INITIAL CHECK DONE. Mostrando el widget hijo (AuthCheckScreen).');
      });
    }
  }

  // Actualizamos el método para usar la API de app_links
  Future<void> _initDeepLinks() async {
    Uri? uri;
    
    debugPrint('⏳ DeepLinkListener: Verificando si la app fue abierta por un enlace inicial...');
    try {
      // 1. Uso de getInitialLink() de app_links (devuelve un Uri)
      uri = await _appLinks.getInitialLink();
    } on PlatformException catch (e) {
      debugPrint('❌ DeepLinkListener: Error al obtener Deep Link inicial: ${e.message}');
    } catch (e) {
      debugPrint('❌ DeepLinkListener: Error inesperado al obtener Deep Link: $e');
    }

    // Pasamos el URI directamente al manejador
    await _handleLink(uri?.toString());

    debugPrint('⏳ DeepLinkListener: Configurando el Stream Listener para futuros enlaces.');
    // 2. Uso de uriLinkStream de app_links (devuelve un Stream<Uri>)
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) async {
      if (!mounted) return;
      debugPrint('🔔 DeepLinkListener: Deep Link recibido desde el Stream: ${uri.toString()}');
      await _handleLink(uri?.toString());
    }, onError: (err) {
      if (mounted) {
        debugPrint('❌ DeepLinkListener: Error en stream de Deep Link: $err');
      }
    });

    _finishInitialCheck();
  }

  Future<void> _handleLink(String? link) async {
    if (link == null) {
      debugPrint('Deep Link Handler: No se encontró Deep Link.');
      return;
    }

    debugPrint('Deep Link Handler: Procesando enlace: $link');
    // Si el link no viene como Uri, lo parseamos
    final uri = Uri.parse(link);

    final status = uri.queryParameters['status']; 
    final mpUserId = uri.queryParameters['mp_user_id']; 

    if (status == 'success' && mpUserId != null) {
      debugPrint('💰 Deep Link Handler: Callback de Supabase detectado. Status: SUCCESS. User ID: $mpUserId');
      
      await _mpSyncProvider.markAccountAsLinked(mpUserId);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // En un ambiente real, considerar usar un modal en lugar de SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vinculación de Mercado Pago completada con éxito.')),
        );
      });
      return;
    }
    
    final voucherId = uri.queryParameters['id'];

    if (voucherId != null) {
      debugPrint('🎫 Deep Link Handler: ID de Voucher extraído: $voucherId');
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // En un ambiente real, considerar usar un modal en lugar de SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voucher ID recibido: $voucherId.')),
        );
      });
      return;
    }
    
    debugPrint('Deep Link Handler: Enlace procesado, no contenía parámetros de autorización ni ID de voucher válido.');
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCheckDone) {
      return widget.child;
    }

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1E88E5),
            ),
            SizedBox(height: 16),
            Text(
              'Verificando Deep Link...',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}