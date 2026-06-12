import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../core/theme.dart';
import '../../core/user_provider.dart';
import 'diary_provider.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialLoad());
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initialLoad() async {
    final userId = _userId;
    if (userId == null) return;
    final provider = context.read<DiaryProvider>();
    await provider.loadMonth(userId, _focusedDay);
    await provider.loadEntry(userId, _selectedDay);
    _syncTextController(provider.selectedContent);
    setState(() => _loaded = true);
  }

  int? get _userId =>
      context.read<UserProvider>().currentUser?['id'] as int?;

  bool get _isToday => isSameDay(_selectedDay, DateTime.now());

  void _syncTextController(String? content) {
    _textController.text = content ?? '';
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (selectedDay.isAfter(DateTime.now())) return;
    final userId = _userId;
    if (userId == null) return;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final provider = context.read<DiaryProvider>();

    if (!isSameDay(selectedDay, focusedDay) ||
        selectedDay.month != _focusedDay.month ||
        selectedDay.year != _focusedDay.year) {
      await provider.loadMonth(userId, focusedDay);
    }

    await provider.loadEntry(userId, selectedDay);
    _syncTextController(provider.selectedContent);
  }

  Future<void> _onPageChanged(DateTime focusedDay) async {
    final userId = _userId;
    if (userId == null) return;
    setState(() => _focusedDay = focusedDay);
    await context.read<DiaryProvider>().loadMonth(userId, focusedDay);
  }

  Future<void> _saveDiary() async {
    final userId = _userId;
    if (userId == null) return;
    final content = _textController.text;
    if (content.trim().isEmpty) return;

    final success = await context
        .read<DiaryProvider>()
        .saveDiary(userId, _selectedDay, content);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일기가 저장되었어요 ✨'),
          duration: Duration(seconds: 2),
        ),
      );
      _speech.stop();
      setState(() => _isListening = false);
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
        if (mounted) {
          final existing = _textController.text;
          final recognized = result.recognizedWords;
          _textController.text =
              existing.isEmpty ? recognized : '$existing $recognized';
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        }
      },
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DiaryProvider>();
    // 키보드가 50dp 이상 올라왔을 때 캘린더를 숨김
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 50;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('기억의 정원 일기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: '일기 모아보기',
            onPressed: () => context.push('/diary_book'),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 키보드가 열리면 캘린더를 애니메이션으로 접음
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    height: keyboardOpen ? 0 : null,
                    child: _buildCalendar(theme, provider),
                  ),
                ),
                if (!keyboardOpen)
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                // 입력 패널: 나머지 공간 전부 사용
                Expanded(
                  child: _buildInputPanel(theme),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendar(ThemeData theme, DiaryProvider provider) {
    return TableCalendar(
      locale: 'ko_KR',
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now(),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
      onDaySelected: _onDaySelected,
      onPageChanged: _onPageChanged,
      availableGestures: AvailableGestures.horizontalSwipe,
      calendarFormat: CalendarFormat.month,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleMedium!
            .copyWith(fontWeight: FontWeight.bold),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: MLColors.primary,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: MLColors.primary.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        selectedTextStyle: const TextStyle(color: Colors.white),
        markerDecoration: BoxDecoration(
          color: MLColors.mem,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        outsideDaysVisible: false,
      ),
      eventLoader: (day) => provider.hasEntry(day) ? [1] : [],
    );
  }

  Widget _buildInputPanel(ThemeData theme) {
    final dateLabel = _buildDateLabel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  size: 18, color: MLColors.primary),
              const SizedBox(width: 6),
              Text(
                dateLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: MLColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isToday
                ? _buildEditableArea(theme)
                : _buildReadOnlyArea(theme),
          ),
          if (_isToday) _buildActionBar(theme),
        ],
      ),
    );
  }

  Widget _buildEditableArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '오늘 하루를 기록해보세요...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildReadOnlyArea(ThemeData theme) {
    final content = context.watch<DiaryProvider>().selectedContent;
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: content != null && content.isNotEmpty
                ? SingleChildScrollView(
                    child: Text(content, style: theme.textTheme.bodyMedium),
                  )
                : Text(
                    '이 날은 일기를 작성하지 않았어요.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '지난 날짜는 수정할 수 없어요.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    final provider = context.watch<DiaryProvider>();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Opacity(
            opacity: _speechAvailable ? 1.0 : 0.4,
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none_outlined,
                color: _isListening
                    ? Colors.red
                    : theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: _isListening ? '음성 인식 중지' : '음성으로 입력',
              onPressed: _speechAvailable ? _toggleListening : null,
            ),
          ),
          if (_isListening)
            Text(
              '듣고 있어요...',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.red),
            ),
          const Spacer(),
          FilledButton.icon(
            onPressed: provider.isSaving ? null : _saveDiary,
            icon: provider.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: const Text('저장'),
          ),
        ],
      ),
    );
  }

  String _buildDateLabel() {
    final d = _selectedDay;
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[d.weekday - 1];
    final suffix = _isToday ? ' (오늘)' : '';
    return '${d.year}년 ${d.month}월 ${d.day}일 ($weekday)$suffix';
  }
}
