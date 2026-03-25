import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/user.dart';
import '../blocs/user/user_cubit.dart';
import 'dashboard_page.dart';

/// Uygulama ilk kez açıldığında ve hiç profil yoksa gösterilen ekran.
/// Kullanıcı buradan ilk profilini oluşturur, ardından Dashboard'a geçer.
class FirstSetupPage extends StatefulWidget {
  const FirstSetupPage({super.key});

  @override
  State<FirstSetupPage> createState() => _FirstSetupPageState();
}

class _FirstSetupPageState extends State<FirstSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();
  UserRole _role = UserRole.admin;
  int _step = 0; // 0: hoşgeldin, 1: form

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userCubit = context.read<UserCubit>();
    return BlocProvider.value(
      value: userCubit,
      child: BlocListener<UserCubit, UserState>(
        listener: (context, state) {
          if (state is UserAuthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: userCubit,
                  child: const DashboardPage(),
                ),
              ),
              (_) => false,
            );
          }
          if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _step == 0
                ? _WelcomeStep(
                    key: const ValueKey('welcome'),
                    onNext: () => setState(() => _step = 1),
                  )
                : _ProfileFormStep(
                    key: const ValueKey('form'),
                    formKey: _formKey,
                    nameController: _nameController,
                    pinController: _pinController,
                    pinConfirmController: _pinConfirmController,
                    role: _role,
                    onRoleChanged: (r) => setState(() => _role = r),
                    onBack: () => setState(() => _step = 0),
                    onSubmit: _createProfile,
                  ),
          ),        // AnimatedSwitcher
        ),          // SafeArea
        ),          // Scaffold
      ),            // BlocListener
    );              // BlocProvider.value
  }

  void _createProfile() {
    if (!_formKey.currentState!.validate()) return;
    final user = User(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      avatarPath: '',
      pin: _pinController.text,
      createdAt: DateTime.now(),
      role: _role,
    );
    context.read<UserCubit>().createUser(user);
  }
}

// ── Hoş Geldin Adımı ──────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: AppShadows.glow(blurRadius: 32),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Akıllı Ayna\'ya\nHoş Geldiniz',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Başlamak için bir profil oluşturun.\nSes asistanı sizi tanıyacak ve\ngörevlerinizi yönetmenize yardımcı olacak.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Profil Oluştur',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profil Form Adımı ─────────────────────────────────────────────────────

class _ProfileFormStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController pinController;
  final TextEditingController pinConfirmController;
  final UserRole role;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _ProfileFormStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.pinController,
    required this.pinConfirmController,
    required this.role,
    required this.onRoleChanged,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<_ProfileFormStep> createState() => _ProfileFormStepState();
}

class _ProfileFormStepState extends State<_ProfileFormStep> {
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Geri butonu
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textSecondary),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            const Text(
              'Profilinizi\nOluşturun',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu bilgiler cihazınızda saklanır.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 28),

            // İsim
            TextFormField(
              controller: widget.nameController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Adınız *',
                prefixIcon: Icon(Icons.person, color: AppTheme.primary),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'İsim zorunludur.' : null,
            ),
            const SizedBox(height: 16),

            // PIN
            TextFormField(
              controller: widget.pinController,
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              maxLength: 6,
              style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'PIN (4-6 hane) *',
                prefixIcon: const Icon(Icons.lock, color: AppTheme.primary),
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 4) ? 'En az 4 hane gerekli.' : null,
            ),
            const SizedBox(height: 16),

            // PIN Tekrar
            TextFormField(
              controller: widget.pinConfirmController,
              keyboardType: TextInputType.number,
              obscureText: _obscureConfirm,
              maxLength: 6,
              style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'PIN Tekrar *',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 4) return 'En az 4 hane gerekli.';
                if (v != widget.pinController.text) return 'PIN\'ler eşleşmiyor.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Rol
            DropdownButtonFormField<UserRole>(
              value: widget.role,
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon: Icon(Icons.admin_panel_settings, color: AppTheme.primary),
              ),
              items: UserRole.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.name.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (r) {
                if (r != null) widget.onRoleChanged(r);
              },
            ),
            const SizedBox(height: 32),

            // Oluştur butonu
            BlocBuilder<UserCubit, UserState>(
              builder: (context, state) {
                final isLoading = state is UserLoading;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : widget.onSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Başla',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
