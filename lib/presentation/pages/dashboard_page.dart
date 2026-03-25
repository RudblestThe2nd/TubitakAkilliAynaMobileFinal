import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../core/di/injection_container.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/task.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/user/user_cubit.dart';
import '../blocs/voice/voice_cubit.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/voice_assistant_widget.dart';
import 'tasks_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeTab(onProfileTap: () => setState(() => _selectedIndex = 2)),
      const TasksPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<TaskBloc>()),
        BlocProvider(
          create: (ctx) => sl<VoiceCubit>(param1: ctx.read<TaskBloc>()),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }
}

// ── Alt Navigasyon ────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textDisabled,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_outlined),
            activeIcon: Icon(Icons.task_alt),
            label: 'Görevler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ── Ana Sekme (Home) ──────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final VoidCallback onProfileTap;
  const _HomeTab({required this.onProfileTap});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayTasks();
    });
  }

  void _loadTodayTasks() {
    final userState = context.read<UserCubit>().state;
    if (userState is UserAuthenticated) {
      context.read<TaskBloc>().add(LoadTodayTasksEvent(userState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserAuthenticated) {
          _loadTodayTasks();
        }
      },
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(onProfileTap: widget.onProfileTap),
            ),

          SliverToBoxAdapter(child: _AiStatusCard()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _VoiceSection(),
            ),
          ),

          SliverToBoxAdapter(child: _TodaySummary()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bugünkü Görevler',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Tümü',
                        style: TextStyle(color: AppTheme.primary)),
                  ),
                ],
              ),
            ),
          ),

          BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is TaskLoading) {
                return const SliverToBoxAdapter(
                  child: _LoadingShimmer(),
                );
              }
              if (state is TaskLoaded) {
                final tasks = state.filteredTasks
                    .where((t) => !t.isCompleted)
                    .take(5)
                    .toList();
                if (tasks.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyTasksCard(
                      neverAdded: state.tasks.isEmpty,
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => FadeInUp(
                      delay: Duration(milliseconds: i * 80),
                      child: TaskCardWidget(
                        task: tasks[i],
                        onToggle: () => context
                            .read<TaskBloc>()
                            .add(ToggleTaskEvent(tasks[i].id)),
                        onDelete: () => context
                            .read<TaskBloc>()
                            .add(RemoveTaskEvent(tasks[i].id)),
                        onSpeak: () {
                          final t = tasks[i];
                          final buf = StringBuffer(t.title);
                          if (t.description != null &&
                              t.description!.isNotEmpty) {
                            buf.write('. ${t.description}');
                          }
                          buf.write('. Öncelik: ${t.priority.label}');
                          context.read<VoiceCubit>().speak(buf.toString());
                        },
                      ),
                    ),
                    childCount: tasks.length,
                  ),
                );
              }
              if (state is TaskError) {
                return SliverToBoxAdapter(
                  child: _ErrorCard(message: state.message),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onProfileTap;
  const _DashboardHeader({required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final dateStr = DateFormat('d MMMM, EEEE', 'tr_TR').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInLeft(
                  child: BlocBuilder<UserCubit, UserState>(
                    builder: (context, state) {
                      final name = state is UserAuthenticated
                          ? state.user.name
                          : 'Kullanıcı';
                      return Text(
                        '$greeting, $name',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                FadeInLeft(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<UserCubit, UserState>(
            builder: (context, state) {
              final name = state is UserAuthenticated ? state.user.name : '?';
              final isGuest = state is! UserAuthenticated;
              return GestureDetector(
                onTap: isGuest ? onProfileTap : null,
                child: _Avatar(
                  initial: name[0].toUpperCase(),
                  showAddHint: isGuest,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi öğleden sonralar';
    return 'İyi akşamlar';
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final bool showAddHint;
  const _Avatar({required this.initial, this.showAddHint = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: showAddHint ? null : AppTheme.primaryGradient,
            color: showAddHint ? AppTheme.surfaceVariant : null,
            border: showAddHint
                ? Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  )
                : null,
            boxShadow: showAddHint ? null : AppShadows.glow(),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: showAddHint ? AppTheme.primary : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showAddHint)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
              ),
              child: const Icon(Icons.add, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

// ── AI Durum Kartı ────────────────────────────────────────────────────────

class _AiStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.glow(blurRadius: 24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Asistan Hazır',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mikrofona basarak konuşabilirsiniz',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ses Bölümü ────────────────────────────────────────────────────────────

class _VoiceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: const VoiceAssistantWidget(),
    );
  }
}

// ── Bugünkü Özet ──────────────────────────────────────────────────────────

class _TodaySummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is! TaskLoaded) return const SizedBox.shrink();

        final total = state.tasks.length;
        final completed = state.completedCount;
        final progress = state.completionRate;

        return FadeInUp(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _StatCard(
                    icon: Icons.pending_actions,
                    value: '${state.pendingCount}',
                    label: 'Bekleyen',
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _StatCard(
                    icon: Icons.task_alt,
                    value: '$completed',
                    label: 'Tamamlandı',
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _ProgressCard(
                    progress: progress,
                    total: total,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int total;
  const _ProgressCard({required this.progress, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İlerleme',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          CircularPercentIndicator(
            radius: 28,
            lineWidth: 5,
            percent: progress.clamp(0, 1),
            center: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            progressColor: AppTheme.primary,
            backgroundColor: AppTheme.dividerColor,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 4),
          Text(
            '$total görev',
            style: const TextStyle(
              color: AppTheme.textDisabled,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Yardımcı Widget'lar ───────────────────────────────────────────────────

class _EmptyTasksCard extends StatelessWidget {
  final bool neverAdded;
  const _EmptyTasksCard({this.neverAdded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: neverAdded
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            neverAdded ? Icons.add_task : Icons.check_circle_outline,
            color: neverAdded ? AppTheme.primary : AppTheme.success,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            neverAdded
                ? 'Henüz görev eklenmedi.'
                : 'Bugün tüm görevler tamamlandı!',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            neverAdded
                ? 'Görevler sekmesinden yeni görev ekleyebilirsiniz.'
                : 'Harika bir gün geçiriyorsunuz.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
