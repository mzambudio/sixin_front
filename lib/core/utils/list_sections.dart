import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sixin_front/core/utils/list_formatters.dart';

/// Helper para construir la lista de secciones (header + items) a partir de los docs, agrupando por día
class SectionRow {
  final bool isHeader;
  final String headerText;
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;

  SectionRow.header(this.headerText) : isHeader = true, doc = null;

  SectionRow.item(this.doc) : isHeader = false, headerText = '';
}

List<SectionRow> buildDaySections(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  // Ordena por startAt asc (si no viene ordenado ya por query)
  docs.sort((a, b) {
    final ta = (a.data()['startAt'] as Timestamp?)?.toDate();
    final tb = (b.data()['startAt'] as Timestamp?)?.toDate();
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return ta.compareTo(tb);
  });

  final out = <SectionRow>[];
  String? currentKey;

  for (final d in docs) {
    final start = readStartAt(d.data())?.toLocal();
    final key = start == null ? 'sin-fecha' : dayKey(start);

    if (key != currentKey) {
      currentKey = key;
      final header = start == null ? 'Sin fecha' : dayHeaderEs(start);
      out.add(SectionRow.header(header));
    }

    out.add(SectionRow.item(d));
  }

  return out;
}
