import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(String path, Uint8List fileBytes, String fileName) async {
    try {
      // 파일 확장자 확인
      final ext = fileName.split('.').last.toLowerCase();
      final isValidExt = ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
      if (!isValidExt) {
        throw Exception('지원하지 않는 파일 형식입니다. (jpg, jpeg, png, gif만 가능)');
      }

      // 파일 크기 확인 (10MB 제한)
      if (fileBytes.length > 10 * 1024 * 1024) {
        throw Exception('파일 크기는 10MB를 초과할 수 없습니다.');
      }

      // 파일 타입에 따른 contentType 설정
      String contentType;
      switch (ext) {
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        default:
          contentType = 'image/jpeg';
      }

      final ref = _storage.ref().child('$path/$fileName');
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'picked-file-path': fileName,
          'original-extension': ext,
        },
      );

      // 파일 업로드
      final uploadTask = ref.putData(fileBytes, metadata);
      
      // 업로드 진행상황 모니터링
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        developer.log(
          'Upload progress: ${progress.toStringAsFixed(2)}%',
          name: 'StorageService',
        );
      });

      // 업로드 완료 대기
      await uploadTask;
      
      // 다운로드 URL 반환
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      developer.log(
        'Error uploading image',
        error: e,
        name: 'StorageService',
      );
      rethrow;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      developer.log(
        'Error deleting image',
        error: e,
        name: 'StorageService',
      );
      return false;
    }
  }
} 