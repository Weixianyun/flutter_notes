# 开发日志

## 2026-08-13 | 环境搭建 + 项目初始化

### 今日完成

#### Step 1-3: 开发环境搭建
- 安装 Flutter SDK 3.44.9 (stable channel) 到 `C:\flutter`
- 安装 Android Studio 2026.1.3.7 + Android SDK 36 + Build Tools 34/36
- 安装 Git 2.55.0,配置用户信息 `weixianyun <weixianyun55@gmail.com>`
- 生成 SSH ed25519 密钥并添加到 GitHub
- 配置国内镜像 (PUB_HOSTED_URL / FLUTTER_STORAGE_BASE_URL)
- 配置环境变量 (JAVA_HOME / ANDROID_SDK_ROOT / PATH)
- 接受 Android SDK 许可协议
- 创建 Android 模拟器 Pixel_7 (Android 16, API 36)
- 启用 Windows 开发者模式 (插件符号链接支持)

#### Step 4: 项目初始化
- `flutter create --org com.weixianyun flutter_notes` 创建项目
- 配置 pubspec.yaml 依赖 (14 个包):
  - 状态管理: flutter_riverpod, riverpod_annotation
  - 数据库: sqflite, drift, sqlite3_flutter_libs
  - Markdown: flutter_markdown, markdown
  - 加密: encrypt, crypto
  - 网络: http, oauth2, webview_flutter
  - 工具: uuid, intl, shared_preferences, path_provider
- 建立目录结构: core/{theme,router,utils}, data/{database,models,repositories}, features/{editor,notes,graph,search,sync}, services/, shared/widgets/
- 配置 analysis_options.yaml (4 条 lint 规则)
- 创建 app.dart (MaterialApp + 明暗主题) 和 main.dart (入口)
- flutter pub get 成功安装 109 个依赖包
- Git 初始化 + 2 次提交
- flutter run 模拟器验证通过

### 解决的兼容性问题
1. **file_picker 6.2.1 v1 API 废弃**: 升级到 11.0.3,但与 AGP 9.0 Kotlin 冲突,暂时移除,Week 9 再添加
2. **Kotlin 增量编译缓存损坏**: 项目路径含空格导致,设置 `kotlin.incremental=false`
3. **Windows 开发者模式**: 插件符号链接需要,通过注册表开启
4. **NDK / CMake 自动安装**: 首次 Gradle 构建时自动下载安装

### 技术决策
- `android.builtInKotlin=false`: 保持 `android.newDsl=false`,兼容现有插件
- `kotlin.incremental=false`: 避免路径空格导致的缓存问题
- `file_picker` 延后: AGP 9.0 与 file_picker 11.x Kotlin 实现不兼容,Week 9 再处理

### Git 提交记录
```
a549d39 fix: disable Kotlin incremental compilation, defer file_picker to Week 9
ea6bfe8 chore: initial Flutter project setup
```

### 明日计划 (Week 1 Day 1)
- Dart 语言基础复习 (类型系统、空安全、异步)
- 搭建应用骨架: 路由配置、主题系统
- 创建笔记列表页面 UI 原型

### 遗留事项
- [ ] TraeCode 安装 Flutter 插件
- [ ] GitHub OAuth App 创建 (需 callback URL: `flutternotes://oauth/callback`)
- [ ] GitHub 仓库创建并推送代码
- [ ] file_picker 兼容性问题 (Week 9 解决)
