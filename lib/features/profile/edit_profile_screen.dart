import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _medsController;
  late TextEditingController _emergencyController;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _nameController = TextEditingController(text: user.currentUser?['username']);
    _ageController = TextEditingController(text: user.age?.toString());
    _weightController = TextEditingController(text: user.weight?.toString());
    _bloodTypeController = TextEditingController(text: user.bloodType);
    _medsController = TextEditingController(text: user.medications);
    _emergencyController = TextEditingController(text: user.emergencyContact);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _bloodTypeController.dispose();
    _medsController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = context.read<UserProvider>();
      
      // Update username if changed
      if (_nameController.text != userProvider.currentUser?['username']) {
        await userProvider.updateUsername(_nameController.text);
      }

      // Update other medical info
      await userProvider.updateMedicalInfo(
        age: int.tryParse(_ageController.text),
        weight: double.tryParse(_weightController.text),
        bloodType: _bloodTypeController.text,
        medications: _medsController.text,
        emergencyContact: _emergencyController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정보가 성공적으로 업데이트되었습니다.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('정보 수정'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildSectionTitle(theme, '기본 계정 정보'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: '사용자 이름',
              icon: Icons.person_outline,
              validator: (value) => (value == null || value.isEmpty) ? '이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 32),

            _buildSectionTitle(theme, '생체 및 의료 정보'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ageController,
                    label: '나이 (세)',
                    keyboardType: TextInputType.number,
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: '몸무게 (kg)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    icon: Icons.monitor_weight_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bloodTypeController,
              label: '혈액형',
              icon: Icons.bloodtype_outlined,
              hint: 'A+, B-, AB+ 등',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _medsController,
              label: '복용 중인 약물',
              icon: Icons.medical_services_outlined,
              hint: '혈압약, 당뇨약 등',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emergencyController,
              label: '비상 연락처',
              icon: Icons.phone_outlined,
              hint: '보호자 성함 및 연락처',
            ),
            const SizedBox(height: 40),
            
            FilledButton(
              onPressed: _save,
              child: const Text('수정 완료'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
