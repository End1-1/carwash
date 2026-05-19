/// Результат нажатия клавиши нумпада для суммы (без «⌫» — его обрабатывает вызывающий).
/// Убирает лишние ведущие нули: `0`+`5` → `5`, `05`+`0` → `50`.
String numpadMoneyKeyResult(String current, String key) {
  var t = current;
  if (key == '.') {
    if (t.contains('.')) return t;
    if (t.isEmpty || t == '0') return '0.';
    return '$t.';
  }
  if (!RegExp(r'^\d$').hasMatch(key)) return t;
  if (t.isEmpty) return key;
  if (t == '0') {
    return key == '0' ? '0' : key;
  }
  t = t + key;
  if (!t.contains('.')) {
    final stripped = t.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return stripped.isEmpty ? '0' : stripped;
  }
  final dot = t.indexOf('.');
  var intP = t.substring(0, dot);
  final frac = t.substring(dot + 1);
  intP = intP.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (intP.isEmpty) intP = '0';
  return '$intP.$frac';
}
