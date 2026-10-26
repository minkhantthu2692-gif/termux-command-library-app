import 'dart:async';

/// Combines two broadcast-safe streams without adding an RxDart dependency.
/// The combined subscription pauses/resumes with the consumer so listeners
/// that are not visible do not keep expensive database streams alive.
Stream<T> combineLatest2<A, B, T>(
  Stream<A> first,
  Stream<B> second,
  T Function(A, B) combine,
) {
  late StreamController<T> controller;
  StreamSubscription<A>? firstSub;
  StreamSubscription<B>? secondSub;
  A? latestA;
  B? latestB;
  var hasA = false;
  var hasB = false;

  void emit() {
    if (hasA && hasB && !controller.isClosed) {
      controller.add(combine(latestA as A, latestB as B));
    }
  }

  controller = StreamController<T>(
    onListen: () {
      firstSub = first.listen((value) {
        latestA = value;
        hasA = true;
        emit();
      }, onError: controller.addError);
      secondSub = second.listen((value) {
        latestB = value;
        hasB = true;
        emit();
      }, onError: controller.addError);
    },
    onPause: () {
      firstSub?.pause();
      secondSub?.pause();
    },
    onResume: () {
      firstSub?.resume();
      secondSub?.resume();
    },
    onCancel: () async {
      await firstSub?.cancel();
      await secondSub?.cancel();
    },
  );
  return controller.stream;
}

Stream<T> combineLatest3<A, B, C, T>(
  Stream<A> first,
  Stream<B> second,
  Stream<C> third,
  T Function(A, B, C) combine,
) {
  late StreamController<T> controller;
  StreamSubscription<A>? firstSub;
  StreamSubscription<B>? secondSub;
  StreamSubscription<C>? thirdSub;
  A? latestA;
  B? latestB;
  C? latestC;
  var hasA = false;
  var hasB = false;
  var hasC = false;

  void emit() {
    if (hasA && hasB && hasC && !controller.isClosed) {
      controller.add(combine(latestA as A, latestB as B, latestC as C));
    }
  }

  controller = StreamController<T>(
    onListen: () {
      firstSub = first.listen((value) {
        latestA = value;
        hasA = true;
        emit();
      }, onError: controller.addError);
      secondSub = second.listen((value) {
        latestB = value;
        hasB = true;
        emit();
      }, onError: controller.addError);
      thirdSub = third.listen((value) {
        latestC = value;
        hasC = true;
        emit();
      }, onError: controller.addError);
    },
    onPause: () {
      firstSub?.pause();
      secondSub?.pause();
      thirdSub?.pause();
    },
    onResume: () {
      firstSub?.resume();
      secondSub?.resume();
      thirdSub?.resume();
    },
    onCancel: () async {
      await firstSub?.cancel();
      await secondSub?.cancel();
      await thirdSub?.cancel();
    },
  );
  return controller.stream;
}
