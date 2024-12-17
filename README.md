# Market Master

Flutter와 Firebase를 사용한 쇼핑몰 관리자 페이지입니다.

## 프로젝트 개요

Firebase Firestore와 Flutter를 사용하여 개발된 쇼핑몰 관리 시스템입니다. 
Windows를 기본 플랫폼으로 하되, 크로스 플랫폼 지원이 가능한 관리자 솔루션입니다.

### 주요 기능

- 주문 관리
  - 주문 목록 조회
  - 주문 상태 관리
  - 배송 상태 추적
  
- 재고 관리
  - 상품 등록/수정/삭제
  - 재고 수량 관리
  - 카테고리 관리
  
- 고객 관리
  - 회원 목록 조회
  - 주문 이력 관리
  - 고객 정보 관리
  
- 매출 분석
  - 일별/월별 매출 통계
  - 상품별 판매 분석
  - 카테고리별 매출 현황

## 기술 스택

- **Frontend**
  - Flutter 3.x
  - Riverpod (상태 관리)
  - Material Design 3
  
- **Backend**
  - Firebase Services
    - Firestore (데이터베이스)
    - Authentication (인증)
    - Storage (파일 저장)
    - Cloud Messaging (알림)
    
- **Architecture**
  - MVVM 패턴
  - Clean Architecture

## 프로젝트 구조
lib/
│-- main.dart
│-- models/
│ ├── product.dart
│ ├── user.dart
│ └── order.dart
│-- viewmodels/
│ ├── product_viewmodel.dart
│ ├── user_viewmodel.dart
│ └── order_viewmodel.dart
│-- services/
│ └── firestore_service.dart
│-- views/
│ ├── order_management/
│ │ ├── orders_list_view.dart
│ │ └── order_detail_view.dart
│ ├── inventory_management/
│ │ ├── products_list_view.dart
│ │ └── product_edit_view.dart
│ ├── customer_management/
│ │ └── customers_list_view.dart
│ └── analytics/
│ └── analytics_dashboard_view.dart
│-- widgets/
│-- utils/


## 설치 및 실행

### 1. 필요 조건

- Flutter SDK (3.x 이상)
- Firebase 프로젝트
- IDE (Android Studio 또는 VS Code)
- Git

### 2. 프로젝트 설정

```bash
# 저장소 클론
git clone https://github.com/khy0425/market_master.git

# 프로젝트 디렉토리로 이동
cd market_master

# 의존성 설치
flutter pub get
```

### 3. Firebase 설정

1. [Firebase Console](https://console.firebase.google.com/)에서 새 프로젝트 생성
2. Flutter 앱 등록 (패키지명: com.example.market_master)
3. 설정 파일 다운로드
   - Android: google-services.json
   - iOS: GoogleService-Info.plist
4. 설정 파일을 프로젝트의 적절한 위치에 복사
5. Firebase SDK 초기화 코드 추가

### 4. 실행

```bash
# 디버그 모드로 실행
flutter run

# 릴리즈 모드로 실행
flutter run --release
```

## 개발 가이드

- 코드 스타일: [Effective Dart](https://dart.dev/guides/language/effective-dart) 준수
- 커밋 메시지: [Conventional Commits](https://www.conventionalcommits.org/) 형식 사용
- 문서화: 모든 public API에 dartdoc 주석 필수

## 라이선스

MIT License

Copyright (c) 2024 khy0425

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
