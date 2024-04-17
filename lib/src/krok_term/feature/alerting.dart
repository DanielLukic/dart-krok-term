import 'package:krok_term/src/krok_term/repository/krok_repos.dart';

import '../common/desktop.dart';
import '../repository/alerts_repo.dart';
import '../repository/ticker_repo.dart';

class Alerting {
  Alerting(TickersRepo tickersRepo);

  void onAdd(AlertAdd add) {
    final lastPrice = add.pair.price(add.lastPrice);

    final preset = add.presetPrice ?? '';
    final input = DuiTextInput(
      limitLength: 20,
      preset: preset,
      filter: RegExp(r"[-+]?[0-9]*\.?[0-9]*%?"),
    );

    final layout = DuiLayout(
      DuiBorder(
        DuiPadding.hv(
          DuiColumn(
            [
              DuiPadding(DuiTitle('Create alert'), bottom: 1),
              DuiText.fromLines([
                'Specify price as absolute value or +/-.',
                'Optionally use % with either absolute or +/-.'
              ]),
              DuiSpace(),
              DuiText('Last price: $lastPrice'),
              DuiSpace(),
              DuiRow(
                [
                  input,
                  DuiSpace(2),
                  DuiButton("Create <Return>"),
                ],
              ),
              DuiSpace(),
              DuiText.fromLines([
                'Use <Escape> to cancel. Press <Return> to create alert.',
                'Use j/k and <S-j>/<S-k> to change price by 1 or 10 percent.',
              ])
            ],
          ),
          h: 2,
          v: 1,
        ),
      ),
    );

    final dialog = desktop.openDialog();
    dialog.attach(layout);

    void changePrice(int percent) {
      final step = add.lastPrice * percent / 100;
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

    layout.onKey('<Escape>',
        aliases: ['q'],
        description: 'Cancel alert creation',
        action: () => dialog.dismiss());

    layout.onKey(
      '<Return>',
      aliases: ['a'],
      description: 'Confirm alert creation',
      action: () {
        final price = double.tryParse(input.input);
        if (price != null) {
          alertsRepo.addAlert(add.pair.wsname, price);
          dialog.dismiss();
        } else {
          desktop.toast('invalid price: ${input.input}');
        }
      },
    );
  }
}
