import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/excel_service.dart';
import '../services/product_service.dart';
import '../providers/providers.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

class ExcelUploadWidget extends ConsumerStatefulWidget {
  const ExcelUploadWidget({super.key});

  @override
  ConsumerState<ExcelUploadWidget> createState() => _ExcelUploadWidgetState();
}

class _ExcelUploadWidgetState extends ConsumerState<ExcelUploadWidget> {
  bool _isLoading = false;

  Future<void> _uploadExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isLoading = true);

      final bytes = result.files.first.bytes!;
      final products = await ExcelService.parseProductExcel(bytes);
      
      final (success, failed, errors) = 
          await ref.read(productServiceProvider).addProductsBatch(products);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '상품 등록 완료\n'
              '성공: $success개\n'
              '실패: $failed개'
            ),
            duration: const Duration(seconds: 5),
            action: errors.isNotEmpty
                ? SnackBarAction(
                    label: '오류 보기',
                    onPressed: () => _showErrorDialog(errors),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('엑셀 파일 처리 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadSample() async {
    try {
      final bytes = ExcelService.generateSampleExcel();
      
      // 웹에서 파일 다운로드
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '상품등록_양식.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('엑셀 양식 파일이 다운로드되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('샘플 파일 생성 실패: $e')),
        );
      }
    }
  }

  void _showErrorDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('등록 실패 상품 목록'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: errors.map((e) => Text(e)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('엑셀 파일로 상품 일괄 등록'),
          subtitle: const Text('엑셀 파일을 업로드하여 여러 상품을 한 번에 등록할 수 있습니다.'),
          trailing: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                )
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _isLoading ? null : _uploadExcel,
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('파일 처리 중...'),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.download_rounded, color: Colors.green),
          title: const Text('상품 등록 예시 파일 다운로드'),
          subtitle: const Text(
            '올바른 형식으로 상품을 등록하기 위한 예시 파일입니다.\n'
            '※ 대표이미지와 상세이미지는 선택사항이며, 상품코드는 고유해야 합니다.',
          ),
          isThreeLine: true,
          trailing: ElevatedButton.icon(
            icon: const Icon(Icons.file_download),
            label: const Text('예시 파일'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: _downloadSample,
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '엑셀 파일 작성 시 주의사항',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• 첫 번째 행(헤더)은 수정하지 마세요'),
                  Text('• 필수 항목은 반드시 입력해야 합니다'),
                  Text('• 가격과 재고는 숫자만 입력 가능합니다'),
                  Text('• 이미지는 10MB 이하의 JPG, PNG, GIF 파일만 가능합니다'),
                  Text('• 대량 등록 시 시간이 다소 소요될 수 있습니다'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
} 