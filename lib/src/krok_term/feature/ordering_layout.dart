part of 'ordering.dart';

void _createLayout(
  Dialog dialog,
  DuiState state,
  (ExecuteState, dynamic) status,
) {
  final es = status.$1;
  if (es != ExecuteState.idle) {
    return _renderExecuting(es, status, dialog, state);
  }

  final dirs = OrderDirection.values.mapList((e) => (e.name, e));
  final dir = DuiSwitcher(id: 'dir', entries: dirs, selected: state['dir'])
    ..onSelection = (e) => state['dir'] = e;

  final types = OrderType.values
      .where((e) => e != OrderType.settlePosition)
      .mapList((e) => (e.name, e));
  types.sort((a, b) => a.$2.name.compareTo(b.$2.name));

  final type = DuiSwitcher(id: 'type', entries: types, selected: state['type'])
    ..onSelection = (e) {
      state['type'] = e;
      if (state.isTrailing) state.updateForTrailing();
    };

  final AssetPairData ap = state['pair'];

  final priceAck = DuiText(makePrice(state['price'], state.priceAck, ap));
  final limitAck = DuiText(makePrice(state['limit'], state.limitAck, ap));
  final volumeAck = DuiText(makeVolume(state.volumeAck, ap));
  final zAck = DuiText(makePrice(state['z'], state.zAck, ap));

  final ask = 'Ask: ${state.ask}';
  final bid = 'Bid: ${state.bid}';
  final volMax = 'Max: ${state.volMax}';
  final volMin = 'Min: ${state.volMin}';
  final zMax = 'Max: ${state.zMax}';
  final zMin = 'Min: ${state.zMin}';

  final ts = state.isTrailing;
  final price = state.makeInput('price', plusMinus: !ts, trailing: ts);
  final limit = state.makeInput('limit', plusMinus: true);
  final volume = state.makeInput('volume', plusMinus: false)
    ..chain((e) => state.updateZFromVolume(e));
  final z = state.makeInput('z', plusMinus: false)
    ..chain((e) => state.updateVolumeFromZ(e));

  final priceInfo = DuiText('Latest price:\n${ask.green()}\n${bid.red()}');
  final pl = DuiText('Price [?]:');
  final ll = DuiText('Limit [?]:');
  final vl = DuiText('Volume ${ap.base}:\n${volMax.gray()}\n${volMin.gray()}');
  final zl = DuiText('Volume ${ap.quote_}:\n${zMax.gray()}\n${zMin.gray()}');

  final helpHint = '([?] for help)'.gray();
  final title = 'Create ${ap.wsname} ${state.dir.name} order $helpHint';

  final confirm = DuiButton(
    id: 'confirm',
    text: 'Create order <Return>',
    enabled: !state.description.contains('<'),
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
              DuiRow([dir, type, priceInfo]),
              DuiSpace(),
              if (state['vol_mode']) DuiRow([vl, volume, volumeAck]),
              if (!state['vol_mode']) DuiRow([zl, z, zAck]),
              if (state.needsPrice) DuiRow([pl, price, priceAck]),
              if (state.needsLimit) DuiRow([ll, limit, limitAck]),
              DuiSpace(),
              DuiText(state.description),
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
  _addInputKeys(state, layout, z);
  _addInputKeys(state, layout, price);
  _addInputKeys(state, layout, limit);

  layout.onKey('?', aliases: ['<C-?>'], description: 'Toggle help', action: () {
    state['help'] = !state['help'];
  });

  layout.onKey('v', description: 'Toggle volume input', action: () {
    state['vol_mode'] = !state['vol_mode'];
    if (state['vol_mode']) state.focusedId = 'volume';
    if (!state['vol_mode']) state.focusedId = 'z';
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
      state['z'] = state.zMax;
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

extension on DuiTextInput {
  void chain(void Function(String) onChange) {
    final now = this.onChange;
    this.onChange = (e) {
      now(e);
      onChange(e);
    };
  }
}
