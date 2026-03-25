import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/user.dart';
import '../blocs/user/user_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (state is UsersLoaded) {
            return _ProfileList(
              users: state.users,
              activeUser: state.activeUser,
            );
          }

          if (state is UserAuthenticated) {
            return _ActiveUserProfile(user: state.user);
          }

          if (state is UserError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppTheme.error),
              ),
            );
          }

          // İlk yükleme
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserCubit>().loadUsers();
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Profil Listesi (Çoklu Kullanıcı Seçimi) ───────────────────────────────

class _ProfileList extends StatelessWidget {
  final List<User> users;
  final User? activeUser;

  const _ProfileList({required this.users, this.activeUser});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profiller',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: AppTheme.primary),
                  onPressed: () => _showCreateUserSheet(context),
                  tooltip: 'Yeni profil ekle',
                ),
              ],
            ),
          ),
        ),
        if (users.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline,
                      size: 64, color: AppTheme.textDisabled),
                  SizedBox(height: 16),
                  Text(
                    'Henüz profil oluşturulmadı.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _UserCard(
                  user: users[i],
                  isActive: activeUser?.id == users[i].id,
                  onSelect: () =>
                      _showPinSheet(context, users[i]),
                  onDelete: () =>
                      context.read<UserCubit>().deleteUser(users[i].id),
                ),
                childCount: users.length,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showPinSheet(BuildContext context, User user) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<UserCubit>(),
        child: _PinSheet(user: user),
      ),
    );
  }

  Future<void> _showCreateUserSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<UserCubit>(),
        child: const _CreateUserSheet(),
      ),
    );
  }
}

// ── Kullanıcı Kartı ────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final User user;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isActive,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.primary : AppTheme.dividerColor,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _UserAvatar(name: user.name, isActive: isActive),
        title: Text(
          user.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${user.role.name} · ${user.preferences.language}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.login, color: AppTheme.primary),
                onPressed: onSelect,
                tooltip: 'Profili seç',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              onPressed: onDelete,
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final bool isActive;

  const _UserAvatar({required this.name, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive ? AppTheme.primaryGradient : null,
        color: isActive ? null : AppTheme.surfaceVariant,
        boxShadow: isActive ? AppShadows.glow() : null,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: isActive ? Colors.white : AppTheme.textSecondary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Aktif Kullanıcı Profili ────────────────────────────────────────────────

class _ActiveUserProfile extends StatelessWidget {
  final User user;
  const _ActiveUserProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: AppShadows.glow(blurRadius: 24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.role.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _SettingsTile(
                  icon: Icons.language,
                  title: 'Dil',
                  value: user.preferences.language,
                ),
                _SettingsTile(
                  icon: Icons.mic,
                  title: 'Ses Asistan',
                  value: user.preferences.voiceEnabled
                      ? 'Açık'
                      : 'Kapalı',
                  valueColor: user.preferences.voiceEnabled
                      ? AppTheme.success
                      : AppTheme.error,
                ),
                _SettingsTile(
                  icon: Icons.notifications,
                  title: 'Bildirimler',
                  value: user.preferences.notificationsEnabled
                      ? 'Açık'
                      : 'Kapalı',
                  valueColor: user.preferences.notificationsEnabled
                      ? AppTheme.success
                      : AppTheme.error,
                ),
                _SettingsTile(
                  icon: Icons.speed,
                  title: 'TTS Hızı',
                  value: '${user.preferences.ttsSpeed}x',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.read<UserCubit>().logout(),
                    icon: const Icon(Icons.logout, color: AppTheme.error),
                    label: const Text(
                      'Çıkış Yap',
                      style: TextStyle(color: AppTheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── PIN Giriş Sheet ────────────────────────────────────────────────────────

class _PinSheet extends StatefulWidget {
  final User user;
  const _PinSheet({required this.user});

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  final _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserAuthenticated) {
          Navigator.pop(context);
        }
        if (state is UserPinError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Hatalı PIN. ${state.attemptsLeft} deneme hakkınız kaldı.',
              ),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.user.name} için PIN girin',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '••••',
                counterText: '',
              ),
              onSubmitted: (_) => _verify(context),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _verify(context),
                child: const Text('Giriş Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verify(BuildContext context) {
    context.read<UserCubit>().selectUser(
          widget.user.id,
          _pinController.text,
        );
  }
}

// ── Yeni Kullanıcı Oluştur Sheet ───────────────────────────────────────────

class _CreateUserSheet extends StatefulWidget {
  const _CreateUserSheet();

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  UserRole _role = UserRole.member;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yeni Profil',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'İsim *',
                prefixIcon: Icon(Icons.person, color: AppTheme.primary),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'İsim zorunludur.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'PIN (4-6 hane) *',
                prefixIcon: Icon(Icons.lock, color: AppTheme.primary),
              ),
              validator: (v) =>
                  (v == null || v.length < 4) ? 'En az 4 hane gerekli.' : null,
            ),
            const SizedBox(height: 12),
            // Rol seçimi
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon:
                    Icon(Icons.admin_panel_settings, color: AppTheme.primary),
              ),
              items: UserRole.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (r) {
                if (r != null) setState(() => _role = r);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _create,
                child: const Text('Profil Oluştur'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _create() {
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
    Navigator.pop(context);
  }
}
