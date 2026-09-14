import 'dart:html' as html;

/// Which questions a student flagged, kept only in their browser. It survives
/// a refresh and a resume, which is the path that matters; it does not survive
/// a change of machine, and it is never sent to the server or shown after
/// submit -- flags are a scratchpad for the student sitting the test.
abstract final class ExamMarksStore {
  static String _slot(String key) => 'exam_marks_$key';

  static Set<int> load(String key) {
    // Storage throws outright in some private-browsing modes, and the test is
    // not worth failing over a flag.
    try {
      final raw = html.window.localStorage[_slot(key)];
      if (raw == null || raw.isEmpty) return {};
      return {
        for (final part in raw.split(','))
          if (int.tryParse(part) case final id?) id,
      };
    } catch (_) {
      return {};
    }
  }

  static void save(String key, Set<int> ids) {
    try {
      if (ids.isEmpty) {
        html.window.localStorage.remove(_slot(key));
        return;
      }
      html.window.localStorage[_slot(key)] = ids.join(',');
    } catch (_) {
      // A flag that does not persist still works for the rest of this module.
    }
  }

  static void clear(String key) {
    try {
      html.window.localStorage.remove(_slot(key));
    } catch (_) {}
  }
}
