/// Накопление команд печати для отправки на сервер: только объекты `{ "cmd": … }`
/// в списке `print_data` (без вёрстки, TextPainter, растров и т.п.).
class PosPrint {
  final List<Map<String, dynamic>> _cmds = <Map<String, dynamic>>[];

  /// Сброс накопленных команд.
  void clear() => _cmds.clear();

  /// Копия для поля `print_data` в теле HTTP-запроса.
  List<Map<String, dynamic>> toCommandList() =>
      List<Map<String, dynamic>>.from(_cmds);

  void fontsize(double size) =>
      _cmds.add(<String, dynamic>{'cmd': 'fontsize', 'size': size.round()});

  void br({int height = 0}) => _cmds.add(<String, dynamic>{'cmd': 'br', 'height' : height});

  void line() => _cmds.add(<String, dynamic>{'cmd': 'line'});

  void line2([int width = 1]) =>
      _cmds.add(<String, dynamic>{'cmd': 'line2', 'width': width});

  void ltext(String text, {int x = 0, int width = -1}) =>
      _cmds.add(<String, dynamic>{'cmd': 'ltext', 'text': text, 'x':x , 'textwidth': width });

  void rtext(String text) =>
      _cmds.add(<String, dynamic>{'cmd': 'rtext', 'text': text});

  void ctext(String text) =>
      _cmds.add(<String, dynamic>{'cmd': 'ctext', 'text': text});

  void lrtext(String left, String? right) {
    _cmds.add(<String, dynamic>{
      'cmd': 'lrtext',
      'left': left,
      'right': right,
    });
  }
}
