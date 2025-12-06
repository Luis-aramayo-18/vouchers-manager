import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:uni_links/uni_links.dart';
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
  StreamSubscription? _sub;
  bool _initialCheckDone = false;
  late MpSyncProvider _mpSyncProvider;

  @override
  void initState() {
    super.initState();
    // LOG 1: Confirmación de que el listener es el primer widget en iniciar.
    debugPrint('➡️ DeepLinkListener: START - Inicializando el estado.'); 
    
    // Configuración del Provider
    _mpSyncProvider = Provider.of<MpSyncProvider>(context, listen: false);
    
    // Inicia el proceso de escucha de Deep Links.
    _initUniLinks();
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
        // LOG 2: La verificación inicial ha terminado, se procede a mostrar el 'child'.
        debugPrint('✅ DeepLinkListener: INITIAL CHECK DONE. Mostrando el widget hijo (AuthCheckScreen).');
      });
    }
  }

  Future<void> _initUniLinks() async {
    String? link;
    
    // --- Lógica para Deep Link Inicial (App Abierta por Enlace) ---
    debugPrint('⏳ DeepLinkListener: Verificando si la app fue abierta por un enlace inicial...');
    try {
      link = await getInitialLink();
    } on PlatformException catch (e) {
      debugPrint('❌ DeepLinkListener: Error al obtener Deep Link inicial: ${e.message}');
    } catch (e) {
      debugPrint('❌ DeepLinkListener: Error inesperado al obtener Deep Link: $e');
    }

    await _handleLink(link);

    // --- Lógica para Stream de Deep Links (App ya en Ejecución) ---
    debugPrint('⏳ DeepLinkListener: Configurando el Stream Listener para futuros enlaces.');
    _sub = uriLinkStream.listen((Uri? uri) async {
      if (!mounted) return;
      // LOG 3: Deep Link recibido mientras la app estaba abierta.
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
    final uri = Uri.parse(link);

    final status = uri.queryParameters['status']; 
    final mpUserId = uri.queryParameters['mp_user_id']; 

    // --- LÓGICA CLAVE: PROCESAR CALLBACK EXITOSO DE SUPABASE ---
    if (status == 'success' && mpUserId != null) {
      debugPrint('💰 Deep Link Handler: Callback de Supabase detectado. Status: SUCCESS. User ID: $mpUserId');
      
      await _mpSyncProvider.markAccountAsLinked(mpUserId);
      
      // NOTA: Se asume que la navegación a /main_app ocurre en el MpSyncProvider
      // o en AuthCheckScreen después de verificar el estado de vinculación actualizado.

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vinculación de Mercado Pago completada con éxito.')),
        );
      });
      return;
    }
    
    // --- LÓGICA EXISTENTE: MANEJO DE VOUCHERS ---
    final voucherId = uri.queryParameters['id'];

    if (voucherId != null) {
      debugPrint('🎫 Deep Link Handler: ID de Voucher extraído: $voucherId');
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // Si la verificación inicial ha terminado, muestra el child (AuthCheckScreen)
    if (_initialCheckDone) {
      return widget.child;
    }

    // Si no, muestra el indicador de carga
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1E88E5), // Color para el tema de la app
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