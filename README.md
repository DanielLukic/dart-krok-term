## Krok Term - Kraken Crypto API TUI

Another project from my "Learn me some Dart" phase.

After implementing a Kraken Crypto API that I named [krok](https://pub.dev/packages/krok) for no good reason, I
started implementing a simple TUI "desktop system". Also in Dart. This one is called
[consul](https://pub.dev/packages/dart_consul).

This now in front of you is the obvious conclusion... 🙃

### What is this?

Basic alternative to the Kraken Web Interface. Allows running this in screen/tux/... session on a server. That's
what I do. Or locally on your machine in a terminal. Because that's fun and cool. Right? 🙃

The neat thing, to me, are the shortcuts. You can just type "gb" to go to the balances window. Inside a window you
can scroll up/down via j/k like a real vim pro. You can jump into the asset pair selection from everywhere via / and
start typing to filter. Then press enter to select it.

### Example Screenshot

Screenshot of the app running:

![Screenshot](images/example.gif)

As you can see, at the time of this writing, much is missing. Especially the chart of the currently selected asset
pair. I also have no idea how Kraken calculates their 24-hour percentages. So mine or totally off.

### Some Code

Most of the code is hideous. For fun side projects I like to just spill out code... 🤷 Especially the TUI code is
pretty nasty in places.

On the other, I tried getting the core as clean as possible with my limited understanding of the Dart ecosystem. For
example the repos holding the data like assets and balances. Here's such an example:

```dart
final class AssetPairsRepo extends KrokAutoRepo<AssetPairs> {
  AssetPairsRepo(Storage storage) : super(
    storage,
    "asset_pairs",
    request: () => KrakenRequest.assetPairs(),
    preform: (e) => _preform(e),
    restore: (e) => _restore(e),
  );

  static JsonObject _preform(JsonObject data) =>
      data.map((k, v) => MapEntry(k, (v as Map<String, dynamic>) + {'pair': k}));

  static AssetPairs _restore(JsonObject result) =>
      result.map((k, v) => MapEntry(k, AssetPairData(v)));
}
```

For storage, I briefly looked at existing solutions. Besides the real database (sqlite primarily) solutions and realm
(which I liked, but which is available for Flutter only), I found stash. But I couldn't get it to work. And the API
was overly complex for my task. So I decided to write a very simple solution myself. Which makes sense. Because I
want to learn me some Dart... 🙃

Moving on, the core is a simple "actor style" queue. Nothing more than this:

```dart
void initKrokCore() async {
  logEvent('init krok core');
  await for (final it in _queue.stream) {
    await _process(it);
  }
}
```

A simplified version of `_process` is:

```dart
Future _process(QueuedRequest it) async {
  if (!it.canceled) {
    await _throttle(it);
    try {
      final response = await _api.retrieve(it._request);
      it.complete(response);
    } catch (error) {
      if (!it.canceled) {
        it.completeError(error);
        logEvent("fail $it: $error");
      }
    }
  }
}
```

The `_throttle` call ensures not hitting the API rate limit.

There is of course some more to this core. Like the `QueuedRequest` class. But all things considered, it is
reasonable small and readable. Imho.

### To Do

If I have some more time to work on this:

- Fix pair handling (XXBT vs XBT vs BTC and / from "wsname" messing up display)
- Add the market chart (pretty sure I'll do this - and soon)
- Add a market crawler to give indications what to do
- Add simple bots
- Maybe a bot language (haven't done that in a long time)

The pair handling is a mess. Pair and currency. Currently, simply strings. But these should be
AssetData/AssetPairData objects instead. Or at least extension types. Either way, they need to represent properly
what data is provided. For example, Bitcoin on the Kraken platform is called XBT, but shown as BTC. And for some
reason, some asset pairs use XX before the asset. And currencies are using ZUSD. Probably all done to avoid
confusion like in the case of PYUSD. Which currently is broken in krok-term... 🙃

This is probably something I need to fix asap.

### No AI/ML

I will probably not look at any AI/ML for this. I have no experience with that. And it would distract too much from
my primary goal of learning Dart, then Flutter, then some Flutter Flame (game engine), and finally offer my
Freelance Services as a Flutter App developer. Well, that's the plan anyway...

