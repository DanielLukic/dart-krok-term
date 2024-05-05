import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';

void onAddAlert(AddAlert add) {
  final refPrice = add.pair.price(add.refPrice);

  final preset = add.presetPrice ?? '';
  final input = DuiTextInput(
    id: 'input',
    limitLength: 20,
    preset: preset,
    filter: RegExp(r"[-+]?[0-9]*\.?[0-9]*%?"),
  );

  final dialog = desktop.openDialog();
  final state = DuiState(() => dialog.requestRedraw());
  final layout = DuiLayout(
    state: state,
    root: DuiBorder(
      DuiPadding.hv(
        h: 2,
        v: 1,
        wrapped: DuiColumn(
          [
            DuiTitle('Create ${add.pair.wsname} alert'),
            DuiSpace(),
            DuiText.fromLines([
              'Specify price as absolute value or +/-.',
              'Optionally use % with either absolute or +/-.',
              '',
              'Use x or <C-u> to clear input.',
              'Use j/k and <S-j>/<S-k> to change price by 1 or 10 percent.',
              'Use <Escape> to cancel. Press <Return> to create alert.',
            ]),
            DuiSpace(),
            DuiText('Price (${add.label}): $refPrice'),
            DuiSpace(),
            DuiRow(
              [
                input,
                DuiButton(id: 'confirm', text: "Create <Return>")
                  ..onClick = () => _createAlert(input, add, dialog),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  dialog.attach(layout);

  void changePrice(int percent) {
    final step = add.refPrice * percent / 100;
    final current = double.tryParse(input.input);
    if (current == null) return;
    input.input = add.pair.price(current + step);
  }

  layout.onKey('k',
      description: 'Up 1% of last price', action: () => changePrice(1));
  layout.onKey('<S-k>',
      description: 'Up 10% of last price', action: () => changePrice(10));

  layout.onKey('j',
      description: 'Down 1% of last price', action: () => changePrice(-1));
  layout.onKey('<S-j>',
      description: 'Down 10% of last price', action: () => changePrice(-10));

  layout.onKey('+',
      description: 'Start entering relative price',
      action: () => input.input = '+');
  layout.onKey('-',
      description: 'Start entering relative price',
      action: () => input.input = '-');

  layout.onKey('x',
      aliases: ['<C-u>'],
      description: 'Clear input',
      action: () => input.input = '');

  layout.onKey('<Escape>',
      aliases: ['q'],
      description: 'Cancel alert creation',
      action: () => dialog.dismiss());

  layout.onKey(
    '<Return>',
    aliases: ['a'],
    description: 'Confirm alert creation',
    action: () => _createAlert(input, add, dialog),
  );
}

void _createAlert(DuiTextInput input, AddAlert add, Dialog dialog) {
  var i = input.input;

  final op = switch (i) {
    _ when i.startsWith('+') => (e) => add.refPrice + e,
    _ when i.startsWith('-') => (e) => add.refPrice - e,
    _ => null,
  };
  if (op != null) i = i.drop(1);

  final pre = switch (i) {
    _ when i.endsWith('%') => (e) => add.refPrice * e / 100,
    _ => null,
  };
  if (pre != null) i = i.dropLast(1);

  final price = double.tryParse(i);
  if (price != null) {
    final abs = (pre ?? (e) => e)(price);
    final res = (op ?? (e) => e)(abs);
    final mode = switch (res) {
      _ when res < add.lastPrice => 'below',
      _ when res > add.lastPrice => 'above',
      _ => null,
    };
    logVerbose('alter at: $res last: ${add.lastPrice} => mode: $mode');
    if (mode == null) {
      desktop.toast('ignoring alert for same price');
    } else {
      final data = add.pair;
      alertsRepo.add(AlertData(data.pair, data.wsname, res, mode));
    }
    dialog.dismiss();
  } else {
    desktop.toast('invalid price: $i');
  }
}
