# Market Master 관리자 시스템

## 1. 권한 체계

### 권한 레벨
- `SUPER_ADMIN`: 최고 관리자 (전체 시스템 관리)
- `ADMIN`: 일반 관리자 (일반 관리 기능)
- `MANAGER`: 매니저 (제한된 권한)

### 권한별 기능
- SUPER_ADMIN
  - 관리자 계정 생성/수정/삭제
  - 권한 레벨 변경
  - 계정 활성화/비활성화
  
- ADMIN
  - 상품 관리
  - 주문 관리
  - 고객 관리
  
- MANAGER
  - 기본 운영 기능
  - 조회 권한

## 2. 보안 기능

### 계정 관리
- 첫 번째 가입자 자동 SUPER_ADMIN 지정
- 이메일 중복 확인
- 비밀번호 유효성 검사
- 계정 활성화 상태 관리

### 로그 기록
- 로그인/로그아웃 기록
- 권한 변경 이력
- 계정 상태 변경 추적

## 3. 데이터 구조

### Firestore 컬렉션
```javascript
admins/
  {adminId}/
    email: string
    displayName: string
    role: string ('super_admin' | 'admin' | 'manager')
    isActive: boolean
    createdAt: timestamp
    updatedAt: timestamp
    updatedBy: string
    deactivatedAt: timestamp?
    deactivatedBy: string?
```

## 4. 주요 ���능

### 인증
- 이메일/비밀번호 로그인
- 관리자 권한 확인
- 자동 로그아웃 (비활성 계정)

### 관리자 관리
- 새 관리자 등록
- 권한 수정
- 계정 비활성화
- 관리자 목록 조회

## 5. UI 구성

### 로그인 화면
- 이메일/비밀번호 입력
- 에러 메시지 표시
- 로딩 상태 표시

### 관리자 관리 화면
- 관리자 목록 표시
- 권한 수정 다이얼로그
- 계정 활성화 토글
- 새 관리자 추가 폼

## 6. 보안 고려사항

- 공개 회원가입 비활성화
- SUPER_ADMIN만 관리자 추가 가능
- 권한 변경 시 현재 사용자 권한 확인
- 비활성화된 계정 자동 로그아웃 