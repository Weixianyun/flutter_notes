import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/github_config.dart';
import '../../../services/service_providers.dart';
import '../providers/sync_provider.dart';

/// GitHub OAuth 登录页
///
/// 使用 WebView 加载 GitHub 授权页面，用户授权后拦截回调 URL
/// 获取 authorization_code，交换为 access_token 并加密存储。
class GitHubLoginPage extends ConsumerStatefulWidget {
  const GitHubLoginPage({super.key});

  @override
  ConsumerState<GitHubLoginPage> createState() => _GitHubLoginPageState();
}

class _GitHubLoginPageState extends ConsumerState<GitHubLoginPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isExchanging = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            // 拦截回调 URL
            if (request.url.startsWith(GitHubConfig.redirectUri)) {
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(GitHubConfig.authorizationUrl));
  }

  Future<void> _handleRedirect(String url) async {
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];

    if (code == null) {
      if (mounted) {
        setState(() {
          _error = '未获取到授权码';
          _isExchanging = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isExchanging = true);

    try {
      final github = ref.read(githubServiceProvider);
      final token = await github.exchangeCodeForToken(code);
      await ref.read(syncProvider.notifier).saveToken(token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GitHub 授权成功')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '授权失败: $e';
          _isExchanging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub 登录'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // 加载指示器
          if (_isLoading && !_isExchanging)
            const LinearProgressIndicator(),

          // Token 交换中
          if (_isExchanging)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('正在获取访问令牌...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 错误提示
          if (_error != null && !_isExchanging)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _controller.loadRequest(
                          Uri.parse(GitHubConfig.authorizationUrl),
                        );
                      },
                      child: const Text('重试'),
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
