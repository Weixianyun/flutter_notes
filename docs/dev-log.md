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

### Git 提交记录
```
74257e3 feat: Week 1 Day 1 - app skeleton, theme system, notes list UI
```

### 明日计划 (Week 1 Day 2)
- Riverpod 状态管理接入 (Provider 体系搭建)
- 笔记编辑器页面 UI 原型
- Markdown 渲染组件集成

## 2026-08-14 | Week 1 Day 2 — Riverpod 状态管理 + 编辑器 + Markdown 预览

### 今日完成

#### 1. Riverpod 状态管理接入

##### Provider 体系搭建
- `main.dart`: 添加 `ProviderScope` 包裹根组件，启用 Riverpod 依赖注入
- `lib/data/repositories/note_repository.dart`: 定义 `NoteRepository` 抽象接口 + `MockNoteRepository` 内存实现
  - CRUD 操作: `getAllNotes` / `getNoteById` / `addNote` / `updateNote` / `deleteNote`
  - 6 条 Mock 种子数据（含 Markdown 格式内容）
  - `List.from(_seedData)` 避免静态列表引用共享
- `lib/features/notes/providers/notes_provider.dart`: `NotesNotifier` (extends `Notifier<List<NoteModel>>`)
  - `noteRepositoryProvider`: Provider 暴露仓库实例
  - `notesProvider`: NotifierProvider 管理笔记列表状态
  - 所有变更同步写入仓库，确保数据一致性

##### 笔记列表页重构
- `notes_list_page.dart`: `StatefulWidget` → `ConsumerWidget`
  - `ref.watch(notesProvider)` 替代本地 `_notes` 状态
  - 删除/撤销通过 `ref.read(notesProvider.notifier)` 调用
  - 移除 `_generateMockNotes()` 方法（数据源迁移至 MockNoteRepository）

#### 2. 笔记编辑器页面 UI 原型

##### 编辑器状态管理
- `lib/features/editor/providers/editor_provider.dart`: `previewModeProvider` (StateProvider.autoDispose<bool>)
  - 管理 编辑/预览 模式切换，每次打开编辑器自动重置为编辑模式

##### 编辑器页面 (`note_editor_page.dart`)
- `ConsumerStatefulWidget` + `TextEditingController` 管理标题和内容输入
- 标题输入框（大字体粗体）+ 优先级 `SegmentedButton` 选择器 + 标签 `Chip` 列表
- Markdown 格式工具栏（10 个快捷按钮）: 加粗、斜体、行内代码、标题、无序列表、有序列表、引用、待办、链接、代码块
  - `_wrapSelection()`: 选中文本两侧包裹标记
  - `_insertPrefix()`: 行首插入前缀
- 编辑/预览模式切换（AppBar 图标按钮）
- `PopScope` 未保存更改退出确认对话框
- 保存逻辑: 空内容校验 → 新增/更新笔记 → SnackBar 提示 → 返回列表页

##### 路由对接
- `app_router.dart`: 编辑器路由从占位页面替换为 `NoteEditorPage`
  - `ModalRoute.of(context)?.settings.arguments` 传递 noteId 参数

#### 3. Markdown 渲染组件集成

##### Markdown 预览组件 (`markdown_preview.dart`)
- 基于 `flutter_markdown` 包，支持 `Markdown` (可滚动) 和 `MarkdownBody` (不可滚动) 两种模式
- 定制 `MarkdownStyleSheet` 适配 Material 3 主题:
  - h1/h2/h3 标题样式
  - 代码块/行内代码样式（monospace + surfaceContainerHighest 背景）
  - 引用块左侧边框装饰
  - 表格边框 + 表头加粗
  - 列表项目符号颜色
- `selectable: true` 支持文本选择

#### 4. 测试更新
- 重写 `test/widget_test.dart`（3 项测试）:
  1. 笔记列表渲染（标题 + FAB + Dismissible 卡片）
  2. FAB 点击打开编辑器（标题输入 + 内容输入 2 个 TextField）
  3. 编辑器预览切换（输入 Markdown → 切换预览 → 验证渲染结果）

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (3 tests)

