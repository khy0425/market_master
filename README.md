# Market Master

마켓 관리자를 위한 웹 기반 상품 관리 시스템

## 기능

- 상품 관리
  - 상품 등록/수정/삭제
  - 이미지 업로드 (JPEG, PNG, GIF 지원)
  - 엑셀 일괄 등록
  - 실시간 검색
  - 재고 관리

- 관리자 시스템
  - 권한 기반 접근 제어 (SUPER_ADMIN, ADMIN, MANAGER)
  - 관리자 계정 관리
  - 활동 로그 기록

## 기술 스택

- Frontend
  - Flutter Web
  - Flutter Riverpod (상태 관리)
  - Cached Network Image (이미지 캐싱)

- Backend
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Hosting

## 설치 및 실행

1. 필수 요구사항:
   - Flutter SDK (^3.6.0)
   - Firebase CLI
   - Google Cloud SDK

2. 프로젝트 설정:
```bash
# 의존성 설치
flutter pub get

# Firebase 초기화
firebase init

# CORS 설정 (Google Cloud SDK 필요)
gsutil cors set cors.json gs://[YOUR-STORAGE-BUCKET]
```

3. 환경 변수 설정:
   - `.env` 파일 생성 (`.env.example` 참고)
   - Firebase 설정 추가

4. 실행:
```bash
flutter run -d chrome
```

## 프로젝트 구조

```
lib/
  ├── models/          # 데이터 모델
  ├── services/        # Firebase 서비스
  ├── providers/       # Riverpod 프로바이더
  ├── views/           # UI 화면
  ├── widgets/         # 재사용 위젯
  └── utils/          # 유틸리티 함수
```

## 보안 설정

### Firebase Storage Rules
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null
        && request.resource.size < 10 * 1024 * 1024
        && (
          request.resource.contentType == 'image/jpeg' ||
          request.resource.contentType == 'image/png' ||
          request.resource.contentType == 'image/gif'
        )
    }
  }
}
```

### CORS 설정
```json
// cors.json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": [
      "Origin",
      "X-Requested-With",
      "Content-Type",
      "Accept",
      "Access-Control-Allow-Origin",
      "Access-Control-Allow-Methods",
      "Access-Control-Allow-Headers",
      "Content-Length",
      "Content-Range",
      "Cache-Control",
      "ETag",
      "Pragma",
      "x-goog-*"
    ]
  }
]
```

## 이미지 처리

- 지원 형식: JPEG, PNG, GIF
- 최대 파일 크기: 10MB
- 이미지 캐싱 및 최적화
- CORS 설정으로 크로스 도메인 이슈 해결

## 라이선스

MIT License

## 기여

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
