class MemoPermission {
  final bool canCreate;    // 메모 작성 권한
  final bool canEdit;      // 메모 수정 권한
  final bool canDelete;    // 메모 삭제 권한
  final bool canViewAll;   // 전체 메모 조회 권한
  final bool canViewPrivate; // 개인메모 조회 권한

  const MemoPermission({
    this.canCreate = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canViewAll = false,
    this.canViewPrivate = false,
  });

  factory MemoPermission.admin() {
    return const MemoPermission(
      canCreate: true,
      canEdit: true,
      canDelete: true,
      canViewAll: true,
      canViewPrivate: true,
    );
  }

  factory MemoPermission.staff() {
    return const MemoPermission(
      canCreate: true,
      canEdit: false,
      canDelete: false,
      canViewAll: true,
      canViewPrivate: false,
    );
  }
} 