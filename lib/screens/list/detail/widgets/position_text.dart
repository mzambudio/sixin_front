import 'package:sixin_front/core/constants/volley_positions.dart';

const String kPosPoly = 'U';

PositionsLang langFromSetting(String langStr) =>
    (langStr == 'en') ? PositionsLang.en : PositionsLang.es;

/// Devuelve el texto corto que se muestra en el badge.
String positionAbbr(String? id, PositionsLang lang) {
  if (id == null || id.isEmpty) return '—';

  if (id == kPosPoly) {
    return (lang == PositionsLang.es) ? '—' : '—';
  }

  final p = volleyPositions
      .where((x) => x.id == id)
      .cast<VolleyPosition?>()
      .firstWhere((x) => x != null, orElse: () => null);

  return p?.abbr(lang) ?? id;
}

/// Devuelve un nombre “largo” útil para tooltip (opcional)
String positionName(String? id, PositionsLang lang) {
  if (id == null || id.isEmpty) return '—';

  if (id == kPosPoly) {
    return (lang == PositionsLang.es) ? 'Polivalente' : 'All-rounder';
  }

  final p = volleyPositions
      .where((x) => x.id == id)
      .cast<VolleyPosition?>()
      .firstWhere((x) => x != null, orElse: () => null);

  return p?.name(lang) ?? id;
}
