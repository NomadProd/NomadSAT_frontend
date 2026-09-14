/// Fullscreen is a browser capability. Off the web there is nothing to enter,
/// so every call is a no-op and `isSupported` keeps the button out of the bar.
/// Widget tests run here too, which is why the exam flow must not depend on
/// fullscreen actually happening.
abstract final class ExamFullscreen {
  static bool get isSupported => false;
  static bool get isActive => false;
  static Stream<void> get onChange => const Stream<void>.empty();
  static void enter() {}
  static void exit() {}
}
