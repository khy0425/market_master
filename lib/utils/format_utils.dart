import 'package:intl/intl.dart';

class FormatUtils {
  static final _numberFormat = NumberFormat('#,###');
  
  static String formatPrice(int price) {
    return '${_numberFormat.format(price)}원';
  }
  
  // 할인율 등 다른 숫자 포맷팅이 필요한 경우를 위해
  static String formatNumber(int number) {
    return _numberFormat.format(number);
  }
} 