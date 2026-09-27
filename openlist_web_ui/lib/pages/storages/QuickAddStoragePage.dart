import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:openlist_utils/getDIO.dart';
import 'package:openlist_utils/toast.dart';

import 'CookieLoginPage.dart';
import 'cookie_login_sites.dart';

/// 「一键添加网盘」：选网盘 → 网页登录 → 自动提取 Cookie → 直接创建 OpenList 存储。
///
/// 原来的做法是在网页端管理页面里手动粘贴 Cookie（用户得自己去浏览器开发者工具里复制），
/// 这里把「登录」和「写入存储配置」串成一条链，Cookie 全程由 App 自己抓。
class QuickAddStoragePage extends StatefulWidget {
  const QuickAddStoragePage({super.key});

  @override
  State<QuickAddStoragePage> createState() => _QuickAddStoragePageState();
}

class _QuickAddStoragePageState extends State<QuickAddStoragePage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _drivers = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = getDIO();
      final response = await dio.getUri(Uri.parse('/api/admin/driver/list'));
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'];
        setState(() {
          _drivers = data is Map
              ? data.cast<String, dynamic>()
              : <String, dynamic>{};
          _loading = false;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = '读取驱动列表失败：${response.data['message'] ?? response.data}';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '读取驱动列表失败：$e';
      });
    }
  }

  /// 找到该网盘对应的 OpenList 驱动名。
  String? _driverForSite(CookieSite site) {
    for (final name in _drivers.keys) {
      if (site.matchesDriver(name)) return name;
    }
    return null;
  }

  Future<void> _startWithSite(CookieSite site, {String? driver}) async {
    final targetDriver = driver ?? _driverForSite(site);
    if (targetDriver == null) {
      show_failed('驱动列表里没有找到「${site.label}」，请在网页端手动添加', context);
      return;
    }
    // 1) 网页登录并抓 Cookie
    final cookie = await showCookieLoginPage(context, site);
    if (!mounted || cookie == null || cookie.trim().isEmpty) return;
    if (!site.isValidCookie(cookie)) {
      show_failed('没有检测到有效登录态，请重新登录', context);
      return;
    }
    // 2) 确认挂载信息
    final form = await _askCreateForm(site, targetDriver);
    if (!mounted || form == null) return;
    // 3) 直接调 OpenList 接口创建存储，Cookie 写进去
    final ok = await _createStorage(
      driver: targetDriver,
      cookie: cookie,
      form: form,
    );
    if (!mounted) return;
    if (ok) {
      show_success(
        '已添加「${form.remark.isEmpty ? site.label : form.remark}」',
        context,
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<_CreateForm?> _askCreateForm(CookieSite site, String driver) {
    final mount = TextEditingController(text: '/${site.label}');
    final root = TextEditingController(text: '/');
    final remark = TextEditingController(text: site.label);
    return showDialog<_CreateForm>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('添加 $driver'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: mount,
                decoration: const InputDecoration(
                  labelText: '挂载路径',
                  hintText: '/夸克网盘',
                ),
              ),
              TextField(
                controller: root,
                decoration: const InputDecoration(
                  labelText: '根文件夹路径',
                  hintText: '/',
                ),
              ),
              TextField(
                controller: remark,
                decoration: const InputDecoration(labelText: '备注'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cookie 已自动获取，无需手动粘贴。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final path = mount.text.trim();
              if (path.isEmpty || !path.startsWith('/')) {
                show_failed('挂载路径必须以 / 开头', ctx);
                return;
              }
              Navigator.of(ctx).pop(
                _CreateForm(
                  mountPath: path,
                  rootFolderPath: root.text.trim().isEmpty
                      ? '/'
                      : root.text.trim(),
                  remark: remark.text.trim(),
                ),
              );
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<bool> _createStorage({
    required String driver,
    required String cookie,
    required _CreateForm form,
  }) async {
    final schema = _drivers[driver];
    final common = (schema is Map && schema['common'] is List)
        ? schema['common'] as List
        : const <dynamic>[];
    final additional = (schema is Map && schema['additional'] is List)
        ? schema['additional'] as List
        : const <dynamic>[];

    final payload = <String, dynamic>{'driver': driver};
    // 驱动自己的字段先按默认值铺一遍，避免漏字段导致创建失败
    for (final raw in common) {
      if (raw is! Map) continue;
      final field = raw.cast<String, dynamic>();
      final name = '${field['name']}';
      if (name.isEmpty || name == 'null') continue;
      payload[name] = _defaultValueOf(field);
    }

    // Cookie 字段名各驱动不尽相同
    final cookieField = payload.keys.firstWhere(
      (key) => key.toLowerCase().contains('cookie'),
      orElse: () => 'cookie',
    );
    payload[cookieField] = cookie;

    if (payload.containsKey('root_folder_path')) {
      payload['root_folder_path'] = form.rootFolderPath;
    }
    if (payload.containsKey('root_folder_id')) {
      payload['root_folder_id'] = form.rootFolderPath;
    }

    payload['mount_path'] = form.mountPath;
    payload['remark'] = form.remark;
    payload.putIfAbsent('order', () => 0);
    payload.putIfAbsent('cache_expiration', () => 30);
    payload.putIfAbsent('status', () => 'work');
    payload.putIfAbsent('web_proxy', () => false);
    payload.putIfAbsent('webdav_policy', () => '302_redirect');
    payload.putIfAbsent('order_by', () => 'name');
    payload.putIfAbsent('order_direction', () => 'asc');
    payload.putIfAbsent('enable_sign', () => false);
    payload.putIfAbsent('extract_folder', () => '');
    payload.putIfAbsent('down_proxy_url', () => '');

    final addition = <String, dynamic>{};
    for (final raw in additional) {
      if (raw is! Map) continue;
      final field = raw.cast<String, dynamic>();
      final name = '${field['name']}';
      if (name.isEmpty || name == 'null') continue;
      addition[name] = _defaultValueOf(field);
    }
    payload['addition'] = jsonEncode(addition);

    try {
      final dio = getDIO();
      final response = await dio.postUri(
        Uri.parse('/api/admin/storage/create'),
        data: payload,
      );
      if (response.statusCode == 200 && response.data['code'] == 200) {
        return true;
      }
      if (mounted) {
        show_failed(
          '创建失败：${response.data['message'] ?? response.data}',
          context,
        );
      }
    } catch (e) {
      if (mounted) show_failed('创建失败：$e', context);
    }
    return false;
  }

  dynamic _defaultValueOf(Map<String, dynamic> field) {
    final value = field['default'];
    switch ('${field['type']}') {
      case 'bool':
        return value == true || '$value'.toLowerCase() == 'true';
      case 'number':
        return num.tryParse('$value') ?? 0;
      case 'float':
        return double.tryParse('$value') ?? 0.0;
      default:
        return value ?? '';
    }
  }

  Future<void> _startWithCustomUrl() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('自定义登录网址'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: '网盘登录页地址',
            hintText: 'https://example.com/login',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (!text.startsWith('http://') && !text.startsWith('https://')) {
                show_failed('请输入完整网址（http/https）', ctx);
                return;
              }
              Navigator.of(ctx).pop(text);
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
    if (!mounted || url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      show_failed('网址解析失败', context);
      return;
    }
    final driver = await _chooseDriver();
    if (!mounted || driver == null) return;
    final site = CookieSite(
      id: 'custom',
      label: uri.host,
      loginUrl: url,
      cookieUrls: <String>['${uri.scheme}://${uri.host}'],
      tip: '登录完成后会自动提取该域名下的 Cookie。',
    );
    await _startWithSite(site, driver: driver);
  }

  Future<String?> _chooseDriver() {
    final names = _drivers.keys.toList()..sort();
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择对应的 OpenList 驱动'),
        children: names
            .map(
              (name) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(name),
                child: Text(name),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('一键添加网盘'),
        actions: [
          IconButton(
            tooltip: '刷新驱动列表',
            onPressed: _loading ? null : _loadDrivers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadDrivers, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final tiles = <Widget>[
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          '选择网盘 → 在网页里登录 → 自动把 Cookie 写进存储配置，不用再手动复制粘贴。',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    ];
    for (final site in kCookieSites) {
      final driver = _driverForSite(site);
      tiles.add(
        ListTile(
          leading: const Icon(Icons.cloud_outlined),
          title: Text(site.label),
          subtitle: Text(driver == null ? '未安装对应驱动' : '驱动：$driver'),
          trailing: driver == null
              ? const Icon(Icons.block, color: Colors.grey)
              : const Icon(Icons.chevron_right),
          enabled: driver != null,
          onTap: driver == null
              ? null
              : () => _startWithSite(site, driver: driver),
        ),
      );
    }
    tiles.add(const Divider());
    tiles.add(
      ListTile(
        leading: const Icon(Icons.link),
        title: const Text('其它网盘（自定义登录网址）'),
        subtitle: const Text('不在上面的网盘也能用，登录后同样自动提取 Cookie'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _startWithCustomUrl,
      ),
    );
    return ListView(children: tiles);
  }
}

class _CreateForm {
  const _CreateForm({
    required this.mountPath,
    required this.rootFolderPath,
    required this.remark,
  });

  final String mountPath;
  final String rootFolderPath;
  final String remark;
}
