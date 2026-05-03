import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _consentPersonal = false;
  bool _consentHealth = false;
  bool _consentGuardian = false;

  bool get _isAllRequiredChecked => _consentPersonal && _consentHealth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보 동의')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '서비스 이용을 위해\n필수 동의가 필요합니다.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildConsentItem(
              '개인정보 처리 동의 (필수)',
              _consentPersonal,
              (val) => setState(() => _consentPersonal = val!),
            ),
            _buildConsentItem(
              '건강정보 취급 동의 (필수)',
              _consentHealth,
              (val) => setState(() => _consentHealth = val!),
            ),
            _buildConsentItem(
              '보호자 데이터 공유 (선택)',
              _consentGuardian,
              (val) => setState(() => _consentGuardian = val!),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _isAllRequiredChecked
                  ? () {
                      context.read<UserProvider>().setConsent(true);
                      context.push('/onboarding');
                    }
                  : null,
              child: const Text('다음으로'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentItem(String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
