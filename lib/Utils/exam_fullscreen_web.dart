import 'dart:html' as html;

/// Immersion, not invigilation: the student can leave with Esc at any time and
/// nothing is recorded when they do. Tab-hiding is what the attempt already
/// watches to pause the clock, and that is the better signal anyway.
abstract final class ExamFullscreen {
  static bool get isSupported => html.document.fullscreenEnabled ?? false;

  static bool get isActive => html.document.fullscreenElement != null;

  /// Fires for Esc and for the browser's own chrome as well as for our button,
  /// so the icon can follow the browser instead of our last tap.
  static Stream<void> get onChange => html.document.onFullscreenChange;

  static void enter() {
    if (isActive) return;
    // Only granted inside a user gesture; callers ask from a tap, and a
    // refusal is a rejected promise the page can ignore.
    html.document.documentElement?.requestFullscreen();
  }

  static void exit() {
    if (!isActive) return;
    html.document.exitFullscreen();
  }
}
