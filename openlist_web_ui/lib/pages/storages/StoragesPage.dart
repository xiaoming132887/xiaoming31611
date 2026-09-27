import 'package:openlist_config/config/config.dart';
import 'package:openlist_web_ui/pages/storages/QuickAddStoragePage.dart';
import 'package:openlist_web_ui/pages/web/web.dart';
import 'package:flutter/material.dart';

class StoragesPage extends StatefulWidget {
  const StoragesPage({super.key});

  @override
  State<StoragesPage> createState() => _StoragesPageState();
}

class _StoragesPageState extends State<StoragesPage> {
  final GlobalKey<WebScreenState> _webKey = GlobalKey<WebScreenState>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: WebScreen(
            key: _webKey,
            startUrl: "$AListAPIBaseUrl/@manage/storages",
          ),
        ),
        // 网页端管理页要手动粘贴 Cookie；这里给一个「登录后自动取 Cookie」的入口
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'quick_add_storage',
            onPressed: _openQuickAddStorage,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('一键添加网盘'),
          ),
        ),
      ],
    );
  }

  Future<void> _openQuickAddStorage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const QuickAddStoragePage()),
    );
    if (created == true) {
      _webKey.currentState?.reload();
    }
  }
}
