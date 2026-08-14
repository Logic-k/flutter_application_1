import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ml_widgets.dart';
import '../../core/theme.dart';
import 'data/dementia_center_repository.dart';
import 'domain/dementia_center.dart';

/// 치매상담콜센터. 데이터가 없어도 이 번호는 항상 안내한다.
const String _helplineNumber = '1899-9988';

/// 가까운 치매안심센터를 지역으로 찾아 전화·길찾기로 연결한다.
///
/// GPS를 쓰지 않는다. 시도·시군구를 직접 고르게 하므로 위치 권한이 필요 없고,
/// 권한 팝업 없이 첫 화면부터 바로 쓸 수 있다.
class DementiaCenterFinderScreen extends StatefulWidget {
  /// 테스트에서 자산 대신 다른 저장소를 주입하기 위한 통로.
  final DementiaCenterRepository? repository;

  const DementiaCenterFinderScreen({super.key, this.repository});

  @override
  State<DementiaCenterFinderScreen> createState() =>
      _DementiaCenterFinderScreenState();
}

class _DementiaCenterFinderScreenState
    extends State<DementiaCenterFinderScreen> {
  late final DementiaCenterRepository _repository;
  late Future<DementiaCenterData> _future;

  String? _sido;
  String? _sigungu;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DementiaCenterRepository();
    _future = _repository.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가까운 치매안심센터')),
      body: SafeArea(
        child: FutureBuilder<DementiaCenterData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null || !data.isReady) {
              return _UnavailableView(message: data?.message);
            }
            return _buildReady(context, data.centers);
          },
        ),
      ),
    );
  }

  Widget _buildReady(BuildContext context, List<DementiaCenter> centers) {
    final sidoOptions = DementiaCenterRepository.sidoList(centers);
    final sido = _sido ?? sidoOptions.first;
    final sigunguOptions = DementiaCenterRepository.sigunguList(centers, sido);
    final results = DementiaCenterRepository.filter(
      centers,
      sido: sido,
      sigungu: _sigungu,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        const _HelplineCard(),
        const SizedBox(height: 18),
        const MLSectionTitle('지역 선택'),
        _RegionDropdown(
          label: '시 · 도',
          value: sido,
          options: sidoOptions,
          onChanged: (v) => setState(() {
            _sido = v;
            // 시도가 바뀌면 이전 시군구는 더 이상 유효하지 않다.
            _sigungu = null;
          }),
        ),
        const SizedBox(height: 12),
        _RegionDropdown(
          // 시도가 바뀌면 폼 필드를 새로 만들어 이전 시군구 선택이 남지 않게 한다.
          key: ValueKey('sigungu-$sido'),
          label: '시 · 군 · 구',
          value: _sigungu,
          options: sigunguOptions,
          placeholder: '전체',
          onChanged: (v) => setState(() => _sigungu = v),
        ),
        const SizedBox(height: 22),
        MLSectionTitle('검색 결과 ${results.length}곳'),
        if (results.isEmpty)
          const MLCard(
            soft: true,
            child: Text(
              '이 지역의 센터 정보가 아직 없습니다.\n위의 치매상담콜센터로 문의해 주세요.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          )
        else
          ...results.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CenterCard(center: c),
              )),
        const SizedBox(height: 18),
        const _SourceNotice(),
      ],
    );
  }
}

/// 데이터 유무와 무관하게 항상 쓸 수 있는 공식 창구.
class _HelplineCard extends StatelessWidget {
  const _HelplineCard();

  @override
  Widget build(BuildContext context) {
    return MLCard(
      onTap: () => _launch(context, Uri(scheme: 'tel', path: '18999988')),
      child: Row(
        children: [
          const MLIconTile(icon: Icons.support_agent_rounded, color: MLColors.care),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('치매상담콜센터',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('$_helplineNumber · 24시간 상담',
                    style: TextStyle(fontSize: 15, color: MLColors.textSoft)),
              ],
            ),
          ),
          const Icon(Icons.call_rounded, color: MLColors.care),
        ],
      ),
    );
  }
}

