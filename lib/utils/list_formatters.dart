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

/// Devuelve dd/MM
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Devuelve HH:mm
String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Formatea un array (systems/levels) en modo compacto:
/// - [] => '—'
/// - [A] => 'A'
/// - [A,B] => 'A+B'
/// - [A,B,C] => 'A+…'
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

/// Lee y formatea totalPrice.
/// - null => '—'
/// - num => '24€' o '24.50€'
String formatTotalPrice(Map<String, dynamic> data) {
  final v = data['totalPrice'];
  if (v == null) return '—';

  final n = v is num ? v.toDouble() : double.tryParse(v.toString());
  if (n == null) return '—';

  final isInt = n % 1 == 0;
  final s = isInt ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  return '$s€';
}

/// Construye un título compacto de la lista con tus campos nuevos:
/// "Lugar • dd/MM HH:mm • 6-2+… • Intermedio+… • 24€"
String buildListTitle(Map<String, dynamic> data) {
  final place = (data['place'] ?? '(sin lugar)').toString().trim();
  final startAt = readStartAt(data);

  final datePart = startAt == null ? 'sin fecha' : formatDate(startAt);
  final timePart = startAt == null ? 'sin hora' : formatTime(startAt);

  final systemPart = formatMulti(data['systems']);
  final levelPart = formatMulti(data['levels']);
  final pricePart = formatTotalPrice(data);

  return '$place • $datePart $timePart • $systemPart • $levelPart • $pricePart';
}

/// Alternativa útil para subtítulo (si no quieres un title tan largo).
/// Devuelve algo tipo: "dd/MM HH:mm · Sistema: 6-2+… · Nivel: Intermedio · Precio: —"
String buildListSubtitle(Map<String, dynamic> data) {
  final startAt = readStartAt(data);
  final when = startAt == null
      ? 'sin fecha'
      : '${formatDate(startAt)} ${formatTime(startAt)}';

  final systemPart = formatMulti(data['systems']);
  final levelPart = formatMulti(data['levels']);
  final pricePart = formatTotalPrice(data);

  return '$when · Sistema: $systemPart · Nivel: $levelPart · Precio: $pricePart';
}
