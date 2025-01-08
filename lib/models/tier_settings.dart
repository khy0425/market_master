class TierSettings {
  final int vvipThreshold;  // VVIP 기준금액
  final int vipThreshold;   // VIP 기준금액
  final int goldThreshold;  // GOLD 기준금액

  const TierSettings({
    required this.vvipThreshold,
    required this.vipThreshold,
    required this.goldThreshold,
  });

  factory TierSettings.fromMap(Map<String, dynamic> map) {
    return TierSettings(
      vvipThreshold: map['vvipThreshold'] ?? 1000000,
      vipThreshold: map['vipThreshold'] ?? 500000,
      goldThreshold: map['goldThreshold'] ?? 200000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vvipThreshold': vvipThreshold,
      'vipThreshold': vipThreshold,
      'goldThreshold': goldThreshold,
    };
  }
} 