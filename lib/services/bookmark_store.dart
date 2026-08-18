import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan persisten untuk sekumpulan ID item yang di-bookmark.
class BookmarkStore {
  const BookmarkStore(this.preferenceKey);

  final String preferenceKey;

  Future<Set<int>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(preferenceKey) ?? const [];
    return values
        .map(int.tryParse)
        .whereType<int>()
        .where((id) => id >= 0)
        .toSet();
  }

  Future<void> save(Iterable<int> ids) async {
    final preferences = await SharedPreferences.getInstance();
    final sortedIds = ids.where((id) => id >= 0).toSet().toList()..sort();
    await preferences.setStringList(
      preferenceKey,
      sortedIds.map((id) => id.toString()).toList(growable: false),
    );
  }
}
