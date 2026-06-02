import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/debate_session.dart';
import '../../models/message.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

class DebateChatScreen extends StatefulWidget {
  final DebateSession session;

  const DebateChatScreen({super.key, required this.session});

  @override
  State<DebateChatScreen> createState() => _DebateChatScreenState();
}

class _DebateChatScreenState extends State<DebateChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  late String _currentStance;
  bool _isAiThinking = false;
  bool _sessionEnded = false;
  List<Message> _messages = [];

  // Voice state
  String _language = 'en'; // 'en' or 'id'
  bool _isRecording = false; // mic is actively recording audio
  bool _isTranscribing = false; // waiting on Whisper transcription
  bool _autoSpeak = false; // auto read AI replies aloud
  String? _speakingMessageId; // id of message currently being read aloud

  @override
  void initState() {
    super.initState();
    _currentStance = widget.session.stance;
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingMessageId = null);
    });
  }

  String get _ttsLanguage => _language == 'id' ? 'id-ID' : 'en-US';

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _tts.stop();
    super.dispose();
  }

  // --- Voice input: record audio, then transcribe with Groq Whisper ---

  Future<void> _toggleRecording() async {
    if (_isTranscribing) return;

    if (_isRecording) {
      await _stopAndTranscribe();
      return;
    }

    // Start recording
    await _stopSpeaking();
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied.')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/debate_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopAndTranscribe() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    if (path == null) {
      if (mounted) setState(() => _isTranscribing = false);
      return;
    }

    try {
      final text = await _aiService.transcribeAudio(
        filePath: path,
        language: _language,
      );
      if (text.isNotEmpty) {
        // Append the transcript to whatever is already in the box — never wipes
        final existing = _inputController.text.trim();
        _inputController.text =
            existing.isEmpty ? text : '$existing $text';
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not transcribe audio. Check connection.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTranscribing = false);
    }
  }

  // --- Voice: text-to-speech output ---

  Future<void> _speak(Message message) async {
    if (_speakingMessageId == message.messageId) {
      await _stopSpeaking();
      return;
    }
    await _stopSpeaking();
    await _tts.setLanguage(_ttsLanguage);
    setState(() => _speakingMessageId = message.messageId);
    await _tts.speak(message.content);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (mounted) setState(() => _speakingMessageId = null);
  }

  void _switchLanguage(String lang) {
    if (lang == _language) return;
    _stopSpeaking();
    setState(() => _language = lang);
  }

  void _toggleAutoSpeak() {
    setState(() => _autoSpeak = !_autoSpeak);
    if (!_autoSpeak) _stopSpeaking();
  }

  Stream<QuerySnapshot> get _messagesStream => FirebaseFirestore.instance
      .collection('debateSessions')
      .doc(widget.session.sessionId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isAiThinking) return;

    _inputController.clear();
    setState(() => _isAiThinking = true);

    await _saveMessage(role: 'user', content: text);
    _scrollToBottom();

    try {
      final aiReply = await _aiService.generateCounterArgument(
        userArgument: text,
        topic: widget.session.topicTitle,
        stance: _currentStance,
        language: _language,
        previousMessages: _messages,
      );
      final aiMessage = await _saveMessage(role: 'ai', content: aiReply);
      if (_autoSpeak && mounted) _speak(aiMessage);
    } catch (e) {
      await _saveMessage(
        role: 'ai',
        content:
            'Could not get a response. Make sure your Groq API key is set in lib/config/secrets.dart.',
      );
    } finally {
      if (mounted) {
        setState(() => _isAiThinking = false);
        _scrollToBottom();
      }
    }
  }

  Future<Message> _saveMessage({
    required String role,
    required String content,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('debateSessions')
        .doc(widget.session.sessionId)
        .collection('messages')
        .doc();

    final message = Message(
      messageId: ref.id,
      sessionId: widget.session.sessionId,
      role: role,
      content: content,
      timestamp: DateTime.now(),
    );
    await ref.set(message.toMap());
    return message;
  }

  Future<void> _editStance() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _StanceDialog(currentStance: _currentStance),
    );
    if (result == null || result == _currentStance) return;

    await FirebaseFirestore.instance
        .collection('debateSessions')
        .doc(widget.session.sessionId)
        .update({'stance': result});

    setState(() => _currentStance = result);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stance changed to ${result.toUpperCase()}')),
      );
    }
  }

  Future<void> _endSession() async {
    final userMessages = _messages.where((m) => m.role == 'user').toList();
    if (userMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Make at least one argument before ending.')),
      );
      return;
    }

    // Show loading dialog while AI scores
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ScoringDialog(),
    );

    try {
      final result = await _aiService.scoreDebate(
        topic: widget.session.topicTitle,
        stance: _currentStance,
        messages: _messages,
        language: _language,
      );

      final score = result['score'] as int;
      final feedback = result['feedback'] as String;

      await FirebaseFirestore.instance
          .collection('debateSessions')
          .doc(widget.session.sessionId)
          .update({'score': score, 'feedback': feedback});

      setState(() => _sessionEnded = true);

      if (!mounted) return;
      Navigator.pop(context); // close loading dialog

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SessionSummaryDialog(
          score: score,
          feedback: feedback,
          stance: _currentStance,
          messageCount: userMessages.length,
          onDone: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not score debate. Check your connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = _currentStance == 'pro';
    final stanceColor = isPro ? AppTheme.proColor : AppTheme.conColor;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.session.topicTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: stanceColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPro ? 'PRO — In Favor' : 'CON — Against',
                style: TextStyle(
                  color: stanceColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!_sessionEnded)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Edit stance',
              onPressed: _editStance,
            ),
          if (!_sessionEnded)
            TextButton(
              onPressed: _endSession,
              child: const Text(
                'END',
                style: TextStyle(
                  color: AppTheme.conColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildSessionBanner(),
          Expanded(child: _buildMessageList()),
          if (_sessionEnded) _buildEndedBanner() else _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEndedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: AppTheme.proColor, size: 18),
          SizedBox(width: 8),
          Text(
            'Session ended — score saved.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel, color: AppTheme.primary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.session.topicTitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _buildAutoSpeakToggle(),
          const SizedBox(width: 8),
          _buildLanguageToggle(),
        ],
      ),
    );
  }

  Widget _buildAutoSpeakToggle() {
    return GestureDetector(
      onTap: _toggleAutoSpeak,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _autoSpeak
              ? AppTheme.secondary.withValues(alpha: 0.15)
              : AppTheme.surfaceVar,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _autoSpeak ? AppTheme.secondary : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 13,
              color: _autoSpeak ? AppTheme.secondary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Auto',
              style: TextStyle(
                color: _autoSpeak ? AppTheme.secondary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _langChip('EN', 'en'),
          _langChip('ID', 'id'),
        ],
      ),
    );
  }

  Widget _langChip(String label, String lang) {
    final isSelected = _language == lang;
    return GestureDetector(
      onTap: () => _switchLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: AppTheme.conColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        _messages = snapshot.hasData
            ? snapshot.data!.docs.map(Message.fromDoc).toList()
            : [];

        final showEmpty = _messages.isEmpty && !_isAiThinking;
        final itemCount =
            _messages.length + (_isAiThinking ? 1 : 0) + (showEmpty ? 1 : 0);

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: itemCount,
          itemBuilder: (context, i) {
            if (showEmpty && i == 0) return _buildEmptyState();
            if (i == _messages.length && _isAiThinking) {
              return _buildThinkingBubble();
            }
            return _buildMessageBubble(_messages[i]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isPro = _currentStance == 'pro';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.mic_rounded,
                color: AppTheme.primary, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Arena is ready.',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are arguing ${isPro ? 'IN FAVOR of' : 'AGAINST'} this topic.\nType your opening argument below.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == 'user';
    final isPro = _currentStance == 'pro';
    final stanceColor = isPro ? AppTheme.proColor : AppTheme.conColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              isUser
                  ? 'YOU — ${_currentStance.toUpperCase()}'
                  : 'AI OPPONENT',
              style: TextStyle(
                color: isUser ? stanceColor : AppTheme.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? stanceColor.withValues(alpha: 0.12)
                  : AppTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(
                color: isUser
                    ? stanceColor.withValues(alpha: 0.35)
                    : AppTheme.border,
              ),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _speak(message),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _speakingMessageId == message.messageId
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_rounded,
                          color: _speakingMessageId == message.messageId
                              ? AppTheme.secondary
                              : AppTheme.textSecondary,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _speakingMessageId == message.messageId
                              ? 'Stop'
                              : 'Listen',
                          style: TextStyle(
                            color: _speakingMessageId == message.messageId
                                ? AppTheme.secondary
                                : AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'AI OPPONENT',
              style: TextStyle(
                color: AppTheme.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ThinkingDots(),
                SizedBox(width: 10),
                Text(
                  'Formulating counter...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    final disabled = _isAiThinking || _isTranscribing;
    return GestureDetector(
      onTap: disabled ? null : _toggleRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isRecording
              ? AppTheme.conColor.withValues(alpha: 0.15)
              : AppTheme.surfaceVar,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isRecording ? AppTheme.conColor : AppTheme.border,
          ),
        ),
        child: _isTranscribing
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppTheme.secondary,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color:
                    _isRecording ? AppTheme.conColor : AppTheme.textSecondary,
                size: 22,
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildMicButton(),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14),
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _isRecording
                    ? 'Recording... tap mic to stop'
                    : _isTranscribing
                        ? 'Transcribing...'
                        : (_language == 'id'
                            ? 'Sampaikan argumenmu...'
                            : 'Make your argument...'),
                hintStyle:
                    const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceVar,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.primary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isAiThinking ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isAiThinking
                    ? AppTheme.surfaceVar
                    : AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isAiThinking
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppTheme.textSecondary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// --- Animated thinking dots ---

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) {
        final active = _animation.value.floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: i == active ? 8 : 6,
                height: i == active ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == active
                      ? AppTheme.secondary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Edit stance dialog ---

class _StanceDialog extends StatefulWidget {
  final String currentStance;
  const _StanceDialog({required this.currentStance});

  @override
  State<_StanceDialog> createState() => _StanceDialogState();
}

class _StanceDialogState extends State<_StanceDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentStance;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      title: const Text(
        'CHANGE STANCE',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      content: Row(
        children: [
          Expanded(
              child: _option('pro', 'PRO', 'In favor', AppTheme.proColor)),
          const SizedBox(width: 12),
          Expanded(
              child:
                  _option('con', 'CON', 'Against', AppTheme.conColor)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('CONFIRM'),
        ),
      ],
    );
  }

  Widget _option(
      String stance, String label, String subtitle, Color color) {
    final isSelected = _selected == stance;
    return GestureDetector(
      onTap: () => setState(() => _selected = stance),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppTheme.surfaceVar,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
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
}

// --- AI scoring loading dialog ---

class _ScoringDialog extends StatelessWidget {
  const _ScoringDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
          SizedBox(height: 20),
          Text(
            'AI is judging your debate...',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Evaluating logic, clarity, and persuasiveness.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

// --- Session summary dialog ---

class _SessionSummaryDialog extends StatelessWidget {
  final int score;
  final String feedback;
  final String stance;
  final int messageCount;
  final VoidCallback onDone;

  const _SessionSummaryDialog({
    required this.score,
    required this.feedback,
    required this.stance,
    required this.messageCount,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isPro = stance == 'pro';
    final stanceColor = isPro ? AppTheme.proColor : AppTheme.conColor;
    final scoreColor = score >= 8
        ? AppTheme.proColor
        : score >= 5
            ? AppTheme.secondary
            : AppTheme.conColor;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'DEBATE COMPLETE',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _statRow('Score', '$score / 10', scoreColor),
          _statRow('Stance', stance.toUpperCase(), stanceColor),
          _statRow('Arguments made', '$messageCount', AppTheme.textPrimary),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVar,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '"$feedback"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Score & feedback saved to Firestore ✓',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            child: const Text('BACK TO HOME'),
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
