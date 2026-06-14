import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../domain/model/debate_session.dart';
import '../../domain/model/progress_record.dart';
import '../../domain/repository/progress_repository.dart';
import '../../data/remote/notification_datasource.dart';
import '../home/home_viewmodel.dart';
import 'progress_viewmodel.dart';

class _BadgeDef {
  final String id;
  final String emoji;
  final String name;
  final String desc;
  const _BadgeDef(this.id, this.emoji, this.name, this.desc);
}

const _allBadges = [
  _BadgeDef('first_debate', '🥇', 'First Steps', 'Complete your first debate'),
  _BadgeDef('high_scorer', '🎯', 'High Scorer', 'Score 8+ in a debate'),
  _BadgeDef('perfect', '💯', 'Perfect Score', 'Achieve a perfect 10/10'),
  _BadgeDef('on_a_roll', '🔥', 'On a Roll', '3-day debate streak'),
  _BadgeDef('veteran', '⚔️', 'Veteran', 'Complete 10 debates'),
  _BadgeDef('week_warrior', '🏆', 'Week Warrior', '7-day debate streak'),
];

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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final progressVm = context.read<ProgressViewModel>();
    final homeVm = context.read<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROGRESS'),
        actions: [
          StreamBuilder<ProgressRecord?>(
            stream: progressVm.progressStream,
            builder: (context, snap) {
              final goal = snap.data?.weeklyGoal ?? 5;
              return IconButton(
                icon: const Icon(Icons.flag_rounded),
                tooltip: 'Edit weekly goal',
                onPressed: () => _editGoalDialog(context, goal),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<ProgressRecord?>(
        stream: progressVm.progressStream,
        builder: (context, progressSnap) {
          final progress = progressSnap.data;

          return StreamBuilder<List<DebateSession>>(
            stream: homeVm.getRecentSessions(uid),
            builder: (context, sessionsSnap) {
              final sessions = sessionsSnap.data ?? [];
              final thisWeek = sessions
                  .where((s) =>
                      DateTime.now().difference(s.createdAt).inDays < 7)
                  .length;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                      child: _buildStatsCard(progress, sessions)),
                  SliverToBoxAdapter(
                      child: _buildWeeklyGoal(
                          context, thisWeek, progress?.weeklyGoal ?? 5)),
                  if (progress != null && progress.scores.isNotEmpty)
                    SliverToBoxAdapter(
                        child: _buildScoreChart(progress.scores)),
                  SliverToBoxAdapter(
                      child: _buildBadges(progress?.badges ?? [])),
                  SliverToBoxAdapter(
                      child: _buildHistoryHeader(sessions)),
                  if (sessions.isEmpty)
                    SliverToBoxAdapter(child: _buildEmpty())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) =>
                            _buildSwipeableCard(ctx, sessions[i], uid),
                        childCount: sessions.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- Stats card ---

  Widget _buildStatsCard(
      ProgressRecord? progress, List<DebateSession> sessions) {
    final streak = progress?.streak ?? 0;
    final scored =
        sessions.where((s) => s.score > 0).map((s) => s.score).toList();
    final avg = scored.isEmpty
        ? '—'
        : (scored.reduce((a, b) => a + b) / scored.length)
            .toStringAsFixed(1);
    final best = scored.isEmpty
        ? '—'
        : scored.reduce((a, b) => a > b ? a : b).toString();

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
          _statItem('$streak 🔥', 'Streak', Icons.local_fire_department),
          _vDivider(),
          _statItem(avg, 'Avg Score', Icons.trending_up),
          _vDivider(),
          _statItem(best, 'Best', Icons.emoji_events_rounded),
          _vDivider(),
          _statItem('${sessions.length}', 'Sessions', Icons.gavel),
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
                  fontSize: 15,
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

  // --- Weekly goal ---

  Widget _buildWeeklyGoal(BuildContext context, int thisWeek, int goal) {
    final progress = (thisWeek / goal).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('WEEKLY GOAL',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              Text('$thisWeek / $goal debates',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
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
          if (thisWeek >= goal)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('🎉 Goal reached this week!',
                  style: TextStyle(
                      color: AppTheme.proColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Future<void> _editGoalDialog(BuildContext context, int current) async {
    int selected = current;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Text('WEEKLY GOAL',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'How many debates do you want to complete each week?',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppTheme.primary),
                    onPressed:
                        selected > 1 ? () => setState(() => selected--) : null,
                  ),
                  const SizedBox(width: 8),
                  Text('$selected',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppTheme.primary),
                    onPressed: selected < 14
                        ? () => setState(() => selected++)
                        : null,
                  ),
                ],
              ),
              const Text('debates / week',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: const Text('SAVE')),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      await context.read<ProgressViewModel>().updateWeeklyGoal(result);
    }
  }

  // --- Score chart ---

  Widget _buildScoreChart(List<int> scores) {
    final display =
        scores.length > 15 ? scores.sublist(scores.length - 15) : scores;
    final spots = List.generate(
      display.length,
      (i) => FlSpot(i.toDouble(), display[i].toDouble()),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('SCORE HISTORY',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 10,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppTheme.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 5,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: AppTheme.primary,
                        strokeColor: AppTheme.background,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Last ${display.length} scored session${display.length == 1 ? '' : 's'}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // --- Badges ---

  Widget _buildBadges(List<String> earnedIds) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
              const Text('BADGES',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              const Spacer(),
              Text('${earnedIds.length}/${_allBadges.length} earned',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _allBadges
                .map((b) => _buildBadgeCard(b, earnedIds.contains(b.id)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(_BadgeDef badge, bool earned) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: earned
            ? AppTheme.secondary.withValues(alpha: 0.08)
            : AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: earned
              ? AppTheme.secondary.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(earned ? badge.emoji : '🔒',
              style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 5),
          Text(badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: earned
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(badge.desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: earned
                      ? AppTheme.textSecondary
                      : AppTheme.textSecondary.withValues(alpha: 0.4),
                  fontSize: 9),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // --- Session history ---

  Widget _buildHistoryHeader(List<DebateSession> sessions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        sessions.isEmpty ? '' : 'SESSION HISTORY',
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSwipeableCard(
      BuildContext context, DebateSession session, String uid) {
    return Dismissible(
      key: Key(session.sessionId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Session?'),
            content: Text(
                'Delete "${session.topicTitle}"? This also removes all messages and cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<HomeViewModel>().deleteSession(session.sessionId);
        // D CRUD for Person C — remove score from progress/ collection
        if (session.score > 0) {
          context
              .read<ProgressRepository>()
              .removeScore(userId: uid, score: session.score);
        }
        NotificationDatasource().showSessionDeleted(session.topicTitle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${session.topicTitle}" deleted.'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('DELETE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ],
        ),
      ),
      child: _buildSessionCard(session),
    );
  }

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
            child: Text(isPro ? 'PRO' : 'CON',
                style: TextStyle(
                    color: stanceColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5)),
          ),
        ),
        title: Text(session.topicTitle,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_timeAgo(session.createdAt),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ),
        trailing: session.score > 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${session.score}',
                      style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const Text('pts',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              )
            : const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary),
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
          Text('No sessions yet',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
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
}