### 技术决策
- Riverpod 2.x Notifier: 使用 `Notifier<T>` + `NotifierProvider`（非已废弃的 `StateNotifier`）
- 编辑器状态: TextEditingController 管理文本输入（保持光标控制），Riverpod 管理非文本状态（预览模式）
- autoDispose: `previewModeProvider` 使用 autoDispose，每次打开编辑器自动重置
- Mock 数据迁移: 从页面级 `_generateMockNotes()` 迁移至 `MockNoteRepository`，为 Week 2 drift 替换做准备
- 工具栏实现: 通过 `TextEditingController.selection` 操作选区，支持包裹和行首插入两种模式

### Git 提交记录
```
c3379dd feat: Week 1 Day 2 - Riverpod state management, note editor, Markdown preview
```

### 明日计划 (Week 1 Day 3)
- 搜索功能实现 (搜索页面 + Provider 过滤)
- 笔记标签管理系统
- 设置页面 UI

## 2026-08-14 | Week 1 Day 3 — 搜索功能 + 标签管理 + 设置页面

### 今日完成

#### 1. 搜索功能实现

##### 搜索 Provider (`lib/features/search/providers/search_provider.dart`)
- `searchQueryProvider` (StateProvider<String>): 搜索查询文本
- `searchResultsProvider` (Provider<List<NoteModel>>): 监听 notesProvider + searchQuery，按标题/内容/标签模糊匹配
- `SearchHistoryNotifier` (Notifier<List<String>>): 搜索历史管理（去重、限 10 条、增删清空）

##### 搜索页面 (`lib/features/search/pages/search_page.dart`)
- ConsumerStatefulWidget + TextEditingController + FocusNode（自动聚焦）
- 三态展示：无查询→搜索历史 / 有查询无结果→空状态 / 有结果→NoteCard 列表
- 搜索历史: InputChip 展示，支持点击回搜和单独删除
- 点击搜索结果进入编辑器并记录搜索历史

#### 2. 笔记标签管理系统

##### 标签 Provider (`lib/features/notes/providers/tags_provider.dart`)
- `allTagsProvider` (Provider<List<TagInfo>>): 从所有笔记提取去重标签，按使用频率降序排列
- `SelectedTagsNotifier` (Notifier<Set<String>>): 选中标签集合管理（toggle/select/clear）
- `filteredNotesProvider` (Provider<List<NoteModel>>): 无选中标签返回全部，否则返回包含任一选中标签的笔记
- `TagInfo` 数据类：标签名 + 使用次数

##### 标签过滤栏 (`lib/features/notes/widgets/tag_filter_bar.dart`)
- 水平滚动 FilterChip 列表，「全部」+ 各标签（显示名称和计数）
- 多选过滤，点击「全部」清除所有选中标签
- 无标签时自动隐藏（SizedBox.shrink）

##### 笔记列表页集成
- `notes_list_page.dart`: 从 `notesProvider` 改为 `filteredNotesProvider`
- 新增标签过滤栏（Column 布局，栏 + Expanded 列表）
- 新增过滤无结果空状态（带「清除筛选」操作按钮）

#### 3. 设置页面 UI

##### 设置 Provider (`lib/features/settings/providers/settings_provider.dart`)
- `ThemeModeNotifier` (Notifier<ThemeMode>): 主题模式状态（system/light/dark）
- `appVersion` / `githubRepoUrl` 常量

##### 设置页面 (`lib/features/settings/pages/settings_page.dart`)
- 四个分区：外观 / 云同步 / 数据管理 / 关于
- 外观: SegmentedButton 三档主题模式切换（浅色/系统/深色）
- 云同步: GitHub 同步 + 加密设置（信息弹窗占位）
- 数据管理: 导出/导入笔记 + 清空确认对话框
- 关于: 版本号 + GitHub 仓库链接 + 开源许可页面

#### 4. 应用集成

##### 路由对接
- `app_router.dart`: search 和 settings 路由从占位页面替换为真实页面
- 移除 `_PlaceholderPage` 内部类，未知路由改为 404 页面

##### 主题模式集成
- `app.dart`: StatelessWidget → ConsumerWidget
- 通过 `ref.watch(themeModeProvider)` 动态控制 MaterialApp.themeMode
- 主题切换实时生效，无需重启应用

