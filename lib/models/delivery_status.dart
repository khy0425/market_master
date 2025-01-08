/// 배송 상태를 나타내는 열거형
enum DeliveryStatus {
  waiting('waiting', '결제대기'),
  confirmed('confirmed', '결제완료'),
  preparing('preparing', '배송준비'),
  shipping('shipping', '배송중'),
  delivered('delivered', '배송완료'),
  cancelled('cancelled', '취소/반품');

  final String code;
  final String text;
  const DeliveryStatus(this.code, this.text);

  static DeliveryStatus fromCode(String code) {
    return DeliveryStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => DeliveryStatus.waiting,
    );
  }
} 