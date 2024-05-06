import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok_term/src/krok_term/common/functions.dart';
import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';
import 'package:rxdart/rxdart.dart';

part 'editing_execute.dart';
part 'editing_layout.dart';
part 'editing_state.dart';

void onEditOrder(EditOrder edit) {
  final redraw = BehaviorSubject.seeded(DateTime.timestamp());
  final execute = BehaviorSubject<(DateTime, DuiState?)>.seeded(
      (DateTime.timestamp(), null));

  final state = DuiState(() => redraw.value = DateTime.timestamp());
  state['dir'] = edit.dir;
  state['execute'] = execute;
  state['help'] = false;
  state['limit'] = '';
  state['limit_was'] = edit.limit;
  state['pair'] = edit.ap;
  state['price'] = '';
  state['price_was'] = edit.price;
  state['type'] = edit.type;
  state['txid'] = edit.od.id;
  state['userref'] = '';
  state['userref_was'] = edit.userref;
  state['volume'] = '';
  state['volume_was'] = edit.volume;

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

  final ap = edit.ap;

  dialog.autoDispose('balances', balances.listen((b) {
    state['volume_ref'] = b[ap.base]?.volume ?? 0;
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
    openOrdersRepo.refresh(force: true);
    closedOrdersRepo.refresh(force: true);
  });
}
