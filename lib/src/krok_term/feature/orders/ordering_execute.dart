part of 'ordering.dart';

enum ExecuteState {
  complete,
  executing,
  failed,
  idle,
}

Stream<(ExecuteState, dynamic)> _executeStream(DuiState? s) {
  if (s == null) return Stream.value((ExecuteState.idle, null));
  return ConcatStream([
    Stream.value((ExecuteState.executing, 'executing')),
    _executeOrder(s).map((r) {
      return r is Map ? (ExecuteState.complete, r) : (ExecuteState.failed, r);
    }),
  ]);
}

Stream _executeOrder(DuiState s) {
  final orderType = s.type;
  final direction = s.dir;
  final volume = s.volumeAck.$1;
  if (volume == null) throw ArgumentError('null volume');
  final pair = s.ap.pair;
  KrakenPrice? price;
  KrakenPrice? price2;

  if (s.needsPrice) {
    final ts = s.isTrailing;
    price = KrakenPrice.fromString(s['price'], trailingStop: ts);
    logInfo('price $price');
    if (s.needsLimit) {
      // TODO this was different, right? ts does not apply here?
      price2 = KrakenPrice.fromString(s['limit'], trailingStop: ts);
      logInfo('price2 $price2');
    }
  }

  final request = KrakenRequest.addOrder(
    orderType: orderType,
    direction: direction,
    volume: volume,
    pair: pair,
    price: price,
    price2: price2,
  );

  return retrieve(request);
}

void _renderExecuting(
  ExecuteState es,
  (ExecuteState, dynamic) status,
  Dialog dialog,
  DuiState state,
) {
  final title = switch (es) {
    ExecuteState.idle => 'Idle',
    ExecuteState.executing => 'Placing order',
    ExecuteState.complete => 'Order placed'.whiteBright(),
    ExecuteState.failed => 'Placing order failed'.red(),
  };
  final layout = DuiLayout(
    root: DuiBorder(
      DuiPadding.hv(
        h: 2,
        v: 1,
        wrapped: DuiColumn(
          [
            DuiTitle(title),
            DuiSpace(),
            DuiText(status.$2.toString()),
          ],
        ),
      ),
    ),
  );
  dialog.attach(layout);

  if (es == ExecuteState.executing) return;

  layout.onKey(
    '<Escape>',
    aliases: ['<Return>', 'q'],
    description: 'Back to order form',
    action: () {
      if (status.$1 == ExecuteState.complete) {
        dialog.dismiss();
      } else {
        state.clearExecution();
      }
    },
  );

  return;
}
