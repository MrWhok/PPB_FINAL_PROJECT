import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/debate_session.dart';
import '../../models/topic.dart';
import 'debate_chat_screen.dart';

class StartDebateScreen extends StatefulWidget {
  const StartDebateScreen({super.key});

  @override
  State<StartDebateScreen> createState() => _StartDebateScreenState();
}

class _StartDebateScreenState extends State<StartDebateScreen> {
  Topic? _selectedTopic;
  String? _selectedStance;
  String _selectedCategory = 'All';
  bool _isLoading = false;

  List<String> get _categories => [
        'All',
        ...{...kSampleTopics.map((t) => t.category)},
      ];

  List<Topic> get _filteredTopics => _selectedCategory == 'All'
      ? kSampleTopics
      : kSampleTopics.where((t) => t.category == _selectedCategory).toList();

  Future<void> _startDebate() async {
    if (_selectedTopic == null || _selectedStance == null) return;
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final ref =
          FirebaseFirestore.instance.collection('debateSessions').doc();
      final session = DebateSession(
        sessionId: ref.id,
        userId: userId,
        topicId: _selectedTopic!.topicId,
        topicTitle: _selectedTopic!.title,
        stance: _selectedStance!,
        createdAt: DateTime.now(),
      );
      await ref.set(session.toMap());
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DebateChatScreen(session: session)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _selectedTopic != null && _selectedStance != null;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildTopicSection()),
                if (_selectedTopic != null)
                  SliverToBoxAdapter(child: _buildStanceSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
          _buildBottomCTA(canStart),
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
                  Text(
                    'CHOOSE YOUR',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'BATTLE',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      height: 1,
                    ),
                  ),
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

  Widget _buildTopicSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SELECT YOUR TOPIC'),
          const SizedBox(height: 14),
          _buildCategoryFilter(),
          const SizedBox(height: 16),
          ..._filteredTopics.map(_buildTopicCard),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.surfaceVar,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopicCard(Topic topic) {
    final isSelected = _selectedTopic?.topicId == topic.topicId;
    final diffColor = switch (topic.difficulty) {
      'easy' => AppTheme.proColor,
      'hard' => AppTheme.conColor,
      _ => AppTheme.secondary,
    };

    return GestureDetector(
      onTap: () => setState(() {
        _selectedTopic = isSelected ? null : topic;
        if (!isSelected) _selectedStance = null;
      }),
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
                  Text(
                    topic.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
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
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 15),
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
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStanceSection() {
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
                    'pro',
                    'PRO',
                    'Argue in favor',
                    AppTheme.proColor,
                    Icons.thumb_up_rounded,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVar,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'VS',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _buildStanceOption(
                    'con',
                    'CON',
                    'Argue against',
                    AppTheme.conColor,
                    Icons.thumb_down_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStanceOption(
    String stance,
    String label,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    final isSelected = _selectedStance == stance;
    return GestureDetector(
      onTap: () => setState(
          () => _selectedStance = isSelected ? null : stance),
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
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppTheme.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? color.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTA(bool canStart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canStart) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVar,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedTopic!.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_selectedStance == 'pro'
                              ? AppTheme.proColor
                              : AppTheme.conColor)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedStance!.toUpperCase(),
                      style: TextStyle(
                        color: _selectedStance == 'pro'
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
              onPressed: canStart && !_isLoading ? _startDebate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canStart ? AppTheme.primary : AppTheme.surfaceVar,
                foregroundColor:
                    canStart ? Colors.white : AppTheme.textSecondary,
                disabledBackgroundColor: AppTheme.surfaceVar,
                disabledForegroundColor: AppTheme.textSecondary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      canStart ? 'ENTER THE ARENA' : 'SELECT TOPIC & STANCE',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
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
