import 'dart:async';

class SampleStep {
  late int milliseconds;
  List<int> sample;

  SampleStep(this.milliseconds, this.sample);
}

Stream<List<int>> sampleStreamer(List<SampleStep> sampleSteps) {
  late StreamController<List<int>> controller;
  Timer? timer;
  int counter = 0;

  void tick() {
    controller.add(sampleSteps[counter].sample);
    counter++;
    if (counter >= sampleSteps.length) {
      return;
    }

    timer = Timer(Duration(milliseconds: sampleSteps[counter].milliseconds), tick);
  }

  void startTimer() {
    if (counter >= sampleSteps.length) {
      return;
    }

    timer = Timer(Duration(milliseconds: sampleSteps[counter].milliseconds), tick);
  }

  void stopTimer() {
    if (timer != null) {
      timer?.cancel();
      timer = null;
    }
  }

  controller = StreamController<List<int>>(
    onListen: startTimer,
    onPause: stopTimer,
    onResume: startTimer,
    onCancel: stopTimer,
  );

  return controller.stream;
}

int keySelector(List<int> l) {
  if (l.isEmpty) {
    return 0;
  }

  if (l.length == 1) {
    return l[0];
  }

  return l[1] * 256 + l[0];
}


class Stream2ThrottledDeduplicatedStreamList {
  final Duration _duration;
  final Stream<List<int>> _parent;
  Map<int, List<int>> _listMap = {};
  Timer? _timer;

  Stream2ThrottledDeduplicatedStreamList(this._parent, this._duration);

  Stream<List<List<int>>> pumpStream() async* {
    await for (final list in _parent) {
      final key = keySelector(list);
      _listMap[key] = list;
      final shouldYield = !(_timer?.isActive ?? false);
      _timer ??= Timer(_duration, () => { _timer = null });
      if (shouldYield) {
        final values = _listMap.values.toList(growable: false);
        _listMap = {};
        yield values;
      }
    }
  }
}
