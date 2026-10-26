import 'dart:convert';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class APICache {

  static const String _CACHE_KEY = "cache";

  late final CacheManager _cacheManager;

  //Singleton to use for the different components
  APICache._() {
    this._cacheManager = CacheManager(
      Config(
        _CACHE_KEY,
        stalePeriod: const Duration(minutes: 5)
      )
    );
  }
  static APICache? instance;

  static Future<APICache> get() async {
    if (instance != null) {
      return instance!;
    }
    final created = APICache._();
    instance = created;
    await created._cacheManager.emptyCache();
    return created;
  }

  Future<String?> getContents(String url) async {
    final info = await this._cacheManager.getFileFromCache(url);
    if (info == null) {
      return null;
    }
    return utf8.decode(info.file.readAsBytesSync());
  }

  Future putContents(String url, String contents) {
    return this._cacheManager.putFile(url, utf8.encode(contents));
  }
}