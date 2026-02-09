import 'package:flutter/material.dart';
import 'package:flutter_metro_app/metrostation_class.dart';

// دلوقتي Dropdown بياخد قائمة محطات (فلترة ممكنة)
Widget stationDropdown({
  required String hint,
  required MetroStation? selectedValue,
  required Function(MetroStation?) onChanged,
  required List<MetroStation> items, // 👈 هنا هنبعت القايمة المفلترة
}) {
  return DropdownButtonFormField<MetroStation>(
    value: selectedValue,
    hint: Text(hint),
    isExpanded: true,
    decoration: InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    items: items.map((station) {
      return DropdownMenuItem<MetroStation>(
        value: station,
        child: Text('${station.name} (Line ${station.line})'),
      );
    }).toList(),
    onChanged: onChanged,
  );
}
