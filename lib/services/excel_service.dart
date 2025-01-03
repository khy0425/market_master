import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:market_master/services/storage_service.dart';
import '../models/product.dart';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';

class ExcelService {
  /// 엑셀 파일에서 상품 데이터 추출
  static Future<List<Map<String, dynamic>>> parseProductExcel(Uint8List bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      final products = <Map<String, dynamic>>[];
      bool isFirstRow = true;
      
      for (var row in sheet!.rows) {
        if (isFirstRow) {
          isFirstRow = false;
          continue;
        }
        
        if (row.isEmpty || row[0]?.value == null) continue;

        try {
          final productCode = row[0]?.value?.toString() ?? '';
          
          // 이미지 데이터 추출
          final mainImageBytes = row[8]?.value as Uint8List?;
          final detailImageBytes = row[9]?.value as Uint8List?;
          
          // 이미지 파일명 생성 (상품코드 활용)
          String mainImageUrl = '';
          String detailImageUrl = '';
          
          if (mainImageBytes != null) {
            final fileName = '${productCode}_main.jpg';  // 상품코드로 파일명 지정
            mainImageUrl = await _uploadImageToStorage(mainImageBytes, fileName);
          }
          
          if (detailImageBytes != null) {
            final fileName = '${productCode}_detail.jpg';  // 상품코드로 파일명 지정
            detailImageUrl = await _uploadImageToStorage(detailImageBytes, fileName);
          }

          products.add({
            'productCode': productCode,
            'name': row[1]?.value?.toString() ?? '',
            'description': row[2]?.value?.toString() ?? '',
            'originalPrice': int.tryParse(row[3]?.value?.toString() ?? '0') ?? 0,
            'sellingPrice': int.tryParse(row[4]?.value?.toString() ?? '0') ?? 0,
            'mainCategory': row[5]?.value?.toString() ?? '',
            'subCategory': row[6]?.value?.toString() ?? '',
            'stockQuantity': int.tryParse(row[7]?.value?.toString() ?? '0') ?? 0,
            'productImageUrl': mainImageUrl,
            'productDetailImage': detailImageUrl,
            'isActive': true,
            'createdAt': DateTime.now(),
          });
        } catch (e) {
          developer.log('Error processing row', error: e, name: 'ExcelService');
          throw Exception('상품 데이터 처리 중 오류: $e');
        }
      }
      
      return products;
    } catch (e) {
      developer.log('Error parsing excel file', error: e, name: 'ExcelService');
      rethrow;
    }
  }

  static Future<String> _uploadImageToStorage(Uint8List bytes, String fileName) async {
    try {
      final storageService = StorageService();
      final downloadUrl = await storageService.uploadImage(
        'products',
        bytes,
        fileName,
      );
      
      if (downloadUrl == null) {
        throw Exception('이미지 업로드 실패');
      }
      
      return downloadUrl;
    } catch (e) {
      developer.log('Error uploading image', error: e, name: 'ExcelService');
      rethrow;
    }
  }

  /// 샘플 엑셀 파일 생성
  static Uint8List generateSampleExcel() {
    final excel = Excel.createExcel();
    
    // 기본 Sheet1 삭제
    excel.delete('Sheet1');
    
    // 상품목록 시트 생성
    final sheet = excel['상품목록'];

    // 열 너비 설정
    sheet.setColumnWidth(0, 15.0);  // 상품코드
    sheet.setColumnWidth(1, 30.0);  // 상품명
    sheet.setColumnWidth(2, 50.0);  // 상품설명
    sheet.setColumnWidth(3, 15.0);  // 정가
    sheet.setColumnWidth(4, 15.0);  // 판매가
    sheet.setColumnWidth(5, 15.0);  // 대분류
    sheet.setColumnWidth(6, 15.0);  // 소분류
    sheet.setColumnWidth(7, 15.0);  // 재고수량
    sheet.setColumnWidth(8, 20.0);  // 대표이미지
    sheet.setColumnWidth(9, 20.0);  // 상세이미지

    // 헤더 스타일 설정
    final headerStyle = CellStyle(
      bold: true,                    // 굵은 글씨
      horizontalAlign: HorizontalAlign.Center,  // 가운데 정렬
      verticalAlign: VerticalAlign.Center,      // 세로 가운데 정렬
      textWrapping: TextWrapping.WrapText,      // 텍스트 줄바꿈
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // 설명행 스타일 설정
    final descStyle = CellStyle(
      italic: true,                  // 이탤릭체
      horizontalAlign: HorizontalAlign.Left,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // 샘플 데이터 스타일 설정
    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // 헤더 행 추가
    final headers = [
      '상품코드',
      '상품명',
      '상품설명',
      '정가',
      '판매가',
      '메인 카테고리',
      '서브 카테고리',
      '재고수량',
      '대표이미지',
      '상세이미지',
    ];

    // 헤더 행 추가 및 스타일 적용
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 필수 여부 행 추가
    final requirements = [
      '(필수)',
      '(필수)',
      '(필수)',
      '(필수/숫자)',
      '(필수/숫자)',
      '(필수)',
      '(필수)',
      '(필수/숫자)',
      '(선택/이미지)',
      '(선택/이미지)',
    ];

    // 필수 여부 행 추가 및 스타일 적용
    for (var i = 0; i < requirements.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = TextCellValue(requirements[i]);
      cell.cellStyle = descStyle;
    }

    // 설명 행 추가
    final descriptions = [
      '고유한 상품코드',
      '상품의 이름',
      '상품에 대한 상세 설명',
      '상품의 원래 가격',
      '실제 판매 가격',
      '예: 아우터, 상의, 하의',
      '예: 후드, 맨투맨, 니트',
      '현재 재고 수량',
      '상품 대표 이미지',
      '상품 상세 이미지',
    ];

    // 설명 행 추가 및 스타일 적용
    for (var i = 0; i < descriptions.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
      cell.value = TextCellValue(descriptions[i]);
      cell.cellStyle = descStyle;
    }

    // 샘플 데이터 추가
    final sampleData = [
      ['P001', '프리미엄 면티', '부드러운 면 소재의 프리미엄 티셔츠입니다.', '30000', '25000', '상의', '반소매티셔츠', '100', '', ''],
      ['P002', '캐주얼 청바지', '편안한 착용감의 일자 청바지입니다.', '45000', '35000', '하의', '롱팬츠', '50', '', ''],
    ];

    // 샘플 데이터 행 추가 및 스타일 적용
    for (var rowIndex = 0; rowIndex < sampleData.length; rowIndex++) {
      for (var colIndex = 0; colIndex < sampleData[rowIndex].length; colIndex++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: colIndex,
          rowIndex: rowIndex + 3,  // 헤더, 필수, 설명 행 다음부터
        ));
        cell.value = TextCellValue(sampleData[rowIndex][colIndex]);
        cell.cellStyle = dataStyle;
      }
    }

    // 첫 번째 행 높이 설정
    sheet.setRowHeight(0, 30);

    return Uint8List.fromList(excel.encode()!);
  }
} 