import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vouchers_manager/services/mercado_pago_service.dart';
import 'package:vouchers_manager/services/verification_database_service.dart';

class MpSyncProvider extends ChangeNotifier {
  final MercadoPagoService _mpService = MercadoPagoService(VerificationDatabaseService());

  String? _currentUserId;
  
  bool _isAccountLinked = false;
  bool _isProcessingLink = false; 
  String? _bindingToken;
  String? _authorizationUrl;
  
  // NUEVO ESTADO: Guarda los datos de éxito después del deep link.
  String? _linkSuccessData; 
  
  // ESTADO DE ERROR
  String? _linkError; 

  bool get isProcessingLink => _isProcessingLink;
  String? get bindingToken => _bindingToken;
  String? get authorizationUrl => _authorizationUrl;
  String? get currentUserId => _currentUserId;
  bool get isAccountLinked => _isAccountLinked;
  String? get linkError => _linkError;
  String? get linkSuccessData => _linkSuccessData; // Expone los datos de éxito

  // --- INICIALIZACIÓN ---

  Future<void> initUserAndLinks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      await _checkInitialLinkStatus();
    } else {
      debugPrint('Error: Usuario no autenticado al iniciar el Provider.');
    }
    _clearError(); 
  }

  Future<void> _checkInitialLinkStatus() async {
    if (_currentUserId == null) return;
    
    try {
      // Verifica el estado en la base de datos (Supabase)
      _isAccountLinked = await _mpService.isMpAccountLinked(_currentUserId!);
      notifyListeners();
      debugPrint('Estado de vinculación inicial: $_isAccountLinked');
    } catch (e) {
      debugPrint('Error al verificar estado de vinculación inicial: $e');
      _setError('No se pudo verificar el estado de la cuenta: ${e.toString()}');
    }
  }

  // --- FLUJO 1 & 2: Preparación y Lanzamiento ---

  Future<void> generateQrBindingToken() async {
    if (_currentUserId == null || _isProcessingLink) return;

    _setProcessingLink(true);
    _clearSyncState();
    _clearError(); 
    _clearSuccess();

    try {
      final token = await _mpService.getMpAuthorizationUrl(userId: _currentUserId!);
      _bindingToken = token;
    } catch (e) {
      debugPrint('Error al generar token de vinculación: $e');
      _setError('Error al generar el código QR: ${e.toString()}'); 
    } finally {
      _setProcessingLink(false);
      notifyListeners();
    }
  }

  Future<void> launchAuthorizationUrl() async {
    if (_currentUserId == null || _isProcessingLink) return;

    _setProcessingLink(true);
    _clearSyncState();
    _clearError(); 
    _clearSuccess(); // Limpiar éxito previo

    try {
      final authorizationUrl = await _mpService.getMpAuthorizationUrl2(userId: _currentUserId!);

      _authorizationUrl = authorizationUrl;

      final uri = Uri.parse(_authorizationUrl!);
      _bindingToken = uri.queryParameters['state']; 

      if (_bindingToken == null) {
        debugPrint('Advertencia: No se pudo extraer el token de estado (state) de la URL.');
      }

      await launchMpUrl(_authorizationUrl!);
    } catch (e) {
      debugPrint('Error al lanzar la URL de autorización MP: $e');
      _setError('No se pudo abrir la página de Mercado Pago. Intenta más tarde.'); 
    } finally {
      // Restablecemos el estado de "procesando" inmediatamente después de lanzar la URL.
      _setProcessingLink(false); 
    }
  }

  // --- MÉTODOS DE CALLBACK DESDE DeepLinkListenerScreen ---
  
  /// Llamado por DeepLinkListenerScreen cuando el deep link indica ÉXITO.
  Future<void> markAccountAsLinked(String mpUserId) async {
    debugPrint('Provider: Marcando cuenta MP como vinculada (MP User ID: $mpUserId)');
    
    // Establecer el estado de éxito explícitamente ANTES de notificar
    _linkSuccessData = mpUserId; 
    _isAccountLinked = true;

    _setProcessingLink(false); 
    _clearSyncState(); 
    _clearError(); 

    notifyListeners();
  }
  
  /// Llamado por DeepLinkListenerScreen cuando el deep link indica FALLO.
  Future<void> markAccountAsFailed(String errorMessage) async {
    debugPrint('Provider: Marcando cuenta MP como FALLIDA con error: $errorMessage');
    
    _isAccountLinked = false;
    _setProcessingLink(false); 
    _clearSyncState(); 
    _clearSuccess();
    _setError('Vinculación fallida: $errorMessage');

    notifyListeners();
  }
  
  // -------------------------------------------------------------


  // --- UTILITIES Y GESTIÓN DE ESTADO ---

  void _clearSyncState() {
    _bindingToken = null;
    _authorizationUrl = null;
  }

  // GESTIÓN DE ESTADO INTERNO
  void _setProcessingLink(bool value) {
    if (_isProcessingLink != value) {
      _isProcessingLink = value;
      notifyListeners();
    }
  }

  // GESTIÓN DE ERRORES
  void _setError(String message) {
    _linkError = message;
    notifyListeners();
  }

  void _clearError() {
    _linkError = null;
  }
  
  // GESTIÓN DE ÉXITO
  void _clearSuccess() {
    _linkSuccessData = null;
  }


  /// Función para lanzar el URL (usada por ambos flujos)
  Future<void> launchMpUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir el enlace: $url');
    }
  }

  /// Lógica de Sign Out 
  Future<void> signOut(VoidCallback onLinkSuccess) async {
    try {
      await Supabase.instance.client.auth.signOut();
      // Reiniciar estado interno al cerrar sesión
      _currentUserId = null;
      _isAccountLinked = false;
      _isProcessingLink = false;
      _clearError(); 
      _clearSuccess();
      onLinkSuccess(); // Navegar fuera
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }
}