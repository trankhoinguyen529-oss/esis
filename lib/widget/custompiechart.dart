import 'package:flutter/material.dart';
import 'dart:math';
import '../data/piechartdata.dart';
import '../data/categorycolor.dart';
import 'package:a_management/services/database_service.dart';

/// `BubbleClipper` tạo hình dạng bong bóng đối thoại có mũi tên chỉ sang trái (hướng về biểu đồ).
class BubbleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double arrowWidth = 6.0;
    const double arrowHeight = 8.0;
    const double radius = 6.0;

    final double arrowTop = (size.height - arrowHeight) / 2;
    final double arrowBottom = (size.height + arrowHeight) / 2;

    path.moveTo(arrowWidth + radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(arrowWidth + radius, size.height);
    path.quadraticBezierTo(arrowWidth, size.height, arrowWidth, size.height - radius);

    // Mũi tên chỉ sang trái
    path.lineTo(arrowWidth, arrowBottom);
    path.lineTo(0, size.height / 2);
    path.lineTo(arrowWidth, arrowTop);

    path.lineTo(arrowWidth, radius);
    path.quadraticBezierTo(arrowWidth, 0, arrowWidth + radius, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// `CustomPieChart` vẽ biểu đồ tròn tương tác có hỗ trợ nhấn giữ để phóng to lát cắt,
/// hiển thị tên và giá trị ở giữa, đồng thời hiện bong bóng đối thoại chỉ sang phải chứa phần trăm.
class CustomPieChart extends StatefulWidget {
  final List<PieChartData> data;
  final String title;

  const CustomPieChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  State<CustomPieChart> createState() => _CustomPieChartState();
}

class _CustomPieChartState extends State<CustomPieChart> {
  int? _selectedIndex;

  double get _totalValue {
    if (widget.data.isEmpty) return 0;
    return widget.data.fold(0.0, (sum, item) => sum + item.value);
  }

  void _handleTouch(Offset localPosition, Size size) {
    if (widget.data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final radius = (size.width / 2) - 12;

    // Kiểm tra xem điểm chạm có nằm trong vùng Donut không
    if (distance > radius + 10 || distance < radius * 0.2) {
      if (_selectedIndex != null) {
        setState(() {
          _selectedIndex = null;
        });
      }
      return;
    }

    double angle = atan2(dy, dx);
    if (angle < 0) {
      angle += 2 * pi;
    }

    // Điều chỉnh theo startAngle = -pi/2
    double adjustedAngle = angle - (-pi / 2);
    if (adjustedAngle < 0) {
      adjustedAngle += 2 * pi;
    }
    adjustedAngle = adjustedAngle % (2 * pi);

    double currentAngle = 0;
    int? foundIndex;
    final total = _totalValue;

    for (int i = 0; i < widget.data.length; i++) {
      final percentage = total > 0 ? (widget.data[i].value / total) * 100 : 0.0;
      final sweepAngle = (percentage / 100) * 2 * pi;
      if (adjustedAngle >= currentAngle &&
          adjustedAngle < currentAngle + sweepAngle) {
        foundIndex = i;
        break;
      }
      currentAngle += sweepAngle;
    }

    if (foundIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = foundIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final total = _totalValue;
        final selectedItem =
            _selectedIndex != null ? widget.data[_selectedIndex!] : null;

        // Tính toán phần trăm và góc của phần tử được chọn để đặt vị trí bong bóng
        double selectedPercentage = 0;
        double middleAngle = 0;
        if (_selectedIndex != null && total > 0) {
          selectedPercentage = (selectedItem!.value / total) * 100;
          double startAngle = -pi / 2;
          for (int i = 0; i < _selectedIndex!; i++) {
            final pct = (widget.data[i].value / total) * 100;
            startAngle += (pct / 100) * 2 * pi;
          }
          final sweepAngle = (selectedPercentage / 100) * 2 * pi;
          middleAngle = startAngle + sweepAngle / 2;
        }

        final innerDiameter = (size.width - 24) * 0.60;

        // Tính toạ độ Y của bong bóng đối thoại
        final double radius = (size.width / 2) - 12;
        final double yOffset = (size.height / 2) + sin(middleAngle) * (radius + 6);
        // Giới hạn Y để không vượt quá chiều cao biểu đồ
        final double clampedY = yOffset.clamp(20.0, size.height - 20.0);

        return GestureDetector(
          onPanDown: (details) => _handleTouch(details.localPosition, size),
          onPanUpdate: (details) => _handleTouch(details.localPosition, size),
          onPanEnd: (_) => setState(() => _selectedIndex = null),
          onPanCancel: () => setState(() => _selectedIndex = null),
          onTapDown: (details) => _handleTouch(details.localPosition, size),
          onTapUp: (_) => setState(() => _selectedIndex = null),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Vẽ các phần biểu đồ
              CustomPaint(
                size: size,
                painter: CustomPieChartPainter(
                  data: widget.data,
                  selectedIndex: _selectedIndex,
                  totalValue: total,
                ),
              ),
              // Vòng tròn lỗ trắng ở giữa
              IgnorePointer(
                child: Container(
                  width: innerDiameter,
                  height: innerDiameter,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            selectedItem != null ? selectedItem.name : widget.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (selectedItem != null) ...[
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatCurrency(selectedItem.value),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CategoryColor.getColor(selectedItem.name),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bong bóng đối thoại hướng sang phải chứa %
              if (_selectedIndex != null)
                Positioned(
                  left: size.width - 12,
                  top: clampedY - 14, // 14 là nửa chiều cao trung bình của bong bóng
                  child: IgnorePointer(
                    child: ClipPath(
                      clipper: BubbleClipper(),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                        color: Colors.black87,
                        child: Text(
                          '${selectedPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// CustomPainter vẽ các lát cắt biểu đồ tròn dạng Donut.
class CustomPieChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final int? selectedIndex;
  final double totalValue;

  CustomPieChartPainter({
    required this.data,
    required this.selectedIndex,
    required this.totalValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalValue <= 0) return;

    final double radius = (size.width / 2) - 12;
    final Offset center = Offset(size.width / 2, size.height / 2);

    double startAngle = -pi / 2;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final percentage = (item.value / totalValue) * 100;
      final sweepAngle = (percentage / 100) * 2 * pi;

      final paint = Paint()
        ..color = CategoryColor.getColor(item.name)
        ..style = PaintingStyle.fill;

      final isSelected = selectedIndex == i;
      final double sliceRadius = isSelected ? radius + 6 : radius;

      if (isSelected) {
        final double middleAngle = startAngle + sweepAngle / 2;
        final Offset offset = Offset(cos(middleAngle) * 4, sin(middleAngle) * 4);
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: sliceRadius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      if (isSelected) {
        canvas.restore();
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPieChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.data != data ||
        oldDelegate.totalValue != totalValue;
  }
}
