class ParsedEmailTransaction {
  final String title;
  final double amount;
  final bool isExpense;
  final DateTime date;
  final String time;
  final String category;
  final String description;

  ParsedEmailTransaction({
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.date,
    required this.time,
    required this.category,
    required this.description,
  });
}

class EmailParserService {
  /// Map a raw email subject/body to a ParsedEmailTransaction or null if it's not a bank email.
  static ParsedEmailTransaction? parse(
      String from, String subject, String body) {
    final cleanFrom = from.toLowerCase();

    // Check if sender is a recognized bank or the test sender 'manh'
    final isFromBankOrTest = cleanFrom.contains('vietcombank') ||
        cleanFrom.contains('tpb') ||
        cleanFrom.contains('techcombank') ||
        cleanFrom.contains('mbbank') ||
        cleanFrom.contains('acb') ||
        cleanFrom.contains('manh');

    if (!isFromBankOrTest) return null;

    // Strip HTML from body to avoid matching inside tags or CSS styles
    String tempBody = body;
    if (body.contains('<') && body.contains('>')) {
      tempBody = body.replaceAll(RegExp(r'<[^>]*>'), ' ');
    }

    final cleanSubject = _removeDiacritics(subject.toLowerCase());
    final cleanBody = _removeDiacritics(tempBody.toLowerCase());

    // Check for clear transaction keywords to prevent parsing general emails (like warnings, personal chats)
    bool hasTransactionKeywords = cleanSubject.contains('bien dong') ||
        cleanSubject.contains('giao dich') ||
        cleanSubject.contains('sao ke') ||
        cleanBody.contains('so tien') ||
        cleanBody.contains('so du') ||
        cleanBody.contains('vietcombank') ||
        cleanBody.contains('tpbank') ||
        cleanBody.contains('techcombank') ||
        cleanBody.contains('mbbank') ||
        cleanBody.contains('acb');

    if (!hasTransactionKeywords) return null;

    String bankName = 'Bank';
    if (cleanFrom.contains('vietcombank') ||
        cleanSubject.contains('vietcombank') ||
        cleanBody.contains('vietcombank')) {
      bankName = 'Vietcombank';
    } else if (cleanFrom.contains('tpb') ||
        cleanSubject.contains('tpbank') ||
        cleanBody.contains('tpbank')) {
      bankName = 'TPBank';
    } else if (cleanFrom.contains('techcombank') ||
        cleanSubject.contains('techcombank') ||
        cleanBody.contains('techcombank')) {
      bankName = 'Techcombank';
    } else if (cleanFrom.contains('acb') ||
        cleanSubject.contains('acb') ||
        cleanBody.contains('acb')) {
      bankName = 'ACB';
    } else if (cleanFrom.contains('mbbank') ||
        cleanSubject.contains('mbbank') ||
        cleanBody.contains('mb bank')) {
      bankName = 'MB Bank';
    }

    // 1. Determine type (Expense or Income)
    // Default is expense
    bool isExpense = true;
    if (cleanBody.contains('+') ||
        cleanBody.contains('ghi co') ||
        cleanBody.contains('nhan tu') ||
        cleanBody.contains('nop tien') ||
        cleanBody.contains('nhan chuyen khoan') ||
        cleanBody.contains('giao dich ghi co')) {
      isExpense = false;
    } else if (cleanBody.contains('-') ||
        cleanBody.contains('ghi no') ||
        cleanBody.contains('chuyen di') ||
        cleanBody.contains('thanh toan') ||
        cleanBody.contains('rut tien')) {
      isExpense = true;
    }

    // 2. Parse Amount
    double rawAmount = 0.0;
    // Regex looking for numbers: optionally preceded by + or -, followed by digits/commas/dots, and followed by VND, đ, usd, $
    // E.g., +50,000 VND, -100.000đ, 5,000.00 USD, so tien gd: 200,000
    final amountRegExps = [
      RegExp(
          r'(?:so tien gd|so tien|thay doi|[\+\-]\s*)([0-9,.]+)\s*(?:vnd|đ|usd|\$)'),
      RegExp(r'(?:so tien|gd|thay doi):\s*([\+\-]?\s*[0-9,.]+)'),
      RegExp(r'([\+\-]?\s*[0-9,.,]+)\s*(?:vnd|đ|usd|\$)'),
      RegExp(r'([0-9,.]+)\s*(?:vnd|đ|usd|\$)'),
    ];

    for (final regex in amountRegExps) {
      final match = regex.firstMatch(cleanBody);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(RegExp(r'[^0-9.]'), '');
        // Sometimes dots are thousand separators, let's normalize
        double? parsed = double.tryParse(amountStr);
        if (parsed == null) {
          // Try replacing dots if it looks like Vietnamese numbering (e.g. 50.000)
          final normalizedStr =
              amountStr.replaceAll('.', '').replaceAll(',', '');
          parsed = double.tryParse(normalizedStr);
        }
        if (parsed != null && parsed > 0) {
          rawAmount = parsed;
          break;
        }
      }
    }

