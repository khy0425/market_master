class ErrorUtils {
  static String getErrorMessage(dynamic error) {
    if (error.toString().contains('permission-denied')) {
      return '권한이 없습니다';
    }
    // ... 기타 공통 에러 처리
    return '오류가 발생했습니다';
  }
} 