#### 5. 测试更新
- 扩展 `test/widget_test.dart` 至 6 项测试:
  1. 笔记列表渲染（标题 + FAB + Dismissible + FilterChip 标签栏）
  2. FAB 打开编辑器（2 个 TextField）
  3. 编辑器预览切换（Markdown 渲染验证）
  4. 搜索页面空状态（搜索框 + 提示文本）
  5. 搜索过滤（输入"Dart"→匹配笔记卡片）
  6. 设置页面（主题选择器 + 滚动至版本信息）

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (6 tests)

### 技术决策
- 搜索 Provider 设计: 使用 Provider 组合（watch notesProvider + searchQueryProvider）而非在 Notifier 内管理，保持单向数据流
- 标签过滤: OR 逻辑（包含任一选中标签即显示），多选模式适合探索性浏览
- 主题模式: StateProvider → Notifier，为后续 shared_preferences 持久化预留接口
- ActionChip → InputChip: Material 3 中 ActionChip 不支持 onDeleted，搜索历史需删除功能改用 InputChip
- 过滤空状态: 区分「无笔记」和「有笔记但过滤无结果」两种空状态，提供不同的操作引导

### Git 提交记录
```
b5b69f5 feat: Week 1 Day 3 - search, tag management, settings page
```

### 明日计划 (Week 1 Day 4)
- drift 数据库集成 (表结构定义 + 代码生成)
- NoteRepository 从 Mock 迁移至 DriftNoteRepository
- 数据库迁移与种子数据

## 2026-08-14 | Week 1 Day 4 — drift 数据库集成

### 今日完成

#### 1. drift 表定义与数据库类

##### 数据库 Schema (`lib/data/database/app_database.dart`)
- 定义 `Notes` 表结构，8 列与 `NoteModel` 字段一一对应:
  - `id` (TEXT, 主键, UUID), `title` (TEXT, 默认空串)
  - `content` (TEXT, 默认空串), `priority` (TEXT, 默认 medium)
  - `status` (TEXT, 默认 draft), `tags` (TEXT, 默认 [] JSON 数组)
  - `createdAt` / `updatedAt` (DateTime, 默认 currentDateAndTime)
- `AppDatabase` 继承 `_$AppDatabase`，schemaVersion = 1
- `MigrationStrategy.onCreate`: 建表 + 插入 6 条种子数据（与 Mock 数据一致）
- `_openConnection()`: 使用 `path_provider` 获取文档目录，`NativeDatabase` 持久化到 `flutter_notes.db`
- `AppDatabase.forTesting()`: 内存数据库构造函数，用于单元/Widget 测试

##### 数据库 Provider (`lib/data/database/database_provider.dart`)
- `appDatabaseProvider`: 全局单例 `AppDatabase`，`ref.onDispose` 自动关闭连接
- 测试时通过 override 替换为 `AppDatabase.forTesting()`

#### 2. build_runner 代码生成
- `dart run build_runner build --delete-conflicting-outputs` 生成 `app_database.g.dart`
- 生成内容: `$NotesTable` 表信息类、`Note` 数据类、`NotesCompanion` 伴生类、`_$AppDatabase` 数据库实现
- 构建耗时 31s，49 个输出文件

#### 3. Repository 接口异步化 + DriftNoteRepository

##### 接口异步化 (`lib/data/repositories/note_repository.dart`)
- `NoteRepository` 抽象接口: 所有方法改为 `Future<T>` / `Stream<T>` 返回类型
- 新增 `watchAllNotes()`: 返回 `Stream<List<NoteModel>>`，支持响应式数据监听
- `MockNoteRepository`: 保持兼容，所有方法改为 async，`watchAllNotes` 产出单次快照

##### DriftNoteRepository 实现
- 基于 `AppDatabase` 实现 CRUD，通过 `_toModel()` / `_toCompanion()` 在 `Note`（drift 实体）和 `NoteModel`（领域模型）间转换
- `tags` 字段: JSON 字符串 ↔ `List<String>`（`jsonEncode` / `jsonDecode`）
- `priority` / `status` 字段: 枚举名称字符串 ↔ 枚举值（`name` / `firstWhere`）
- 查询使用 `select` + `orderBy`（按 `updatedAt` 倒序）+ `where`（按 `id` 过滤）

#### 4. NotesNotifier → AsyncNotifier

