import 'package:flutter/material.dart';
import '../../models/debate_session.dart';
import '../../theme/app_theme.dart';

// Week 2 placeholder — AI chat will be built here
class DebateChatScreen extends StatelessWidget {
  final DebateSession session;

  const DebateChatScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final isPro = session.stance == 'pro';
    final stanceColor = isPro ? AppTheme.proColor : AppTheme.conColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEBATE SESSION'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.construction_rounded,
                    color: AppTheme.secondary, size: 36),
              ),
              const SizedBox(height: 24),
              const Text(
                'WEEK 2 FEATURE',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI Chat Interface',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              // Session summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SESSION CREATED',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      session.topicTitle,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: stanceColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: stanceColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            isPro ? 'PRO — In Favor' : 'CON — Against',
                            style: TextStyle(
                              color: stanceColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.check_circle,
                            color: AppTheme.proColor, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Saved to Firestore',
                          style: TextStyle(
                              color: AppTheme.proColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Groq AI chat integration coming in Week 2.\nYour session is saved — check the Home tab.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('BACK TO HOME'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
