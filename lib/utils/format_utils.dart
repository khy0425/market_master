import 'package:intl/intl.dart';

class FormatUtils {
  static final _numberFormat = NumberFormat('#,###');
  static final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  
  static String formatPrice(int price) {
    return '${_numberFormat.format(price)}원';
  }
  
  // 할인율 등 다른 숫자 포맷팅이 필요한 경우를 위해
  static String formatNumber(int number) {
    return _numberFormat.format(number);
  }

  // 날짜/시간 포맷 메서드 추가
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
} 