import 'package:flutter/foundation.dart';
import 'db_helper.dart';

class FavoritesManager {
  static final FavoritesManager instance = FavoritesManager._init();
  FavoritesManager._init();

  final ValueNotifier<List<String>> favoriteTitles =
      ValueNotifier<List<String>>([]);

  Future<void> loadFavorites() async {
    print('FavoritesManager: loadFavorites() called.');
    final favorites = await DbHelper.instance.fetchFavoriteTitles();
    favoriteTitles.value = favorites;
    print(
      'FavoritesManager: Loaded completed. ValueNotifier is now: \\\$favorites',
    );
  }

  Future<void> toggleFavorite(String title) async {
    print('FavoritesManager: toggleFavorite() called with title: "\\\$title"');
    final currentList = List<String>.from(favoriteTitles.value);

    if (currentList.contains(title)) {
      print(
        'FavoritesManager: Title "\\\$title" exists. Removing from database...',
      );
      await DbHelper.instance.deleteFavoriteByTitle(title);
      currentList.remove(title);
    } else {
      print(
        'FavoritesManager: Title "\\\$title" does NOT exist. Adding to database...',
      );
      await DbHelper.instance.addFavoriteTitle(title);
      currentList.add(title);
    }
    favoriteTitles.value = currentList;
    print(
      'FavoritesManager: ValueNotifier updated. Current size: \\\${currentList.length}',
    );
  }

  Future<void> removeFavorite(String title) async {
    print(
      'FavoritesManager: removeFavorite() called to explicitly delete: "\\\$title"',
    );
    await DbHelper.instance.deleteFavoriteByTitle(title);
    final currentList = List<String>.from(favoriteTitles.value);
    currentList.remove(title);
    favoriteTitles.value = currentList;
    print(
      'FavoritesManager: Notification removed. Current size: \\\${currentList.length}',
    );
  }
}
