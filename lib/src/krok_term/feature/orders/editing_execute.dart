part of 'editing.dart';

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
  logWarn(s);
  logWarn(s['txid']);
  logWarn(s['userref_was']);

  final txid = s['txid'];
  if (txid == null) throw ArgumentError('null txid');

  final pair = s.ap.pair;
  KrakenPrice? price;
  KrakenPrice? price2;

  if (s.needsPrice && s['price'].isNotEmpty) {
    final ts = s.isTrailing;
    price = KrakenPrice.fromString(s['price'], trailingStop: ts);
    logVerbose('price $price');
    if (s.needsLimit && s['limit'].isNotEmpty) {
      // TODO this was different, right? ts does not apply here?
      price2 = KrakenPrice.fromString(s['limit'], trailingStop: ts);
      logVerbose('price2 $price2');
    }
  }

  final request = KrakenRequest.editOrder(
    txid: txid,
    pair: pair,
    userref: s['userref_was'],
    volume: s.volumeAck.$1,
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
    ExecuteState.executing => 'Editing order',
    ExecuteState.complete => 'Order edited'.whiteBright(),
    ExecuteState.failed => 'Editing order failed'.red(),
  };
  final info = status.$2.toString().replaceAll(',', '\n');
  final layout = DuiLayout(
    root: DuiBorder(
      DuiPadding.hv(
        h: 2,
        v: 1,
        wrapped: DuiColumn(
          [
            DuiTitle(title),
            DuiSpace(),
            DuiText(info),
          ],
        ),
      ),
    ),
  );
  dialog.attach(layout);

  if (es == ExecuteState.executing) return;

  final complete = status.$1 == ExecuteState.complete;
  layout.onKey(
    '<Escape>',
    aliases: ['<Return>', 'q'],
    description: complete ? 'Back to main screen' : 'Back to order form',
    action: () {
      if (complete) {
        dialog.dismiss();
      } else {
        state.clearExecution();
      }
    },
  );

  return;
}
