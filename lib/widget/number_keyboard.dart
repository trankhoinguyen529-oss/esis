import 'package:flutter/material.dart';

class NumberKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onConfirm;
  final Color confirmColor;

  const NumberKeyboard({
    super.key,
    required this.controller,
    required this.onConfirm,
    this.confirmColor = Colors.blue,
  });

  void _onKey(String key, BuildContext context) {
    if (key == '✓') {
      onConfirm();
      return;
    }
    final current = controller.text;
    if (key == '.') {
      if (current.contains('.')) return;
      if (current.isEmpty) {
        controller.text = '0.';
        return;
      }
    }
    controller.text = current + key;
  }

  void _onDelete() {
    final current = controller.text;
    if (current.isEmpty) return;
    controller.text = current.substring(0, current.length - 1);
  }

  Widget _buildKey(String key, BuildContext context) {
    final isConfirm = key == '✓';
    final isDelete = key == '⌫';

    return Expanded(
      child: GestureDetector(
        onTap: () => isDelete ? _onDelete() : _onKey(key, context),
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isConfirm
                ? confirmColor
                : isDelete
                    ? Colors.red.shade50
                    : const Color(0xFFF3FFF8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConfirm
                  ? confirmColor
                  : isDelete
                      ? Colors.red.shade200
                      : Colors.black12,
              width: 0.5,
            ),
          ),
          child: Center(
            child: isConfirm
                ? const Icon(Icons.check, color: Colors.white, size: 26)
                : isDelete
                    ? Icon(Icons.backspace_outlined,
                        color: Colors.red.shade400, size: 22)
                    : Text(
                        key,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(children: [
            _buildKey('1', context),
            _buildKey('2', context),
            _buildKey('3', context),
          ]),
          Row(children: [
            _buildKey('4', context),
            _buildKey('5', context),
            _buildKey('6', context),
          ]),
          Row(children: [
            _buildKey('7', context),
            _buildKey('8', context),
            _buildKey('9', context),
          ]),
          Row(children: [
            _buildKey('.', context),
            _buildKey('0', context),
            _buildKey('✓', context),
          ]),
          Row(children: [
            _buildKey('⌫', context), // ✅ nút xóa
          ]),
        ],
      ),
    );
  }
}
