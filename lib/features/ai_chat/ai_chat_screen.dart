import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../core/ai/ai_chat_service.dart';
import '../../core/ai/ai_key_service.dart';
import '../../core/local_ai_service.dart';
import '../../core/user_provider.dart';
import 'models/chat_message.dart';

/// AI 인지 대화 화면
///
/// - Gemini(또는 Fallback) AI와 3~5턴 자연 대화
/// - 텍스트 입력 또는 마이크(STT) 입력
/// - 대화 종료 후 LocalAIService로 인지 점수 분석 → DB 저장
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _messages = <ChatMessage>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _speech = SpeechToText();

  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _sessionEnded = false;
  double? _finalScore;
  String _analysisDetail = '';

  static const int _maxTurns = 10;
  int _aiTurnCount = 0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _startSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  /// 세션 시작: AI가 먼저 인사
  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    final greeting = await AiChatService.chat('안녕하세요, 대화를 시작해 주세요.', []);
    if (!mounted) return;
    _addMessage(ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()));
    _aiTurnCount++;
    setState(() => _isLoading = false);
  }

  void _addMessage(ChatMessage msg) {
    setState(() => _messages.add(msg));
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

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading || _sessionEnded) return;

    _textController.clear();
    _addMessage(ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()));
    setState(() => _isLoading = true);

    final response = await AiChatService.chat(trimmed, List.from(_messages));
    if (!mounted) return;

    _addMessage(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
    _aiTurnCount++;

    final sessionDone = _aiTurnCount >= _maxTurns;

    setState(() => _isLoading = false);

    if (sessionDone) await _endSession();
  }

  Future<void> _endSession() async {
    if (_sessionEnded) return;
    setState(() {
      _sessionEnded = true;
      _isLoading = true;
    });

    // 사용자 발화 전체 합산
    final userTexts = _messages.where((m) => m.isUser).map((m) => m.text).join(' ');
    final words = userTexts.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final totalWords = words.length;
    final uniqueWords = words.map((w) => w.toLowerCase()).toSet().length;
    final ttr = totalWords > 0 ? uniqueWords / totalWords : 0.0;

    // 대화 시간 기반 WPM 추정 (세션 시작부터 현재까지)
    final durationSec = _messages.isNotEmpty
        ? DateTime.now().difference(_messages.first.timestamp).inSeconds
        : 60;
    final wpm = durationSec > 0 ? (totalWords / durationSec) * 60 : 0.0;

    // LocalAIService로 인지 점수 분석
    final result = await LocalAIService().analyzeText(
      text: userTexts,
      ttr: ttr,
      wpm: wpm,
      totalWords: totalWords,
      durationSeconds: durationSec,
    );

    if (!mounted) return;

    final score = (result['cognitive_score'] as double).clamp(0.0, 100.0);
    final analysis = result['analysis'] as String? ?? '';

    setState(() {
      _finalScore = score;
      _analysisDetail = analysis;
      _isLoading = false;
    });
  }

  Future<void> _showApiKeyDialog() async {
    final storedKey = await AiKeyService.getStoredKey();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => _ApiKeyDialog(
        initialKey: storedKey,
        onSave: (key) async {
          await AiChatService.applyApiKey(key);
          if (mounted) setState(() {});
        },
        onDelete: () async {
          await AiChatService.removeApiKey();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _saveScore() async {
    if (_finalScore == null) return;
    final user = context.read<UserProvider>();
    user.setCognitiveScore('voice', _finalScore!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결과가 저장되었습니다.')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    if (!_speechAvailable) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (mounted) _textController.text = result.recognizedWords;
      },
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('AI 대화 도우미'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // AI 제공자 상태 표시 + 설정 버튼
          IconButton(
            icon: Icon(
              AiChatService.isUsingAI ? Icons.smart_toy : Icons.smart_toy_outlined,
              color: AiChatService.isUsingAI ? Colors.green : null,
            ),
            tooltip: AiChatService.isUsingAI
                ? 'Gemini AI 연결됨'
                : 'API 키 없음 (기본 대화)',
            onPressed: _showApiKeyDialog,
          ),
          if (!_sessionEnded)
            TextButton(
              onPressed: _endSession,
              child: const Text('대화 종료'),
            ),
        ],
      ),
      body: Column(
        children: [
          // 진행 표시 바
          _buildProgressBar(theme),

          // 메시지 목록
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i], theme),
            ),
          ),

          // 로딩 인디케이터
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text('AI가 생각 중...', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),

          // 분석 결과 카드
          if (_sessionEnded && _finalScore != null)
            _buildResultCard(theme),

          // 입력창
          if (!_sessionEnded)
            _buildInputBar(theme),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = (_aiTurnCount / _maxTurns).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('대화 진행', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              Text('$_aiTurnCount / $_maxTurns 턴', style: TextStyle(fontSize: 12, color: theme.primaryColor)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, ThemeData theme) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
              child: Icon(Icons.smart_toy_outlined, size: 18, color: theme.primaryColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? theme.primaryColor : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          // 마이크 버튼
          IconButton(
            onPressed: _speechAvailable ? _toggleListening : null,
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none_outlined,
              color: _isListening ? Colors.red : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          // 텍스트 입력
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          // 전송 버튼
          FilledButton(
            onPressed: () => _sendMessage(_textController.text),
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final score = _finalScore!;
    final isGood = score >= 60;
    final color = score >= 75 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isGood ? Icons.check_circle_outline : Icons.info_outline, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                '오늘 대화 점수: ${score.toStringAsFixed(0)}점',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          if (_analysisDetail.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_analysisDetail, style: const TextStyle(fontSize: 13, height: 1.6)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveScore,
              icon: const Icon(Icons.save_outlined),
              label: const Text('결과 저장하기'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// API 키 설정 다이얼로그 — 자체 TextEditingController 수명 주기 관리
class _ApiKeyDialog extends StatefulWidget {
  final String? initialKey;
  final Future<void> Function(String key) onSave;
  final Future<void> Function() onDelete;

  const _ApiKeyDialog({
    required this.initialKey,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKey ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKey = widget.initialKey != null;
    final isUsing = AiChatService.isUsingAI;

    return AlertDialog(
      title: const Text('Gemini API 키 설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUsing
                ? '현재 Gemini AI가 연결되어 있습니다.'
                : 'API 키를 등록하면 Gemini AI와 대화할 수 있습니다.',
            style: TextStyle(
              fontSize: 13,
              color: isUsing ? Colors.green : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Gemini API 키',
              hintText: 'AIza...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key_outlined),
            ),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          Text(
            'Google AI Studio에서 무료로 발급받을 수 있습니다.',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        if (hasKey)
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    final nav = Navigator.of(context);
                    await widget.onDelete();
                    nav.pop();
                  },
            child: const Text('키 삭제', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final key = _controller.text.trim();
                  if (key.isEmpty) return;
                  setState(() => _saving = true);
                  final nav = Navigator.of(context);
                  await widget.onSave(key);
                  nav.pop();
                },
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('저장'),
        ),
      ],
    );
  }
}
