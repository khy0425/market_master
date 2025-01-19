import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tier_settings.dart';

class SettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 등급 설정 가져오기
  Stream<TierSettings> getTierSettings() {
    print('getTierSettings 호출');
    return _db
        .collection('settings')
        .doc('tiers')
        .snapshots()
        .map((doc) {
          final data = doc.data();
          print('Tier 설정 문서: $data');
          
          if (!doc.exists || data == null) {
            print('Tier 설정 문서 없음, 문서 생성 필요');
            _createDefaultTierSettings();  // 기본값으로 문서 생성
            throw Exception('등급 설정이 없습니다. 기본값으로 생성됩니다.');
          }

          return TierSettings(
            vvipThreshold: data['vvipThreshold'] as int? ?? 1000000,
            vipThreshold: data['vipThreshold'] as int? ?? 200000,
            goldThreshold: data['goldThreshold'] as int? ?? 50000,
          );
        });
  }

  // 기본 등급 설정 생성
  Future<void> _createDefaultTierSettings() async {
    try {
      final defaultSettings = {
        'vvipThreshold': 1000000,
        'vipThreshold': 200000,
        'goldThreshold': 50000,
      };
      
      await _db.collection('settings').doc('tiers').set(defaultSettings);
      print('기본 Tier 설정 생성 완료');
    } catch (e) {
      print('기본 Tier 설정 생성 실패: $e');
      rethrow;
    }
  }

  // 등급 설정 업데이트
  Future<void> updateTierSettings(TierSettings settings) async {
    print('updateTierSettings 호출: ${settings.toMap()}');
    try {
      await _db.collection('settings').doc('tiers').set({
        'vvipThreshold': settings.vvipThreshold,
        'vipThreshold': settings.vipThreshold,
        'goldThreshold': settings.goldThreshold,
      });
      print('Tier 설정 업데이트 성공');
    } catch (e) {
      print('Tier 설정 업데이트 실패: $e');
      rethrow;
    }
  }
} 