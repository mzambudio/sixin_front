enum PositionsLang { es, en }

class VolleyPosition {
  final String id;
  final String nameEs;
  final String nameEn;
  final String abbrEs;
  final String abbrEn;

  const VolleyPosition({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required this.abbrEs,
    required this.abbrEn,
  });

  String name(PositionsLang lang) => lang == PositionsLang.es ? nameEs : nameEn;
  String abbr(PositionsLang lang) => lang == PositionsLang.es ? abbrEs : abbrEn;
}

const volleyPositions = <VolleyPosition>[
  VolleyPosition(
    id: 'OH',
    nameEs: 'Receptor',
    nameEn: 'Outside Hitter',
    abbrEs: 'R',
    abbrEn: 'OH',
  ),
  VolleyPosition(
    id: 'MB',
    nameEs: 'Central',
    nameEn: 'Middle Blocker',
    abbrEs: 'CE',
    abbrEn: 'MB',
  ),
  VolleyPosition(
    id: 'S',
    nameEs: 'Colocador',
    nameEn: 'Setter',
    abbrEs: 'CO',
    abbrEn: 'S',
  ),
  VolleyPosition(
    id: 'OPP',
    nameEs: 'Opuesto',
    nameEn: 'Opposite',
    abbrEs: 'O',
    abbrEn: 'OPP',
  ),
  VolleyPosition(
    id: 'L',
    nameEs: 'Líbero',
    nameEn: 'Libero',
    abbrEs: 'L',
    abbrEn: 'L',
  ),
];

VolleyPosition? positionById(String id) {
  for (final p in volleyPositions) {
    if (p.id == id) return p;
  }
  return null;
}
