/// Off the web there is no localStorage, so marks live in memory for as long
/// as the process does. Widget tests land here, which is what makes the
/// save-and-reload path checkable without a browser.
abstract final class ExamMarksStore {
  static final _memory = <String, Set<int>>{};

  static Set<int> load(String key) => {...?_memory[key]};

  static void save(String key, Set<int> ids) => _memory[key] = {...ids};

  static void clear(String key) => _memory.remove(key);
}
