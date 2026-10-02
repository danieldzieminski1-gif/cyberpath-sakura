import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../content/data/content_repository.dart';
import '../../progress/application/providers.dart';

// Public, key-less endpoints (no account or API key needed).
const _newsUrl = 'https://hn.algolia.com/api/v1/search_by_date?query=cybersecurity&tags=story&numericFilters=points%3E15&hitsPerPage=30';
const _kevUrl = 'https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json';

const _kNewsKey = 'cyberpath.live.news.v1';
const _kKevKey = 'cyberpath.live.kev.v1';
const _kLessonsKey = 'cyberpath.remote.lessons.v1';

bool get _isTestEnv {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

class NewsItem {
  const NewsItem({required this.title, required this.url, required this.source, this.subtitle = '', this.at, this.tag = 'NEWS'});
  final String title;
  final String url;
  final String source;
  final String subtitle;
  final DateTime? at;
  final String tag;

  Map<String, Object?> toJson() => {'t': title, 'u': url, 's': source, 'sub': subtitle, 'at': at?.toIso8601String(), 'tag': tag};

  static NewsItem? fromJson(Object? j) {
    if (j is! Map || j['t'] == null) return null;
    return NewsItem(
      title: j['t'].toString(),
      url: j['u']?.toString() ?? '',
      source: j['s']?.toString() ?? '',
      subtitle: j['sub']?.toString() ?? '',
      at: DateTime.tryParse(j['at']?.toString() ?? ''),
      tag: j['tag']?.toString() ?? 'NEWS',
    );
  }
}

class _Cached {
  const _Cached(this.items, this.at);
  final List<NewsItem> items;
  final DateTime at;
}

class LiveFeed {
  const LiveFeed({required this.items, required this.kev, required this.isLive, this.updatedAt});
  final List<NewsItem> items;
  final List<NewsItem> kev;

  /// true = fetched from the internet just now; false = cached or built-in fallback.
  final bool isLive;
  final DateTime? updatedAt;
}

/// Shown when the phone has never been online, so the UI is never empty.
const List<NewsItem> kFallbackBriefing = [
  NewsItem(title: 'Turn on passkeys for your email today', url: '', source: 'CyberPath tip', subtitle: 'Phishing-resistant sign-in beats any password.', tag: 'TIP'),
  NewsItem(title: 'Updates are your cheapest security control', url: '', source: 'CyberPath tip', subtitle: 'Most attacks use bugs that already have a fix.', tag: 'TIP'),
  NewsItem(title: 'Treat anything an AI agent reads as untrusted', url: '', source: 'CyberPath tip', subtitle: 'Prompt injection hides commands inside normal content.', tag: 'TIP'),
  NewsItem(title: 'Use a password manager and unique passwords', url: '', source: 'CyberPath tip', subtitle: 'One leaked password should never open two doors.', tag: 'TIP'),
];

class LiveRepository {
  LiveRepository(this._prefs, [http.Client? client]) : _client = client ?? http.Client();
  final SharedPreferences _prefs;
  final http.Client _client;

  // ---------- cache helpers ----------
  _Cached? _readCache(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final items = (m['items'] as List).map(NewsItem.fromJson).whereType<NewsItem>().toList();
      final at = DateTime.tryParse(m['at']?.toString() ?? '');
      if (items.isEmpty || at == null) return null;
      return _Cached(items, at);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, List<NewsItem> items) async {
    try {
      await _prefs.setString(key, jsonEncode({'at': DateTime.now().toIso8601String(), 'items': [for (final i in items) i.toJson()]}));
    } catch (_) {}
  }

  Future<String?> _get(String url, Duration timeout) async {
    final res = await _client.get(Uri.parse(url), headers: const {'Accept': 'application/json', 'User-Agent': 'CyberPath/1.1'}).timeout(timeout);
    if (res.statusCode != 200) return null;
    return utf8.decode(res.bodyBytes);
  }

  // ---------- news ----------
  Future<List<NewsItem>> _fetchNews() async {
    final body = await _get(_newsUrl, const Duration(seconds: 8));
    if (body == null) return const [];
    final hits = (jsonDecode(body) as Map)['hits'] as List? ?? const [];
    final out = <NewsItem>[];
    for (final h in hits) {
      if (h is! Map) continue;
      final title = (h['title'] ?? h['story_title'])?.toString();
      if (title == null || title.trim().isEmpty) continue;
      final id = h['objectID']?.toString() ?? '';
      final url = (h['url']?.toString().isNotEmpty ?? false) ? h['url'].toString() : 'https://news.ycombinator.com/item?id=$id';
      out.add(NewsItem(
        title: title.trim(),
        url: url,
        source: Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? 'news',
        subtitle: '${h['points'] ?? 0} points on Hacker News',
        at: DateTime.tryParse(h['created_at']?.toString() ?? ''),
      ));
      if (out.length >= 12) break;
    }
    return out;
  }

  // ---------- CISA Known Exploited Vulnerabilities ----------
  Future<List<NewsItem>> _fetchKev() async {
    final body = await _get(_kevUrl, const Duration(seconds: 15));
    if (body == null) return const [];
    final vulns = ((jsonDecode(body) as Map)['vulnerabilities'] as List? ?? const []).whereType<Map>().toList()
      ..sort((a, b) => (b['dateAdded'] ?? '').toString().compareTo((a['dateAdded'] ?? '').toString()));
    return [
      for (final v in vulns.take(5))
        NewsItem(
          title: '${v['cveID']} · ${v['vendorProject']} ${v['product']}',
          url: 'https://nvd.nist.gov/vuln/detail/${v['cveID']}',
          source: 'CISA KEV',
          subtitle: (v['vulnerabilityName'] ?? '').toString(),
          at: DateTime.tryParse((v['dateAdded'] ?? '').toString()),
          tag: 'EXPLOITED',
        ),
    ];
  }

  /// Network first, then cache, then built-in tips. Never throws.
  Future<LiveFeed> loadFeed({bool force = false}) async {
    var news = _readCache(_kNewsKey);
    var kev = _readCache(_kKevKey);
    var live = false;
    if (!_isTestEnv) {
      try {
        final fresh = await _fetchNews();
        if (fresh.isNotEmpty) {
          await _writeCache(_kNewsKey, fresh);
          news = _Cached(fresh, DateTime.now());
          live = true;
        }
      } catch (_) {/* offline: keep cache */}
      final stale = kev == null || DateTime.now().difference(kev.at) > const Duration(hours: 12);
      if (force || stale) {
        try {
          final fresh = await _fetchKev();
          if (fresh.isNotEmpty) {
            await _writeCache(_kKevKey, fresh);
            kev = _Cached(fresh, DateTime.now());
          }
        } catch (_) {}
      }
    }
    return LiveFeed(items: news?.items ?? kFallbackBriefing, kev: kev?.items ?? const [], isLive: live, updatedAt: news?.at);
  }

  // ---------- remote lessons ----------
  /// Applies lessons downloaded on a previous run. Synchronous and offline-safe.
  static int applyCachedLessons(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_kLessonsKey);
      return raw == null ? 0 : mergeRemoteCourses(parseRemoteCourses(raw));
    } catch (_) {
      return 0;
    }
  }

  /// Downloads the remote lesson file and merges new lessons. Returns lessons added.
  Future<int> syncLessons() async {
    if (kRemoteLessonsUrl.isEmpty || _isTestEnv) return 0;
    try {
      final body = await _get(kRemoteLessonsUrl, const Duration(seconds: 10));
      if (body == null || body.length > 1500000) return 0;
      final courses = parseRemoteCourses(body);
      if (courses.isEmpty) return 0;
      await _prefs.setString(_kLessonsKey, body);
      return mergeRemoteCourses(courses);
    } catch (_) {
      return 0;
    }
  }
}

// ---------- providers ----------
final liveRepoProvider = Provider<LiveRepository>((ref) => LiveRepository(ref.watch(prefsProvider)));

final liveFeedProvider = FutureProvider<LiveFeed>((ref) => ref.watch(liveRepoProvider).loadFeed());

/// Bumped whenever remote lessons were merged, so screens can rebuild.
final contentRevisionProvider = StateProvider<int>((ref) => 0);

final lessonSyncProvider = FutureProvider<int>((ref) async {
  final added = await ref.watch(liveRepoProvider).syncLessons();
  if (added > 0) ref.read(contentRevisionProvider.notifier).state++;
  return added;
});

// ---------- small helpers ----------
Future<void> openExternal(String url) async {
  if (url.isEmpty) return;
  try {
    final uri = Uri.parse(url);
    if (uri.scheme == 'https' || uri.scheme == 'http') await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

String timeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t.toLocal());
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return '${(d.inDays / 30).floor()}mo ago';
}
