import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/injection_container.dart';
import 'core/security/security_layer.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/user/user_cubit.dart';
import 'presentation/pages/consent_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/first_setup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Durum çubuğunu şeffaf yap (tam ekran ayna estetiği)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
    ),
  );

  // Portre mod kilidi
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Türkçe tarih formatı başlatma
  await initializeDateFormatting('tr_TR');

  // Bağımlılık enjeksiyon konteyneri
  await initDependencies();

  runApp(const SmartMirrorApp());
}

class SmartMirrorApp extends StatelessWidget {
  const SmartMirrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Mirror',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: BlocProvider(
        create: (_) => sl<UserCubit>()..loadUsers(),
        child: const _AppRouter(),
      ),
    );
  }
}

/// Onay durumuna ve kullanıcı oturumuna göre yönlendirme.
class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool? _consentGranted;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final granted = await sl<SecurityLayer>().isConsentGranted();
    if (mounted) {
      setState(() => _consentGranted = granted);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Onay kontrolü yapılıyor
    if (_consentGranted == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    // Onay alınmamış → Consent ekranı
    if (!_consentGranted!) {
      return ConsentPage(
        security: sl<SecurityLayer>(),
        onConsented: () => setState(() => _consentGranted = true),
      );
    }

    // Onay var → Dashboard
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserInitial || state is UserLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        if (state is UserAuthenticated) {
          return const DashboardPage();
        }
        if (state is UsersLoaded) {
          // Hiç profil yok → İlk kurulum
          if (state.users.isEmpty) {
            return const FirstSetupPage();
          }
          return const DashboardPage();
        }
        return const DashboardPage();
      },
    );
  }
}
