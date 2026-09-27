// 网盘「登录后自动提取 Cookie」站点表。
//
// 思路：App 内用 WebView 打开网盘官网，用户正常登录；
// 登录完成后从 WebView 的 Cookie 仓库里取出该网盘域名下的 Cookie，
// 直接写进 OpenList 的存储配置里，用户不用再去浏览器 F12 复制粘贴。
//
// 新增网盘时只要往 kCookieSites 里加一条即可。

/// 一个网盘站点的登录信息。
class CookieSite {
  const CookieSite({
    required this.id,
    required this.label,
    required this.loginUrl,
    required this.cookieUrls,
    this.driverKeys = const <String>[],
    this.requiredKeys = const <String>[],
    this.anyKeys = const <String>[],
    this.userAgent,
    this.tip = '',
  });

  /// 内部标识
  final String id;

  /// 展示名
  final String label;

  /// 登录页地址
  final String loginUrl;

  /// 读取 Cookie 时使用的地址（可以覆盖多个域名）
  final List<String> cookieUrls;

  /// OpenList 中对应的驱动名
  final List<String> driverKeys;

  /// 必须存在的 Cookie 名（不区分大小写）
  final List<String> requiredKeys;

  /// 至少存在一个的 Cookie 名（不区分大小写）
  final List<String> anyKeys;

  /// 自定义 UA（部分站点对手机 UA 不友好）
  final String? userAgent;

  /// 页面上的提示文案
  final String tip;

  /// 驱动名是否匹配本站点。
  bool matchesDriver(String driver) {
    final d = driver.trim().toLowerCase();
    if (d.isEmpty) return false;
    for (final key in driverKeys) {
      final k = key.trim().toLowerCase();
      if (k.isEmpty) continue;
      if (k == d) return true;
      // 容错：驱动名带前后缀，例如 "115 Cloud"、"Quark TV"
      if (k.length >= 4 && (d.contains(k) || k.contains(d))) return true;
    }
    return false;
  }

  /// Cookie 里是否已经带有登录态。
  bool isValidCookie(String cookie) {
    final text = cookie.trim().toLowerCase();
    if (text.isEmpty) return false;
    for (final key in requiredKeys) {
      if (!text.contains('${key.toLowerCase()}=')) return false;
    }
    if (anyKeys.isNotEmpty) {
      final hit = anyKeys.any((key) => text.contains('${key.toLowerCase()}='));
      if (!hit) return false;
    }
    return true;
  }
}

const String kCookieLoginPcUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

/// 内置支持的网盘列表。
const List<CookieSite> kCookieSites = <CookieSite>[
  CookieSite(
    id: 'quark',
    label: '夸克网盘',
    loginUrl: 'https://pan.quark.cn/?fr=pc&platform=pc',
    cookieUrls: <String>['https://pan.quark.cn'],
    driverKeys: <String>['Quark'],
    requiredKeys: <String>['__pus', '__puus'],
    userAgent: kCookieLoginPcUserAgent,
    tip: '在下方网页里登录夸克账号，登录成功后会自动提取 Cookie（需包含 __pus 与 __puus）。',
  ),
  CookieSite(
    id: 'uc',
    label: 'UC 网盘',
    loginUrl: 'https://drive.uc.cn/',
    cookieUrls: <String>['https://drive.uc.cn'],
    driverKeys: <String>['UC', 'UC Drive'],
    requiredKeys: <String>['__pus', '__puus'],
    userAgent: kCookieLoginPcUserAgent,
    tip: '在下方网页里登录 UC 账号，登录成功后会自动提取 Cookie（需包含 __pus 与 __puus）。',
  ),
  CookieSite(
    id: 'baidu',
    label: '百度网盘',
    loginUrl: 'https://pan.baidu.com/',
    cookieUrls: <String>['https://pan.baidu.com'],
    driverKeys: <String>['BaiduNetdisk', 'Baidu'],
    requiredKeys: <String>['BDUSS'],
    userAgent: kCookieLoginPcUserAgent,
    tip: '在下方网页里登录百度账号，登录成功后会自动提取 Cookie（需包含 BDUSS）。',
  ),
  CookieSite(
    id: '115',
    label: '115 网盘',
    loginUrl: 'https://115.com/',
    cookieUrls: <String>['https://115.com', 'https://webapi.115.com'],
    driverKeys: <String>['115 Cloud', '115', '115Open'],
    requiredKeys: <String>['UID', 'CID'],
    tip: '在下方网页里登录 115 账号，登录成功后会自动提取 Cookie（需包含 UID 与 CID）。',
  ),
  CookieSite(
    id: 'c139',
    label: '移动云盘（139 / 和彩云）',
    loginUrl: 'https://yun.139.com/m/#/login',
    cookieUrls: <String>['https://yun.139.com', 'https://mail.10086.cn'],
    driverKeys: <String>['139Yun', '139', 'C139'],
    anyKeys: <String>[
      'authorization',
      'Login_UserNumber',
      'ORCHES-I-ACCOUNT-ENCRYPT',
    ],
    tip: '在下方网页里登录移动云盘账号，登录成功后会自动提取 Cookie。',
  ),
];

/// 按 id 找站点。
CookieSite? cookieSiteById(String id) {
  for (final site in kCookieSites) {
    if (site.id == id) return site;
  }
  return null;
}

/// 按 OpenList 驱动名找站点。
CookieSite? cookieSiteForDriver(String driver) {
  for (final site in kCookieSites) {
    if (site.matchesDriver(driver)) return site;
  }
  return null;
}
