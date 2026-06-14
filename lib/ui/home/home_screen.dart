import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../domain/model/debate_session.dart';
import '../../domain/model/topic.dart';
import '../topics/topics_viewmodel.dart';
import 'home_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToDebate;

  const HomeScreen({super.key, required this.onNavigateToDebate});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final vm = context.read<HomeViewModel>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildStreakAndGoal(context, vm, userId)),
          SliverToBoxAdapter(child: _buildFeaturedTopic(context)),
          SliverToBoxAdapter(child: _buildEnterArenaButton(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0505), AppTheme.background],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.07),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 80, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.whatshot, color: AppTheme.secondary, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'DEBATE ARENA',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sharpen your arguments. Win every debate.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakAndGoal(
      BuildContext context, HomeViewModel vm, String userId) {
    return StreamBuilder<List<DebateSession>>(
      stream: vm.getRecentSessions(userId),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        final thisWeek = sessions.where((s) {
          final diff = DateTime.now().difference(s.createdAt).inDays;
          return diff < 7;
        }).length;
        const weeklyGoal = 5;
        final progress = (thisWeek / weeklyGoal).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppTheme.secondary, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'STREAK',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${sessions.length} total sessions',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '0 days',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'WEEKLY GOAL',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '$thisWeek / $weeklyGoal debates',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceVar,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedTopic(BuildContext context) {
    return StreamBuilder<List<Topic>>(
      stream: context.read<TopicsViewModel>().topicsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final topic = snapshot.data!.first;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'FEATURED TOPIC',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                topic.title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _chip(topic.category, AppTheme.textSecondary,
                      AppTheme.surfaceVar),
                  const SizedBox(width: 8),
                  _chip(
                    topic.difficulty.toUpperCase(),
                    _diffColor(topic.difficulty),
                    _diffColor(topic.difficulty).withValues(alpha: 0.1),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnterArenaButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onNavigateToDebate,
          icon: const Icon(Icons.gavel, size: 20),
          label: const Text(
            'ENTER THE ARENA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _diffColor(String difficulty) => switch (difficulty) {
        'easy' => AppTheme.proColor,
        'hard' => AppTheme.conColor,
        _ => AppTheme.secondary,
      };
}
