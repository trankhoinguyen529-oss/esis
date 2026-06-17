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

  Widget buildFormField_1({
    required BuildContext context,
    required Map<String, IconData?> icons,
    required Set<String> excludedIcon,
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
            children: icons.entries
                .where((entry) => !excludedIcon.contains(entry.key))
                .map((entry) {
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

  Widget buildFormField_M({
    required BuildContext context,
    required Map<String, IconData?> icons,
    required Set<String> excludedIcon,
    required Function(Set<String>) ifSelected, // ✅ đổi sang Set
    required Set<String> selectedKeys, // ✅ đổi sang Set
  }) {
    return InkWell(
      onTap: () async {
        Set<String> tempSelected =
            Set.from(selectedKeys); // ✅ copy set hiện tại

        final result = await showModalBottomSheet<Set<String>>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, tempSelected),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...icons.entries
                      .where((entry) => !excludedIcon.contains(entry.key))
                      .map((entry) {
                    final isSelected = tempSelected.contains(entry.key);
                    return ListTile(
                      leading:
                          Icon(entry.value, color: const Color(0xFF14C38E)),
                      title: Text(entry.key),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF14C38E))
                          : null,
                      onTap: () {
                        setSheetState(() {
                          if (entry.key == 'All') {
                            // ✅ bấm All → chỉ chọn All, bỏ hết cái khác
                            tempSelected = {'All'};
                          } else {
                            // ✅ bấm item khác → bỏ All, toggle item đó
                            tempSelected.remove('All');
                            if (isSelected) {
                              tempSelected.remove(entry.key);
                            } else {
                              tempSelected.add(entry.key);
                            }
                            // ✅ nếu bỏ hết thì tự động về All
                            if (tempSelected.isEmpty) {
                              tempSelected = {'All'};
                            }
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );

        if (result != null) ifSelected(result); // ✅ trả về Set
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
            // ✅ hiện icon của item đầu tiên nếu có
            Icon(
              selectedKeys.isEmpty ? null : icons[selectedKeys.first],
              color: const Color(0xFF14C38E),
            ),
            const SizedBox(width: 12),
            // ✅ hiện tất cả item đã chọn
            Text(
              selectedKeys.isEmpty
                  ? '--Multiple Pick--'
                  : selectedKeys.join(', '),
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}
