import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../domain/model/topic.dart';
import '../../domain/repository/debate_repository.dart';
import '../../data/remote/ai_remote_datasource.dart';
import 'start_debate_viewmodel.dart';
import 'debate_chat_screen.dart';
import 'debate_chat_viewmodel.dart';

class StartDebateScreen extends StatelessWidget {
  const StartDebateScreen({super.key});

  Future<void> _startDebate(BuildContext context) async {
    final vm = context.read<StartDebateViewModel>();
    final debateRepo = context.read<DebateRepository>();
    final aiDatasource = context.read<AIRemoteDatasource>();

    final session = await vm.startDebate();
    if (session == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => DebateChatViewModel(
            session: session,
            debateRepository: debateRepo,
            aiDatasource: aiDatasource,
          ),
          child: const DebateChatScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StartDebateViewModel>();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildTopicSection(context, vm)),
                if (vm.selectedTopic != null)
                  SliverToBoxAdapter(child: _buildStanceSection(context, vm)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
          _buildBottomCTA(context, vm),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF200808), AppTheme.background],
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHOOSE YOUR',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      )),
                  Text('BATTLE',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        height: 1,
                      )),
                ],
              ),
            ),
          ),
        ),
        title: const Text('NEW DEBATE'),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
    );
  }

  Widget _buildTopicSection(BuildContext context, StartDebateViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SELECT YOUR TOPIC'),
          const SizedBox(height: 14),
          StreamBuilder<List<Topic>>(
            stream: context.read<StartDebateViewModel>().topicsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ));
              }

              final topics = snapshot.data ?? [];
              final categories = [
                'All',
                ...{...topics.map((t) => t.category)},
              ];
              final filtered = vm.selectedCategory == 'All'
                  ? topics
                  : topics.where((t) => t.category == vm.selectedCategory).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryFilter(context, categories, vm),
                  const SizedBox(height: 16),
                  ...filtered.map((t) => _buildTopicCard(context, t, vm)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
      BuildContext context, List<String> categories, StartDebateViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = vm.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.read<StartDebateViewModel>().selectCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceVar,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.border),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopicCard(
      BuildContext context, Topic topic, StartDebateViewModel vm) {
    final isSelected = vm.selectedTopic?.topicId == topic.topicId;
    final diffColor = switch (topic.difficulty) {
      'easy' => AppTheme.proColor,
      'hard' => AppTheme.conColor,
      _ => AppTheme.secondary,
    };

    return GestureDetector(
      onTap: () => context.read<StartDebateViewModel>().selectTopic(isSelected ? null : topic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip(topic.category, AppTheme.textSecondary,
                          AppTheme.surfaceVar),
                      const SizedBox(width: 8),
                      _chip(topic.difficulty.toUpperCase(), diffColor,
                          diffColor.withValues(alpha: 0.1)),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 12),
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                    color: AppTheme.primary, shape: BoxShape.circle),
                child:
                    const Icon(Icons.check, color: Colors.white, size: 15),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStanceSection(BuildContext context, StartDebateViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CHOOSE YOUR STANCE'),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildStanceOption(
                      context, vm, 'pro', 'PRO', 'Argue in favor',
                      AppTheme.proColor, Icons.thumb_up_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 16),
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceVar,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('VS',
                            style: TextStyle(
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _buildStanceOption(
                      context, vm, 'con', 'CON', 'Argue against',
                      AppTheme.conColor, Icons.thumb_down_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStanceOption(
    BuildContext context,
    StartDebateViewModel vm,
    String stance,
    String label,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    final isSelected = vm.selectedStance == stance;
    return GestureDetector(
      onTap: () => context
          .read<StartDebateViewModel>()
          .selectStance(isSelected ? null : stance),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? color : AppTheme.border,
              width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? color : AppTheme.textSecondary,
                size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? color : AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: isSelected
                        ? color.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, StartDebateViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vm.canStart) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceVar,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      vm.selectedTopic!.title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (vm.selectedStance == 'pro'
                              ? AppTheme.proColor
                              : AppTheme.conColor)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vm.selectedStance!.toUpperCase(),
                      style: TextStyle(
                        color: vm.selectedStance == 'pro'
                            ? AppTheme.proColor
                            : AppTheme.conColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.canStart && !vm.isLoading
                  ? () => _startDebate(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    vm.canStart ? AppTheme.primary : AppTheme.surfaceVar,
                foregroundColor:
                    vm.canStart ? Colors.white : AppTheme.textSecondary,
                disabledBackgroundColor: AppTheme.surfaceVar,
                disabledForegroundColor: AppTheme.textSecondary,
              ),
              child: vm.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      vm.canStart ? 'ENTER THE ARENA' : 'SELECT TOPIC & STANCE',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}
