import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok_term/src/krok_term/common/functions.dart';
import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';
import 'package:rxdart/rxdart.dart';

part 'ordering_execute.dart';
part 'ordering_layout.dart';
part 'ordering_state.dart';

void onPlaceOrder(PlaceOrder place) {
  final redraw = BehaviorSubject.seeded(DateTime.timestamp());
  final execute = BehaviorSubject<(DateTime, DuiState?)>.seeded(
      (DateTime.timestamp(), null));

  final state = DuiState(() => redraw.value = DateTime.timestamp());
  state['dir'] = place.dir;
  state['execute'] = execute;
  state['help'] = false;
  state['limit'] = place.pair.price(place.limit);
  state['pair'] = place.pair;
  state['price'] = place.pair.price(place.price);
  state['type'] = place.type;
  state['vol_mode'] = true;
  state['volume'] = '';
  state['z'] = '';

  if (state.isTrailing) state['price'] = '+1%';
  if (state.isTrailing) state['limit'] = '-2%';

  state.focusedId = 'volume';

  final dialog = desktop.openDialog();

  final Stream<(ExecuteState, dynamic)> executing = execute
      .switchMap((s) => _executeStream(s.$2))
      .onErrorReturnWith((e, trace) => _forwardError(e, trace))
      .startWith((ExecuteState.idle, null)) //
      .doOnData((e) => _refreshOrdersOnSuccess(e));

  combine([redraw, executing])
      .listen((e) => _createLayout(dialog, state, e[1]));

  final ap = place.pair;

  dialog.autoDispose('balances', balances.listen((b) {
    state['volume_ref'] = b[ap.base]?.volume ?? 0;
  }));
  dialog.autoDispose('portfolio', portfolio.listen((p) {
    state['z_ref'] = p.tb;
  }));
  dialog.autoDispose('tickers', tickers.listen((t) {
    state['price_ticker'] = t[ap.pair];
  }));
}

(ExecuteState, Object) _forwardError(Object error, StackTrace trace) {
  logError(error, trace);
  return (ExecuteState.failed, error);
}

void _refreshOrdersOnSuccess((ExecuteState, dynamic) e) {
  if (e.$1 != ExecuteState.complete) return;
  Future.delayed(1.seconds, () {
    openOrdersRepo.refresh(userRequest: true);
    closedOrdersRepo.refresh(userRequest: true);
  });
}
