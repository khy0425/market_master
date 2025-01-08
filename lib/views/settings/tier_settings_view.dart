import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tier_settings.dart';
import '../../providers/providers.dart';
import '../../utils/customer_utils.dart';

class TierSettingsView extends ConsumerStatefulWidget {
  const TierSettingsView({super.key});

  @override
  ConsumerState<TierSettingsView> createState() => _TierSettingsViewState();
}

class _TierSettingsViewState extends ConsumerState<TierSettingsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vvipController;
  late TextEditingController _vipController;
  late TextEditingController _goldController;

  @override
  void initState() {
    super.initState();
    _vvipController = TextEditingController();
    _vipController = TextEditingController();
    _goldController = TextEditingController();
  }

  @override
  void dispose() {
    _vvipController.dispose();
    _vipController.dispose();
    _goldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsyncValue = ref.watch(tierSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP 등급 설정'),
      ),
      body: settingsAsyncValue.when(
        data: (settings) {
          _vvipController.text = settings.vvipThreshold.toString();
          _vipController.text = settings.vipThreshold.toString();
          _goldController.text = settings.goldThreshold.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTierSettingField(
                    'VVIP 기준금액',
                    _vvipController,
                    '100만원 이상 추천',
                  ),
                  const SizedBox(height: 16),
                  _buildTierSettingField(
                    'VIP 기준금액',
                    _vipController,
                    '50만원 이상 추천',
                  ),
                  const SizedBox(height: 16),
                  _buildTierSettingField(
                    'GOLD 기준금액',
                    _goldController,
                    '20만원 이상 추천',
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('설정 저장'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류 발생: $error')),
      ),
    );
  }

  Widget _buildTierSettingField(
    String label,
    TextEditingController controller,
    String helperText,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixText: '₩',
        suffixText: '원',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '금액을 입력하세요';
        }
        final amount = int.tryParse(value);
        if (amount == null || amount <= 0) {
          return '올바른 금액을 입력하세요';
        }
        return null;
      },
    );
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final settings = TierSettings(
        vvipThreshold: int.parse(_vvipController.text),
        vipThreshold: int.parse(_vipController.text),
        goldThreshold: int.parse(_goldController.text),
      );

      await ref.read(settingsServiceProvider).updateTierSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정이 저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }
} 