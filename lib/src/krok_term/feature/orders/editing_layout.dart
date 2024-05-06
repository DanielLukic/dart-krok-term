part of 'editing.dart';

void _createLayout(
  Dialog dialog,
  DuiState state,
  (ExecuteState, dynamic) status,
) {
  final es = status.$1;
  if (es != ExecuteState.idle) {
    return _renderExecuting(es, status, dialog, state);
  }

  final AssetPairData ap = state['pair'];

  final priceAck = DuiText(makePrice(state['price'], state.priceAck, ap));
  final limitAck = DuiText(makePrice(state['limit'], state.limitAck, ap));
  final volumeAck = DuiText(makeVolume(state.volumeAck, ap));

  final ask = 'Ask: ${state.ask}';
  final bid = 'Bid: ${state.bid}';
  final volMax = 'Max: ${state.volMax}';
  final volMin = 'Min: ${state.volMin}';

  final ts = state.isTrailing;
  final price = state.makeInput('price', plusMinus: !ts, trailing: ts);
  final limit = state.makeInput('limit', plusMinus: true);
  final volume = state.makeInput('volume', plusMinus: false);

  final priceInfo = DuiText('Latest price:\n${ask.green()}\n${bid.red()}');

  final priceLabel = state.type == OrderType.limit ? 'Limit' : 'Price';
  final op = state['price_was'];
  final pl = DuiText('$priceLabel:\n(Order: $op)');
  final ol = state['limit_was'];
  final ll = DuiText('Limit:\n(Order: $ol)');
  final ov = state['volume_was'];
  final vMax = volMax.gray();
  final vMin = volMin.gray();
  final vl = DuiText('Volume ${ap.base}:\n(Order: $ov)\n$vMax\n$vMin');

  final helpHint = '([?] for help)'.gray();
  final title = 'Edit ${ap.wsname} ${state.dir.name} order $helpHint';

  final priceChanged = state.needsPrice &&
      state.priceAck.$2 == null &&
      state.priceAck.$1 != null;

  final limitChanged = state.needsLimit &&
      state.limitAck.$2 == null &&
      state.limitAck.$1 != null;

  final volumeChanged =
      state.volumeAck.$2 == null && state.volumeAck.$1 != null;

  final anythingChanged = priceChanged || limitChanged || volumeChanged;

  final confirm = DuiButton(
    id: 'confirm',
    text: 'Edit order <Return>',
    enabled: anythingChanged,
  )..onClick = () => state.triggerExecuteOrder();

  final layout = DuiLayout(
    state: state,
    root: DuiBorder(
      DuiPadding.hv(
        h: 2,
        v: 1,
        wrapped: DuiRow([
          DuiColumn(
            [
              DuiTitle(title),
              DuiSpace(),
              priceInfo,
              DuiSpace(),
              DuiRow([vl, volume, volumeAck]),
              DuiSpace(),
              if (state.needsPrice) DuiRow([pl, price, priceAck]),
              if (state.needsLimit) DuiRow([ll, limit, limitAck]),
              DuiSpace(),
              confirm,
            ],
          ),
          if (state['help']) DuiSpace(),
          if (state['help']) DuiText.fromLines(state.help),
        ]),
      ),
    ),
  );

  _addInputKeys(state, layout, volume);
  _addInputKeys(state, layout, price);
  _addInputKeys(state, layout, limit);

  layout.onKey('?', aliases: ['<C-?>'], description: 'Toggle help', action: () {
    state['help'] = !state['help'];
  });

  layout.onKey('<Return>', description: 'Execute order', action: () {
    if (!confirm.enabled) return;
    state.triggerExecuteOrder();
  });

  layout.onKey('<Escape>',
      aliases: ['q'],
      description: 'Cancel alert creation',
      action: () => dialog.dismiss());

  dialog.attach(layout);
}

void _addInputKeys(
  DuiState state,
  DuiLayout layout,
  DuiTextInput it,
) {
  void resetInput(String i) {
    final f = layout.focused;
    final id = f?.id;
    if (f is DuiTextInput && id != null) state[id] = i;
  }

  final price = it.id == 'price' || it.id == 'limit';
  if (price) {
    if (state.isTrailing) {
      if (it.id == 'price') {
        _addPlus(it, resetInput);
      }
      if (it.id == 'limit') {
        _addPlus(it, resetInput);
        _addMinus(it, resetInput);
      }
    } else {
      _addPlus(it, resetInput);
      _addMinus(it, resetInput);
      _addJoker(it, resetInput);
    }
  }

  if (!price) {
    it.onKey('m', description: 'Set to maximum', action: () {
      state['volume'] = state.volMax;
    });
  }

  it.onKey('x', description: 'Clear input', action: () => resetInput(''));
}

void _addPlus(DuiTextInput it, Function(String) resetInput) {
  it.onKey('+',
      description: 'Start entering relative price',
      action: () => resetInput('+'));
}

void _addMinus(DuiTextInput it, Function(String) resetInput) {
  it.onKey('-',
      description: 'Start entering relative price',
      action: () => resetInput('-'));
}

void _addJoker(DuiTextInput it, Function(String) resetInput) {
  it.onKey('#',
      description: 'Start entering relative price',
      action: () => resetInput('#'));
}