    // Convert VND to USD since the app shows transaction amounts in USD (exchange rate ~25,000)
    // If the raw amount is large (e.g. > 1000) and contains 'vnd' or 'đ' keywords, convert it.
    double appAmount = rawAmount;
    if (rawAmount > 1000 &&
        (cleanBody.contains('vnd') ||
            cleanBody.contains('đ') ||
            cleanBody.contains('d'))) {
      appAmount = rawAmount / 25000.0;
    }

    // Reject transactions without any valid parsed positive amount
    if (appAmount <= 0) return null;

    // 3. Parse Description / Content
    String description = '';
    final descRegExps = [
      RegExp(r'(?:noi dung gd|noi dung|nd|mo ta|ly do):\s*([^.\n]+)'),
      RegExp(r'(?:noi dung gd|noi dung|nd|mo ta|ly do)\s*([^.\n]+)'),
      RegExp(r'gd\s+([^.\n]+)'),
    ];

    for (final regex in descRegExps) {
      final match = regex.firstMatch(cleanBody);
      if (match != null) {
        description = match.group(1)!.trim();
        break;
      }
    }

    if (description.isEmpty) {
      // Fallback to subject or part of the email body
      description = subject
          .replaceAll(
              RegExp(r'bien dong so du|giao dich|thong bao',
                  caseSensitive: false),
              '')
          .trim();
      if (description.isEmpty) {
        description = 'Giao dịch qua $bankName';
      }
    }

    // Capitalize first letter of description
    if (description.isNotEmpty) {
      description = description[0].toUpperCase() + description.substring(1);
    }

    // 4. Parse Date & Time
    DateTime date = DateTime.now();
    String time =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    // Look for time pattern: HH:mm:ss or HH:mm
    final timeMatch = RegExp(r'(\d{2}:\d{2}(?::\d{2})?)').firstMatch(cleanBody);
    if (timeMatch != null) {
      time = timeMatch.group(1)!;
      if (time.split(':').length == 3) {
        // Remove seconds for time display in app
        final parts = time.split(':');
        time = "${parts[0]}:${parts[1]}";
      }
    }

