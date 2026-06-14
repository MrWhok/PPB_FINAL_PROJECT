import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../domain/model/debate_session.dart';
import '../home/home_viewmodel.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final stream = context.read<HomeViewModel>().getRecentSessions(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('PROGRESS')),
      body: StreamBuilder<List<DebateSession>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          final sessions = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildStats(sessions)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    sessions.isEmpty ? '' : 'SESSION HISTORY',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              if (sessions.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildSessionCard(sessions[i]),
                    childCount: sessions.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStats(List<DebateSession> sessions) {
    final scored =
        sessions.where((s) => s.score > 0).map((s) => s.score).toList();
    final avg = scored.isEmpty
        ? '—'
        : (scored.reduce((a, b) => a + b) / scored.length)
            .toStringAsFixed(1);
    final best =
        scored.isEmpty ? '—' : scored.reduce((a, b) => a > b ? a : b).toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _statItem('${sessions.length}', 'Sessions', Icons.gavel),
          _vDivider(),
          _statItem(avg, 'Avg Score', Icons.trending_up),
          _vDivider(),
          _statItem(best, 'Best Score', Icons.emoji_events_rounded),
          _vDivider(),
          _statItem('0', 'Streak', Icons.local_fire_department),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 44, color: AppTheme.divider);

  Widget _buildSessionCard(DebateSession session) {
    final isPro = session.stance == 'pro';
    final stanceColor = isPro ? AppTheme.proColor : AppTheme.conColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: stanceColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: stanceColor.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              isPro ? 'PRO' : 'CON',
              style: TextStyle(
                color: stanceColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        title: Text(
          session.topicTitle,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _timeAgo(session.createdAt),
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
        trailing: session.score > 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${session.score}',
                    style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  const Text('pts',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              )
            : const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.history_rounded, color: AppTheme.textSecondary, size: 48),
          SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Complete a debate and your history\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.secondary, size: 48),
            SizedBox(height: 16),
            Text('Could not load sessions',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Check your connection and try again.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
