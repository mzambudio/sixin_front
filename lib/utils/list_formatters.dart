import 'package:cloud_firestore/cloud_firestore.dart';

/// Lee startAt desde Firestore.
/// - Recomendado: Timestamp
/// - Soporta DateTime por compatibilidad.
DateTime? readStartAt(Map<String, dynamic> data) {
  final v = data['startAt'];
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return null;
}

/// Devuelve HH:mm
String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Devuelve dd/MM
String formatDateDMY(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Key estable para agrupar por día (local time): "YYYY-MM-DD"
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Devuelve "Lunes 01/09/2024"
String dayHeaderEs(DateTime d) {
  const wd = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  final weekday = wd[d.weekday - 1];
  return '$weekday ${formatDateDMY(d)}';
}

/// TITLE corto: "Lugar • HH:mm"
String buildListTitleShort(Map<String, dynamic> data) {
  final place = (data['place'] ?? '(sin lugar)').toString().trim();
  final startAt = readStartAt(data)?.toLocal();

  final timePart = startAt == null ? '—:—' : formatTime(startAt);
  return '$place • $timePart';
}

/// Subtitle completo: "Sistema: 6-0 · Nivel: Intermedio · Precio: 10€"
String buildListSubtitleCompact(Map<String, dynamic> data) {
  final sys = formatMulti(data['systems']);
  final lvl = formatMulti(data['levels']);
  final price = formatTotalPrice(data);
  return 'Sistema: $sys · Nivel: $lvl · Precio: $price';
}

/// Helper para mostrar sistemas o niveles, que pueden ser listas vacías, de 1 o 2 items, o más.
String formatMulti(dynamic raw) {
  final list = raw is List
      ? raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
      : <String>[];

  list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  if (list.isEmpty) return '—';
  if (list.length == 1) return list.first;
  if (list.length == 2) return '${list[0]}+${list[1]}';
  return '${list[0]}+…';
}

/// Helper para mostrar el precio total, que puede ser un número, una cadena, o no estar presente.
String formatTotalPrice(Map<String, dynamic> data) {
  final v = data['totalPrice'];
  if (v == null) return '—';
  final n = v is num ? v.toDouble() : double.tryParse(v.toString());
  if (n == null) return '—';
  final isInt = n % 1 == 0;
  final s = isInt ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  return '$s€';
}