class _RegionDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final String? placeholder;
  final ValueChanged<String?> onChanged;

  const _RegionDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.rTile),
        ),
      ),
      style: const TextStyle(fontSize: 17, color: MLColors.text),
      items: [
        if (placeholder != null)
          DropdownMenuItem<String>(value: null, child: Text(placeholder!)),
        ...options.map((o) => DropdownMenuItem<String>(value: o, child: Text(o))),
      ],
      onChanged: onChanged,
    );
  }
}

class _CenterCard extends StatelessWidget {
  final DementiaCenter center;

  const _CenterCard({required this.center});

  @override
  Widget build(BuildContext context) {
    return MLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(center.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(center.fullAddress,
              style: const TextStyle(
                  fontSize: 15, color: MLColors.textSoft, height: 1.45)),
          if (center.hasPhone) ...[
            const SizedBox(height: 4),
            Text(center.phone,
                style: const TextStyle(fontSize: 15, color: MLColors.textSoft)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (center.telUri != null)
                _ActionButton(
                  icon: Icons.call_rounded,
                  label: '전화',
                  color: MLColors.good,
                  onTap: () => _launch(context, center.telUri!),
                ),
              if (center.mapUri != null)
                _ActionButton(
                  icon: Icons.map_rounded,
                  label: '지도',
                  color: MLColors.sky,
                  onTap: () => _launch(context, center.mapUri!),
                ),
              if (center.homepageUri != null)
                _ActionButton(
                  icon: Icons.language_rounded,
                  label: '홈페이지',
                  color: MLColors.primary,
                  onTap: () => _launch(context, center.homepageUri!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.rTile),
          // 고령 사용자를 위해 최소 터치 영역을 48dp 이상으로 유지한다.
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 88),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.rTile),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 7),
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 자산이 없거나 읽지 못했을 때. 사용자를 막다른 곳에 두지 않는다.
class _UnavailableView extends StatelessWidget {
  final String? message;

  const _UnavailableView({this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
      children: [
        const Icon(Icons.location_off_rounded,
            size: 56, color: MLColors.textFaint),
        const SizedBox(height: 16),
        const Text(
          '센터 목록을 불러오지 못했습니다',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          '아래 치매상담콜센터로 전화하시면\n가까운 센터를 안내받으실 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: MLColors.textSoft, height: 1.5),
        ),
        const SizedBox(height: 22),
        const _HelplineCard(),
        if (message != null) ...[
          const SizedBox(height: 22),
          MLCard(
            soft: true,
            child: Text(
              message!,
              style: const TextStyle(fontSize: 13, color: MLColors.textFaint),
            ),
          ),
        ],
      ],
    );
  }
}

/// 공공데이터 출처 표시.
class _SourceNotice extends StatelessWidget {
  const _SourceNotice();

  @override
  Widget build(BuildContext context) {
    // 공공누리 표준 출처표시 문구(kogl.or.kr). 이용허락범위가 '제한 없음'이어도
    // 저작권법 제24조의2 및 공공누리 관례상 출처는 표시한다.
    return const Text(
      "본 저작물은 '국립중앙의료원'에서 작성하여 공공데이터포털로 개방한 "
      "'치매안심센터 정보'를 이용하였으며, 해당 저작물은 공공데이터포털"
      '(www.data.go.kr)에서 무료로 내려받으실 수 있습니다.\n'
      '이 화면은 위치정보를 수집하지 않습니다.',
      style: TextStyle(fontSize: 12.5, color: MLColors.textSoft, height: 1.5),
    );
  }
}

Future<void> _launch(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('연결할 수 있는 앱을 찾지 못했습니다.')),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('연결에 실패했습니다.')),
    );
  }
}
