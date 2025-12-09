import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/scheduler.dart';

import 'package:vouchers_manager/screens/login_view.dart';
import 'package:vouchers_manager/screens/mercadopago_sync_screen.dart';
import 'package:vouchers_manager/screens/deep_link_listener_screen.dart';
import 'package:vouchers_manager/screens/home_page.dart';

class AuthCheckScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AuthCheckScreen({super.key, required this.cameras});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  late final StreamSubscription<AuthState> _authStateSubscription;

  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _isMpLinked = false;

  @override
  void initState() {
    super.initState();
    debugPrint('*** AuthCheckScreen: initState - Verificando sesión inicial...');
    final initialSession = Supabase.instance.client.auth.currentSession;
    
    if (initialSession != null) {
      _isLoggedIn = true;
      debugPrint('*** AuthCheckScreen: Sesión inicial ACTIVA. User ID: ${initialSession.user.id}');
      _checkMpLinkStatus(initialSession.user.id);
    } else {
      _isLoading = false;
      debugPrint('*** AuthCheckScreen: Sesión inicial INACTIVA. Mostrando Login.');
    }

    final supabase = Supabase.instance.client;

    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      final AuthChangeEvent event = data.event;
      debugPrint('*** AuthCheckScreen: AuthStateChange Evento: $event');

      if (mounted) {
        final bool loggedIn = session != null;

        if (loggedIn != _isLoggedIn) {
          setState(() {
            _isLoggedIn = loggedIn;
            _isLoading = false;
          });

          if (loggedIn) {
            debugPrint('*** AuthCheckScreen: Cambio de estado -> LOGIN. User ID: ${session.user.id}');
            _checkMpLinkStatus(session.user.id);
          } else {
            debugPrint('*** AuthCheckScreen: Cambio de estado -> LOGOUT.');
            setState(() => _isMpLinked = false);
          }
        } else {
           debugPrint('*** AuthCheckScreen: Estado de sesión se mantiene: $_isLoggedIn');
        }
      }
    });
  }

  @override
  void dispose() {
    debugPrint('*** AuthCheckScreen: dispose - Cancelando suscripción de autenticación.');
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkMpLinkStatus(String userId) async {
    debugPrint('*** AuthCheckScreen: _checkMpLinkStatus - Iniciando chequeo para User ID: $userId');
    if (mounted) {
      setState(() => _isLoading = true);
    }

    bool isLinked = false;
    try {
      final response = await Supabase.instance.client
          .from('mp_accounts')
          .select('access_token')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['access_token'] != null) {
        isLinked = true;
        debugPrint('*** AuthCheckScreen: Mercadopago LINKED encontrado.');
      } else {
        debugPrint('*** AuthCheckScreen: Mercadopago NO LINKED (no entry or null access_token).');
      }
    } catch (e) {
      debugPrint('*** AuthCheckScreen ERROR: Error al verificar el estado de MP: $e');
      isLinked = false;
    }

    if (mounted) {
      setState(() {
        _isMpLinked = isLinked;
        _isLoading = false;
        debugPrint('*** AuthCheckScreen: Estado final: _isLoggedIn=$_isLoggedIn, _isMpLinked=$_isMpLinked, _isLoading=$_isLoading');
      });
    }
  }

  void _onMpLinkSuccess() {
    debugPrint('*** AuthCheckScreen: _onMpLinkSuccess - Callback ejecutado.');
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (mounted && currentUserId != null) {
      debugPrint('*** AuthCheckScreen: Re-chequeando estado de MP después de éxito.');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _checkMpLinkStatus(currentUserId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      debugPrint('*** AuthCheckScreen: build -> Mostrando CircularProgressIndicator.');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (!_isLoggedIn) {
      debugPrint('*** AuthCheckScreen: build -> Redirigiendo a LoginView.');
      return const LoginView();
    }

    if (!_isMpLinked) {
      debugPrint('*** AuthCheckScreen: build -> Redirigiendo a MercadoPagoSyncScreen.');
      return MercadoPagoSyncScreen(onLinkSuccess: _onMpLinkSuccess, cameras: widget.cameras);
    }

    debugPrint('*** AuthCheckScreen: build -> Redirigiendo a DeepLinkListenerScreen/HomePage.');
    return DeepLinkListenerScreen(
      cameras: widget.cameras,
      child: HomePage(cameras: widget.cameras),
    );
  }
}