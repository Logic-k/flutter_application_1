import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/ai/model_download_service.dart';
import '../../core/ai/ai_chat_service.dart';
import '../../core/ai/gemma_local_provider.dart';
import '../../core/theme.dart';

enum _DownloadState { idle, downloading, done, error }

class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  _DownloadState _state = _DownloadState.idle;
  double _progress = 0.0;
  String _errorMessage = '';
  bool _modelExists = false;
  bool _obscureToken = true;

  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final exists = await ModelDownloadService.isModelReady();
    final saved = await ModelDownloadService.getSavedToken();
    if (mounted) {
      setState(() {
        _modelExists = exists;
        if (saved != null) _tokenController.text = saved;
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HuggingFace 토큰을 입력해 주세요.')),
      );
      return;
    }

    await ModelDownloadService.saveToken(token);
    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0.0;
      _errorMessage = '';
    });

    try {
      await ModelDownloadService.downloadModel(
        hfToken: token,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      await AiChatService.setProvider(GemmaLocalProvider());
      if (mounted) {
        setState(() {
          _state = _DownloadState.done;
          _modelExists = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _DownloadState.error;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _deleteModel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모델 삭제'),
        content: const Text(
          '온디바이스 AI 모델을 삭제하시겠습니까?\n삭제 후 Gemini API 또는 오프라인 모드로 전환됩니다.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ModelDownloadService.deleteModel();
    await AiChatService.initialize();
    if (mounted) {
      setState(() {
        _modelExists = false;
        _state = _DownloadState.idle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('온디바이스 AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 모델 소개 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MLColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.memory_rounded, color: MLColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Text('Gemma 온디바이스 AI',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: MLColors.primary,
                        )),
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    '인터넷 없이도 AI 대화를 이용할 수 있습니다.\n모델 크기는 약 1.5GB이며, 최초 1회 다운로드가 필요합니다.',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 모델: Gemma 1.1 2B IT GPU INT4\n'
                    '• 우선순위: 온디바이스 > Gemini API > 오프라인\n'
                    '• 필요 저장공간: 약 1.5GB',
                    style: TextStyle(fontSize: 13, color: MLColors.textSoft, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_modelExists) ...[
              _buildStatusChip(Icons.check_circle_rounded, '온디바이스 AI 활성화됨', Colors.green),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _deleteModel,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('모델 삭제', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else ...[
              // 토큰 안내
              Text('HuggingFace 토큰 필요',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Gemma 모델은 Google 이용 약관 동의 후 다운로드할 수 있습니다.\n아래 순서를 따라 토큰을 발급받으세요.',
                style: TextStyle(fontSize: 13, color: MLColors.textSoft, height: 1.6),
              ),
              const SizedBox(height: 12),
              _buildStep('1', '아래 버튼으로 HuggingFace 약관 동의 페이지 이동'),
              _buildStep('2', '로그인 후 "Agree and access repository" 클릭'),
              _buildStep('3', 'HuggingFace → Settings → Access Tokens → New Token 발급'),
              _buildStep('4', '발급된 토큰을 아래에 붙여넣고 다운로드'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://huggingface.co/google/gemma-1.1-2b-it'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('HuggingFace 약관 동의 페이지 열기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MLColors.primary,
                    side: const BorderSide(color: MLColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 토큰 입력
              TextField(
                controller: _tokenController,
                obscureText: _obscureToken,
                decoration: InputDecoration(
                  labelText: 'HuggingFace Access Token',
                  hintText: 'hf_xxxxxxxxxxxxxxxxxxxx',
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureToken ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureToken = !_obscureToken),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              if (_state == _DownloadState.downloading) ...[
                _buildStatusChip(Icons.download_rounded, '다운로드 중...', MLColors.primary),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: MLColors.primarySoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(MLColors.primary),
                ),
                const SizedBox(height: 6),
                Text('${(_progress * 100).toStringAsFixed(1)}% 완료',
                    style: const TextStyle(color: MLColors.textSoft, fontSize: 13)),
              ] else ...[
                if (_state == _DownloadState.error) ...[
                  _buildStatusChip(Icons.error_outline, '다운로드 실패', Colors.red),
                  const SizedBox(height: 6),
                  Text(_errorMessage,
                      style: const TextStyle(fontSize: 12, color: Colors.red, height: 1.5)),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _state == _DownloadState.downloading ? null : _startDownload,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('모델 다운로드 시작 (~1.5GB)',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
            const Text(
              '※ 모델은 Google Gemma 라이선스 조건에 따라 제공됩니다.\n'
              '다운로드 시 해당 약관에 동의하는 것으로 간주됩니다.',
              style: TextStyle(fontSize: 11, color: MLColors.textFaint, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
    ]);
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 8, top: 1),
            decoration: const BoxDecoration(color: MLColors.primarySoft, shape: BoxShape.circle),
            child: Text(number,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MLColors.primary)),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }
}