    // Look for date pattern: dd/MM/yyyy or dd-MM-yyyy
    final dateMatch =
        RegExp(r'(\d{2}[/\-]\d{2}[/\-]\d{4})').firstMatch(cleanBody);
    if (dateMatch != null) {
      final dateStr = dateMatch.group(1)!;
      final parts = dateStr.split(RegExp(r'[/\-]'));
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]) ?? date.day;
        final month = int.tryParse(parts[1]) ?? date.month;
        final year = int.tryParse(parts[2]) ?? date.year;
        date = DateTime(year, month, day);
      }
    }

    // 5. Category mapping based on keywords
    String category = _mapCategory(description, isExpense);

    return ParsedEmailTransaction(
      title: '$bankName Transaction',
      amount: double.parse(appAmount.toStringAsFixed(2)),
      isExpense: isExpense,
      date: date,
      time: time,
      category: category,
      description: description,
    );
  }

  /// Remove Vietnamese diacritics to make regex searching more reliable
  static String _removeDiacritics(String str) {
    const vietnamese = [
      'aàáảãạăằắẳẵặâầấẩẫậ',
      'dđ',
      'eèéẻẽẹêềếểễệ',
      'iìíỉĩị',
      'oòóỏõọôồốổỗộơờớởỡợ',
      'uùúủũụưừứửữự',
      'yỳýỷỹỵ'
    ];
    const english = ['a', 'd', 'e', 'i', 'o', 'u', 'y'];

    String result = str;
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(RegExp('[${vietnamese[i]}]'), english[i]);
    }
    return result;
  }

  /// Map description to app category keys:
  /// 'Food', 'Transport', 'Medicine', 'Groceries', 'Rent', 'Gifts', 'Savings', 'Entertainment', 'Salary', 'Work', 'Gaming', 'Others'
  static String _mapCategory(String description, bool isExpense) {
    final desc = description.toLowerCase();

    if (!isExpense) {
      if (desc.contains('luong') ||
          desc.contains('salary') ||
          desc.contains('paycheck') ||
          desc.contains('thu nhap') ||
          desc.contains('bonus') ||
          desc.contains('thuong')) {
        return 'Salary';
      }
      if (desc.contains('work') ||
          desc.contains('freelance') ||
          desc.contains('ban hang')) {
        return 'Work';
      }
      return 'Savings';
    }

    if (desc.contains('an sang') ||
        desc.contains('an trua') ||
        desc.contains('an toi') ||
        desc.contains('cafe') ||
        desc.contains('coffee') ||
        desc.contains('food') ||
        desc.contains('restaurant') ||
        desc.contains('nha hang') ||
        desc.contains('tra sua') ||
        desc.contains('starbucks') ||
        desc.contains('highlands') ||
        desc.contains('shopeefood') ||
        desc.contains('grabfood')) {
      return 'Food';
    }

    if (desc.contains('grab') ||
        desc.contains('gojek') ||
        desc.contains('be ') ||
        desc.contains('taxi') ||
        desc.contains('xe may') ||
        desc.contains('xang') ||
        desc.contains('ve xe') ||
        desc.contains('ve may bay') ||
        desc.contains('flight') ||
        desc.contains('transport') ||
        desc.contains('bus')) {
      return 'Transport';
    }

    if (desc.contains('nha thuoc') ||
        desc.contains('thuoc') ||
        desc.contains('pharmacy') ||
        desc.contains('hospital') ||
        desc.contains('benh vien') ||
        desc.contains('kham benh') ||
        desc.contains('bac si') ||
        desc.contains('medical') ||
        desc.contains('medicine')) {
      return 'Medicine';
    }

    if (desc.contains('shopee') ||
        desc.contains('lazada') ||
        desc.contains('tiki') ||
        desc.contains('sieu thi') ||
        desc.contains('market') ||
        desc.contains('mart') ||
        desc.contains('vinmart') ||
        desc.contains('coop') ||
        desc.contains('bach hoa') ||
        desc.contains('groceries')) {
      return 'Groceries';
    }

    if (desc.contains('nha') ||
        desc.contains('rent') ||
        desc.contains('phong') ||
        desc.contains('tro') ||
        desc.contains('chung cu') ||
        desc.contains('house')) {
      return 'Rent';
    }

    if (desc.contains('tang') ||
        desc.contains('gift') ||
        desc.contains('sinh nhat') ||
        desc.contains('birthday') ||
        desc.contains('mung') ||
        desc.contains('donate') ||
        desc.contains('tu thien')) {
      return 'Gifts';
    }

    if (desc.contains('tiet kiem') ||
        desc.contains('dau tu') ||
        desc.contains('gui tiet kiem') ||
        desc.contains('savings')) {
      return 'Savings';
    }

    if (desc.contains('phim') ||
        desc.contains('movie') ||
        desc.contains('netflix') ||
        desc.contains('rap chieu') ||
        desc.contains('ca nhac') ||
        desc.contains('concert') ||
        desc.contains('ticket') ||
        desc.contains('entertainment')) {
      return 'Entertainment';
    }

    if (desc.contains('game') ||
        desc.contains('ps5') ||
        desc.contains('steam') ||
        desc.contains('nintendo') ||
        desc.contains('gaming')) {
      return 'Gaming';
    }

    if (desc.contains('cong viec') ||
        desc.contains('work') ||
        desc.contains('van phong pham') ||
        desc.contains('in an')) {
      return 'Work';
    }

    return 'Others';
  }
}
