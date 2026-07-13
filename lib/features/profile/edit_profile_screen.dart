import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String? _imagePath;

  // 사진 경로는 계정별로 저장한다 (계정 전환 시 이전 사용자 사진 노출 방지)
  String get _imagePrefKey =>
      'profile_image_path_${context.read<UserProvider>().currentUser?['id']}';

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    final currentName = user.currentUser?['name'] as String?;
    _nameController = TextEditingController(
      text: currentName?.isNotEmpty == true ? currentName : user.currentUser?['username'],
    );
    _ageController = TextEditingController(text: user.age?.toString());
    _weightController = TextEditingController(text: user.weight?.toString());
    _bloodTypeController = TextEditingController(text: user.bloodType);
    _medsController = TextEditingController(text: user.medications);
    _emergencyController = TextEditingController(text: user.emergencyContact);
    _loadImagePath();
  }

  Future<void> _loadImagePath() async {
    final key = _imagePrefKey;
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(key);
    if (path != null && File(path).existsSync()) {
      if (mounted) setState(() => _imagePath = path);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('사진 제거', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, null),
              ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (source == null && _imagePath != null) {
      // 사진 제거
      final key = _imagePrefKey;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      setState(() => _imagePath = null);
      return;
    }
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null || !mounted) return;
    final key = _imagePrefKey;

    // 앱 문서 디렉토리에 복사하여 영구 저장
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(picked.path).copy('${appDir.path}/$fileName');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, saved.path);
    if (mounted) setState(() => _imagePath = saved.path);
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

      await userProvider.updateName(_nameController.text);

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
            // 프로필 이미지
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        _imagePath != null ? FileImage(File(_imagePath!)) : null,
                    child: _imagePath == null
                        ? Icon(Icons.person, size: 52, color: theme.colorScheme.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _pickImage,
                child: const Text('프로필 사진 변경'),
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle(theme, '기본 계정 정보'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: '이름 (화면에 표시될 이름)',
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
