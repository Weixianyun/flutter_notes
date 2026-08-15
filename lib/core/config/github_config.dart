/// GitHub OAuth 配置
///
/// 在 GitHub Settings → Developer settings → OAuth Apps 中创建应用后，
/// 将下方占位值替换为你的真实 Client ID 和 Client Secret。
///
/// ⚠️ 安全警告：将 client_secret 嵌入客户端代码存在安全风险。
/// 生产环境应使用后端服务器中转 token 交换，或改用 Device Flow。
/// 当前方案仅适用于个人项目/原型开发。
class GitHubConfig {
  GitHubConfig._();

  /// OAuth App Client ID
  static const String clientId = 'Ov23li-placeholder-replace-me';

  /// OAuth App Client Secret
  static const String clientSecret = 'placeholder-replace-me';

  /// 授权回调地址（WebView 中拦截，不实际加载）
  static const String redirectUri = 'http://localhost:8080/callback';

  /// 请求的权限范围
  /// - repo: 仓库读写（含私有仓库）
  static const String scope = 'repo';

  /// GitHub OAuth 授权页 URL
  static String get authorizationUrl {
    return 'https://github.com/login/oauth/authorize'
        '?client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&scope=$scope'
        '&state=flutter_notes_oauth';
  }

  /// GitHub OAuth token 交换端点
  static const String tokenUrl =
      'https://github.com/login/oauth/access_token';

  /// GitHub REST API 基础地址
  static const String apiBaseUrl = 'https://api.github.com';
}
