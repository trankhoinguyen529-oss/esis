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

  Widget buildFormField({
    required BuildContext context,
    required Map<String, IconData?> icons,
    required Function(String) ifSelected,
    required String selectedKey,
  }) {
    return InkWell(
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => ListView(
            shrinkWrap: true,
            children: icons.entries.map((entry) {
              return ListTile(
                leading: Icon(entry.value, color: const Color(0xFF14C38E)),
                title: Text(entry.key),
                onTap: () => Navigator.pop(context, entry.key),
              );
            }).toList(),
          ),
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
