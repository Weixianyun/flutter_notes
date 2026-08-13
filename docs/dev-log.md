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

## 2026-08-13 | README 中英文双语

### 今日完成

#### README 中英文可切换
- 创建 `README.md` (英文版),顶部添加语言切换链接
- 创建 `README_zh.md` (中文版),顶部添加语言切换链接
- 两份 README 均包含完整项目信息:
  - 功能特性、技术栈表格
  - 项目目录结构树
  - 安装与运行指南
  - 代码生成与代码检查说明
  - 开发日志链接

### Git 提交记录
```
fb700d5 docs: add bilingual README with Chinese-English toggle
```

## 2026-08-13 | 遗留事项完成

### 今日完成

#### 环境配置收尾
- **TraeCode Flutter 插件**: 已安装,支持 Dart/Flutter 语法高亮、代码补全、调试
- **GitHub OAuth App**: 已创建,callback URL `flutternotes://oauth/callback`,为后续 GitHub 云同步功能做好准备

### 遗留事项状态
- [x] TraeCode 安装 Flutter 插件
- [x] GitHub OAuth App 创建 (callback URL: `flutternotes://oauth/callback`)
- [x] GitHub 仓库创建并推送代码
- [ ] file_picker 兼容性问题 (Week 9 解决)

### Git 提交记录
```
3b82761 docs: mark TraeCode Flutter plugin and GitHub OAuth App as completed
```

## 2026-08-13 | Week 1 Day 1 — Dart 基础 + 应用骨架 + 笔记列表 UI

### 今日完成

#### 1. Dart 语言基础复习
- 创建 `docs/dart-basics.md` 学习笔记，涵盖：
  - 类型系统：强类型、类型推断、final/const 区别、泛型、Record（Dart 3）、Pattern Matching
  - 空安全：健全空安全规则、`?` `!` `??` `?.` `??=` 操作符、流程提升、`late` 关键字
  - 异步编程：Future、Stream、async/await、async*/sync* 生成器、错误处理、Future 常用方法、Zone
  - 结合本项目实践要点（模型类空安全、JSON 解析、UI 条件渲染）

#### 2. 应用骨架搭建

##### 主题系统 (`lib/core/theme/`)
- `app_colors.dart`: 定义种子色、明暗主题色板、功能色、笔记优先级标签色
- `app_theme.dart`: 基于 `ColorScheme.fromSeed` 生成 Material 3 主题，定制 AppBar、Card、ListTile、FAB、输入框、分隔线、导航栏样式

##### 路由配置 (`lib/core/router/`)
- `app_router.dart`: 命名路由表（home/editor/search/settings），`onGenerateRoute` 支持未知路由兜底，占位页面为后续功能预留

##### 入口集成
- 更新 `app.dart`: 集成 `AppTheme.light/dark` + `AppRouter`，移除硬编码主题和 home 页面

#### 3. 笔记列表页 UI 原型

##### 数据模型 (`lib/data/models/`)
- `note_model.dart`: `NoteModel` 数据类（id/title/content/priority/status/tags/createdAt/updatedAt）
  - `NotePriority` 和 `NoteStatus` 枚举
  - `fromJson`/`toJson`/`copyWith`/`excerpt`/`isEmpty` 方法
  - `==`/`hashCode` 基于 id 重写

##### 笔记列表页面 (`lib/features/notes/pages/`)
- `notes_list_page.dart`: 首页列表，包含：
  - AppBar 搜索/更多入口
  - ListView + NoteCard 卡片列表
  - Dismissible 滑动删除（带撤销 SnackBar）
  - 长按弹出操作菜单（复制/分享/归档/删除）
  - FloatingActionButton 新建笔记
  - 空状态展示（EmptyState 组件）
  - 6 条 Mock 数据（涵盖各优先级和标签）

##### 复用组件 (`lib/features/notes/widgets/` + `lib/shared/widgets/`)
- `note_card.dart`: 笔记卡片（标题、摘要、优先级指示点、标签芯片、更新时间）
- `empty_state.dart`: 通用空状态组件（图标、标题、副标题、操作按钮）

#### 4. 测试更新
- 重写 `test/widget_test.dart`：替换旧计数器测试，新增笔记列表页渲染测试和滑动删除测试

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (2 tests)

### 技术决策
- 命名路由 vs go_router: 当前使用 Flutter 内置命名路由，Week 3 引入 go_router 时可平滑迁移
- Mock 数据: 在 `_NotesListPageState` 中生成 6 条假数据，Week 2 接入 drift 后替换为数据库查询
- Card 零阴影设计: 使用 `surfaceContainerHighest` 背景色 + 圆角，Material 3 风格

### 明日计划 (Week 1 Day 2)
- Riverpod 状态管理接入 (Provider 体系搭建)
- 笔记编辑器页面 UI 原型
- Markdown 渲染组件集成
