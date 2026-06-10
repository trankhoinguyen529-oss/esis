import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Textfield {
  static const Color primary = Color(0xFF00C18A);
  static const Color surface = Color(0xFFF3FFF8);
  Widget buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primary, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  final _categoryKey = GlobalKey();

  Widget buildFormField({
    required BuildContext context,
    required Map<String, IconData?> icons,
    required Function(String) ifSelected,
    required String selectedKey,
  }) {
    return InkWell(
      key: _categoryKey,
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final box =
            _categoryKey.currentContext!.findRenderObject() as RenderBox;
        final offset = box.localToGlobal(Offset.zero);
        final size = box.size;

        final selected = await showMenu<String>(
          context: context,
          constraints: BoxConstraints(
            minWidth: size.width,
            maxWidth: size.width,
            maxHeight: 200,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy + size.height, // 4px gap bên dưới
            offset.dx + size.width,
            offset.dy + size.height,
          ),
          items: icons.entries.map((entry) {
            return PopupMenuItem<String>(
              value: entry.key,
              height: 56,
              child: Row(
                children: [
                  Icon(entry.value, color: const Color(0xFF14C38E)),
                  const SizedBox(width: 12),
                  Text(entry.key),
                ],
              ),
            );
          }).toList(),
        );

        if (selected != null) ifSelected(selected);
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icons[selectedKey], color: const Color(0xFF14C38E)),
            const SizedBox(width: 12),
            Text(selectedKey, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}
