import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'cookie_login_sites.dart';

/// 打开网盘官网登录页，登录完成后自动提取 Cookie。
///
/// 返回提取到的 Cookie 字符串；用户中途返回则返回 null。
Future<String?> showCookieLoginPage(BuildContext context, CookieSite site) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => CookieLoginPage(site: site)),
  );
}

/// 网盘登录 + 自动抓 Cookie 页面。
class CookieLoginPage extends StatefulWidget {
  const CookieLoginPage({super.key, required this.site});

  final CookieSite site;

  @override
  State<CookieLoginPage> createState() => _CookieLoginPageState();
}

class _CookieLoginPageState extends State<CookieLoginPage> {
  InAppWebViewController? _controller;
  Timer? _poll;
  String _cookie = '';
  bool _finishing = false;
  String _status = '等待登录…';

  InAppWebViewSettings get _webSettings => InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    supportZoom: true,
    builtInZoomControls: true,
    displayZoomControls: false,
    useWideViewPort: true,
    loadWithOverviewMode: true,
    userAgent: widget.site.userAgent,
  );

  @override
  void initState() {
    super.initState();
    // 登录过程没有可靠的回调，这里用轮询：Cookie 一旦带上登录态就直接完成
    _poll = Timer.periodic(
      const Duration(milliseconds: 1200),
      (_) => _capture(auto: true),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<String> _readCookie() async {
    final manager = CookieManager.instance();
    final parts = <String>[];
    final seen = <String>{};
    for (final url in widget.site.cookieUrls) {
      try {
        final cookies = await manager.getCookies(url: WebUri(url));
        for (final cookie in cookies) {
          final name = '${cookie.name}';
          final value = cookie.value == null ? '' : '${cookie.value}';
          if (name.isEmpty || value.isEmpty) continue;
          if (seen.add(name)) parts.add('$name=$value');
        }
      } catch (e) {
        debugPrint('读取 $url 的 Cookie 失败: $e');
      }
    }
    return parts.join('; ');
  }

  Future<void> _capture({required bool auto}) async {
    if (_finishing) return;
    final cookie = await _readCookie();
    if (!mounted) return;
    final valid = widget.site.isValidCookie(cookie);
    setState(() {
      _cookie = cookie;
      if (cookie.isEmpty) {
        _status = '等待登录…';
      } else if (valid) {
        _status = '已检测到登录态';
      } else {
        _status = '已拿到部分 Cookie，请继续完成登录';
      }
    });
    if (auto && valid) {
      _finish(cookie);
    }
  }

  void _finish(String cookie) {
    if (_finishing) return;
    _finishing = true;
    _poll?.cancel();
    Navigator.of(context).pop(cookie);
  }

  Future<void> _confirmClearCookie() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除登录状态'),
        content: const Text(
          '将清除本机 WebView 里的 Cookie（含该网盘已有的登录态），方便换账号登录。是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CookieManager.instance().deleteAllCookies();
    } catch (e) {
      debugPrint('清除 Cookie 失败: $e');
    }
    _controller?.reload();
    if (!mounted) return;
    setState(() {
      _cookie = '';
      _status = '请重新登录…';
    });
  }

  void _copyCookie() {
    if (_cookie.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _cookie));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cookie 已复制到剪贴板')));
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.site.tip.isEmpty
        ? '登录完成后会自动提取 Cookie，无需手动复制。'
        : widget.site.tip;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.site.label}登录'),
        actions: [
          IconButton(
            tooltip: '重新加载',
            onPressed: () => _controller?.reload(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '清除登录状态',
            onPressed: _confirmClearCookie,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(tip, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.site.loginUrl)),
              initialSettings: _webSettings,
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStop: (controller, url) {
                _capture(auto: true);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _status,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _cookie.isEmpty ? null : _copyCookie,
                    child: const Text('复制'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: _cookie.isEmpty ? null : () => _finish(_cookie),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
