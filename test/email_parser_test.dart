import 'package:flutter_test/flutter_test.dart';
import 'package:a_management/services/email_parser_service.dart';

void main() {
  group('EmailParserService Tests', () {
    test('Vietcombank - Expense transaction', () {
      const body = 'VCB Digibank: Tai khoan 1012345678 thay doi -250,000 VND vao luc 15/06/2026 12:15:30. ND: Thanh toan don hang Shopee 23412356';
      final parsed = EmailParserService.parse(
        'no-reply@vietcombank.com.vn',
        'VCB Digibank - Thong bao bien dong so du',
        body,
      );

      expect(parsed, isNotNull);
      expect(parsed!.title, 'Vietcombank Transaction');
      expect(parsed.isExpense, true);
      // 250,000 VND / 25,000 = 10.0 USD
      expect(parsed.amount, 10.0);
      expect(parsed.description, 'Thanh toan don hang shopee 23412356');
      expect(parsed.category, 'Groceries'); // shopee maps to Groceries
      expect(parsed.time, '12:15');
      expect(parsed.date.day, 15);
      expect(parsed.date.month, 6);
      expect(parsed.date.year, 2026);
    });

    test('Vietcombank - Income transaction', () {
      const body = 'VCB Digibank: Tai khoan 1012345678 thay doi +15,000,000 VND vao luc 15/06/2026 08:30:00. ND: Cong ty Tra luong thang 06';
      final parsed = EmailParserService.parse(
        'no-reply@vietcombank.com.vn',
        'VCB Digibank - Thong bao bien dong so du',
        body,
      );

      expect(parsed, isNotNull);
      expect(parsed!.isExpense, false);
      // 15,000,000 VND / 25,000 = 600.0 USD
      expect(parsed.amount, 600.0);
      expect(parsed.description, 'Cong ty tra luong thang 06');
      expect(parsed.category, 'Salary');
    });

    test('TPBank - Expense transaction', () {
      const body = 'So tien GD: -65,000 VND luc 15/06/2026 07:45:00. Tai khoan GD: 0998877665. Noi dung: Thanh toan an sang cafe Highlands';
      final parsed = EmailParserService.parse(
        'ebank@tpb.com.vn',
        'TPBank - Thong bao bien dong so du tai khoan',
        body,
      );

      expect(parsed, isNotNull);
      expect(parsed!.title, 'TPBank Transaction');
      expect(parsed.isExpense, true);
      // 65,000 VND / 25,000 = 2.6 USD
      expect(parsed.amount, 2.6);
      expect(parsed.category, 'Food'); // cafe/Highlands maps to Food
      expect(parsed.time, '07:45');
    });

    test('Techcombank - Expense transaction', () {
      const body = 'Giao dich Techcombank: TK 190876543210 -350,000 VND luc 15/06/2026 14:00:25. ND: Thanh toan tien dien sinh hoat thang 05';
      final parsed = EmailParserService.parse(
        'no-reply@techcombank.com.vn',
        'Thong bao giao dich Techcombank',
        body,
      );

      expect(parsed, isNotNull);
      expect(parsed!.title, 'Techcombank Transaction');
      expect(parsed.isExpense, true);
      // 350,000 VND / 25,000 = 14.0 USD
      expect(parsed.amount, 14.0);
      expect(parsed.time, '14:00');
    });

    test('Filter Google Security Alert - Should return null', () {
      const body = 'Tài khoản của bạn manhnt0123@gmail.com vừa có hoạt động đăng nhập mới. Cảnh báo bảo mật.';
      final parsed = EmailParserService.parse(
        'no-reply@accounts.google.com',
        'Cảnh báo bảo mật',
        body,
      );

      expect(parsed, isNull);
    });

    test('Filter Personal Chat from test sender - Should return null', () {
      const body = 'Chào bạn, trưa nay ăn gì thế? Mình đi ăn phở nhé.';
      final parsed = EmailParserService.parse(
        'manhnt0123@gmail.com',
        'Ăn trưa',
        body,
      );

      expect(parsed, isNull);
    });

    test('Sanitize HTML from test sender - Should parse correctly and strip tags', () {
      const body = '<div style="color: red;">Vietcombank: So tien GD +2,500,000 VND. <td style="height:0px">Noi dung: Nhan luong thang 6</td></div>';
      final parsed = EmailParserService.parse(
        'manhnt0123@gmail.com',
        'Giao dịch chuyển khoản',
        body,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 100.0); // 2,500,000 / 25,000 = 100.0 USD
      expect(parsed.isExpense, false);
      expect(parsed.description, 'Nhan luong thang 6'); // Verify HTML tag is stripped out
      expect(parsed.category, 'Salary');
    });
  });
}