##### 状态管理重构 (`lib/features/notes/providers/notes_provider.dart`)
- `NotesNotifier`: `Notifier<List<NoteModel>>` → `AsyncNotifier<List<NoteModel>>`
- `build()`: 异步调用 `repository.getAllNotes()`，返回 `Future<List<NoteModel>>`
- `addNote` / `updateNote` / `deleteNote`: 异步写入后 `ref.invalidateSelf()` 触发重建
- `getNoteById`: 改为 `Future<NoteModel?>`，编辑器页异步加载笔记
- `noteRepositoryProvider`: `MockNoteRepository` → `DriftNoteRepository(appDatabaseProvider)`

#### 5. 标签/搜索 Provider 适配 AsyncValue

##### 标签 Provider (`lib/features/notes/providers/tags_provider.dart`)
- `allTagsProvider`: 返回类型 `List<TagInfo>` → `AsyncValue<List<TagInfo>>`，使用 `whenData` 转换
- `filteredNotesProvider`: 返回类型 `List<NoteModel>` → `AsyncValue<List<NoteModel>>`，使用 `whenData` 过滤
- `SelectedTagsNotifier`: 保持同步（不依赖数据库）

##### 搜索 Provider (`lib/features/search/providers/search_provider.dart`)
- `searchResultsProvider`: 返回类型 `List<NoteModel>` → `AsyncValue<List<NoteModel>>`，使用 `whenData` 过滤
- `SearchHistoryNotifier`: 保持同步（不依赖数据库）

#### 6. UI 页面适配异步状态

##### 笔记列表页 (`notes_list_page.dart`)
- `filteredNotesProvider` / `notesProvider` / `allTagsProvider` 均返回 `AsyncValue`
- 三态渲染: `loading` → CircularProgressIndicator, `error` → 错误重试空状态, `data` → 笔记列表
- 标签栏: `allTagsProvider.maybeWhen` 判断是否有标签
- 删除操作: `ref.read(notesProvider.notifier).deleteNote()` 返回 Future（fire-and-forget）

##### 编辑器页 (`note_editor_page.dart`)
- `initState`: 异步调用 `getNoteById()` 加载笔记，新增 `_isLoading` / `_isSaving` 状态
- `_loadNote()`: 异步加载完成后填充控制器和状态
- `_save()`: 改为 `async`，等待 `addNote` / `updateNote` 完成后再 pop
- 保存按钮: `_isSaving` 时禁用（`onPressed: null`）

##### 标签过滤栏 (`tag_filter_bar.dart`)
- `allTagsProvider` 返回 `AsyncValue`，使用 `.when()` 三态处理
- loading/error 时返回 `SizedBox.shrink()`（不显示标签栏）

##### 搜索页 (`search_page.dart`)
- `searchResultsProvider` 返回 `AsyncValue`，使用 `.when()` 三态处理
- 搜索中显示加载指示器，出错显示错误空状态

#### 7. 测试适配
- `test/widget_test.dart`: 添加 `appDatabaseProvider` override 为 `AppDatabase.forTesting()`
- `driftRuntimeOptions.dontWarnAboutMultipleDatabases = true` 抑制测试中多数据库实例警告
- 6 项测试全部通过，种子数据从 drift 数据库加载

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (6 tests)

### 技术决策
- `AsyncNotifier` vs `StreamNotifier`: 选择 `AsyncNotifier` + `ref.invalidateSelf()` 方案，简洁直观；`watchAllNotes()` Stream 保留在 Repository 接口供未来响应式更新使用
- `whenData` 转换: 派生 Provider（标签、搜索、过滤）使用 `AsyncValue.whenData()` 链式转换，自动传递 loading/error 状态
- `Constant` vs `Value`: drift 中 `Constant` 是 SQL 表达式（用于列默认值），`Value` 是伴生对象参数类型，种子数据必须使用 `Value`
- 内存数据库测试: `AppDatabase.forTesting()` + `NativeDatabase.memory()` 实现 SQLite 内存模式，每个测试独立隔离
- Fire-and-forget 删除: `deleteNote` 返回 Future 但 UI 不 await，Snackbar 撤销通过 `addNote` 恢复，`invalidateSelf` 最终保证一致性

### Git 提交记录
```
(commit hash pending)
```

### 明日计划 (Week 1 Day 5)
- 加密存储集成 (AES-256 + encrypt 包)
- shared_preferences 持久化设置 (主题模式等)
- 数据库 Repository 单元测试
