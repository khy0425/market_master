import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tier_settings.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 등급 설정 가져오기
  Stream<TierSettings> getTierSettings() {
    return _firestore
        .collection('settings')
        .doc('tiers')
        .snapshots()
        .map((doc) => TierSettings.fromMap(doc.data() ?? {}));
  }

  // 등급 설정 업데이트
  Future<void> updateTierSettings(TierSettings settings) async {
    await _firestore
        .collection('settings')
        .doc('tiers')
        .set(settings.toMap());
  }
} 