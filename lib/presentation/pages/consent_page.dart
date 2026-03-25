import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/security/security_layer.dart';
import '../../core/theme/app_theme.dart';

/// Kullanıcı onayı (consent) alma ekranı.
/// Güvenlik gereksinimi: Onay olmadan hiçbir sistem işlemi başlatılamaz.
class ConsentPage extends StatelessWidget {
  final SecurityLayer security;
  final VoidCallback onConsented;

  const ConsentPage({
    super.key,
    required this.security,
    required this.onConsented,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              // Logo
              FadeInDown(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: AppShadows.glow(blurRadius: 32),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: const Text(
                  'Smart Mirror',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: const Text(
                  'TÜBİTAK 2209-A — AI Destekli Akıllı Ayna',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Onay Metni
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.privacy_tip_outlined,
                              color: AppTheme.primary, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Gizlilik & İzinler',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _ConsentItem(
                        icon: Icons.mic,
                        text:
                            'Ses komutları için mikrofon erişimi kullanılacaktır.',
                      ),
                      _ConsentItem(
                        icon: Icons.storage,
                        text:
                            'Görevler ve tercihler yalnızca cihazınızda saklanır.',
                      ),
                      _ConsentItem(
                        icon: Icons.wifi,
                        text:
                            'AI yanıtları için şifreli (TLS) ağ bağlantısı kullanılır.',
                      ),
                      _ConsentItem(
                        icon: Icons.notifications,
                        text:
                            'Hatırlatıcılar için yerel bildirim izni gereklidir.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await security.grantConsent();
                      onConsented();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Onaylıyorum ve Devam Ediyorum',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: const Text(
                  'Onaylamadan uygulama kullanılamaz.\n'
                  'Verileriniz üçüncü taraflarla paylaşılmaz.',
                  style: TextStyle(
                    color: AppTheme.textDisabled,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConsentItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
