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
11a976c feat: Week 1 Day 4 - drift database integration with async state management
```

### 明日计划 (Week 1 Day 5)
- 加密存储集成 (AES-256 + encrypt 包)
- shared_preferences 持久化设置 (主题模式等)
- 数据库 Repository 单元测试

## 2026-08-14 | Week 1 Day 5 — 加密存储 + 偏好持久化 + 单元测试

### 今日完成

#### 1. AES-256 加密服务 (`lib/services/crypto_service.dart`)

##### 加密实现
- 使用 `encrypt` 包的 `AES` + `AESMode.cbc` + PKCS7 填充
- 密钥: 32 字节 (256 bits)，通过 `Key.fromLength(32)` 生成（内部使用 `Random.secure()`）
- IV: 16 字节 (128 bits)，每次加密独立生成随机 IV
- 密文格式: `base64(IV):base64(ciphertext)`，Base64 字符集不含 `:`，分隔安全

##### 密钥管理
- 首次使用时自动生成密钥，以 Base64 编码存储在 `SharedPreferences`
- 后续实例从 `SharedPreferences` 加载已有密钥，确保跨会话解密一致性
- `regenerateKey()`: 重新生成密钥（已加密数据将无法解密）
- `hasKey`: 检查密钥是否存在，用于设置页展示加密状态

##### 边界处理
- 空字符串特殊处理: `encrypt('')` 返回 `base64(IV):`（ciphertext 部分为空），`decrypt` 识别空 ciphertext 直接返回空串
- `FormatException`: 密文格式不合法时抛出异常
- `encryptBytes` / `decryptBytes`: 字节数据加密/解密（通过 UTF-8 编解码桥接）

##### Provider 集成
- `lib/services/service_providers.dart`: 创建 `sharedPreferencesProvider`、`preferencesServiceProvider`、`encryptionServiceProvider`
- `sharedPreferencesProvider` 必须在 `main.dart` 中 override（强制初始化模式）
- `encryptionServiceProvider` 依赖 `sharedPreferencesProvider`，自动获取密钥

#### 2. shared_preferences 偏好持久化

##### PreferencesService (`lib/services/preferences_service.dart`)
- 封装 `SharedPreferences`，提供类型安全的设置项读写
- 主题模式: `getThemeMode()` / `setThemeMode(ThemeMode)` — 默认跟随系统
- Markdown 自动预览: `getMarkdownAutoPreview()` / `setMarkdownAutoPreview(bool)` — 默认开启
- 默认优先级: `getDefaultPriority()` / `setDefaultPriority(String)` — 默认 medium

##### 应用初始化 (`lib/main.dart`)
- `WidgetsFlutterBinding.ensureInitialized()` 确保 Flutter 绑定初始化
- `SharedPreferences.getInstance()` 异步获取实例
- `ProviderScope.overrides` 注入 `sharedPreferencesProvider`

##### 主题模式持久化 (`lib/features/settings/providers/settings_provider.dart`)
- `ThemeModeNotifier.build()`: 从 `PreferencesService` 读取已保存的主题模式
- `ThemeModeNotifier.setMode()`: 更新状态并异步写入 `SharedPreferences`
- 应用重启后自动恢复上次选择的主题模式
- 新增 `encryptionStatusProvider`: 暴露加密状态供设置页使用

##### 设置页增强 (`lib/features/settings/pages/settings_page.dart`)
- 加密设置: 根据 `encryptionStatusProvider` 展示锁定/解锁图标和状态文本
- 清空所有笔记: 调用 `NotesNotifier.clearAllNotes()` 实现真实清空逻辑
- 加密信息弹窗: 根据 `isEncrypted` 展示不同内容

##### NotesNotifier 扩展
- 新增 `clearAllNotes()`: 获取所有笔记并逐条删除，最后 `invalidateSelf()`

#### 3. 数据库 Repository 单元测试 (`test/repositories/note_repository_test.dart`)

##### 测试覆盖 (18 项)
- `getAllNotes`: 验证种子数据排序（updatedAt 倒序）和标题完整性
- `getNoteById`: 验证存在/不存在 ID 的返回值
- `addNote`: 验证新增笔记可检索、计数增加、标签 JSON 数组保持
- `updateNote`: 验证字段更新、标签更新、不产生重复
- `deleteNote`: 验证删除后计数减少、getNoteById 返回 null、不存在的 ID 不抛异常
- `watchAllNotes`: 验证初始数据发射和数据变更后更新
- 实体转换: 优先级枚举、状态枚举、空标签列表、特殊字符（表情/引号/符号）往返测试

##### 测试模式
- `setUp`: 每个测试创建独立的 `AppDatabase.forTesting()` 内存数据库
- `tearDown`: 关闭数据库连接
- 使用 `expectLater` + `completes` 验证异步不抛异常

#### 4. 加密服务单元测试 (`test/services/encryption_service_test.dart`)

##### 测试覆盖 (16 项)
- 密钥管理: 首次生成存储、hasKey 判断、跨实例复用、regenerateKey 生成不同密钥
- 加解密: 往返测试、密文不同于明文、随机 IV 产生不同密文、空字符串、长文本、特殊字符、JSON 内容
- 错误处理: 无效格式抛 FormatException、缺少分隔符抛 FormatException
- 字节数据: encryptBytes/decryptBytes 往返
- 跨实例解密: 实例 A 加密、实例 B 解密

#### 5. Widget 测试更新 (`test/widget_test.dart`)
- 添加 `sharedPreferencesProvider` override（使用 `SharedPreferences.setMockInitialValues({})`）
- 设置页测试新增加密状态验证: `AES-256 加密已启用`

### 遇到的问题及解决

#### 问题 1: `late final` 字段无法重新赋值
- **现象**: `regenerateKey()` 中 `_key = newKey` 抛 `LateInitializationError`
- **原因**: `late final` 字段只能赋值一次，构造函数已赋值后无法再赋
- **解决**: 将 `late final Key _key` 和 `late final Encrypter _encrypter` 改为 `late Key` 和 `late Encrypter`（去掉 `final`）

#### 问题 2: AES-CBC 加密空字符串抛 RangeError
- **现象**: `encrypt('')` 时 pointycastle `PaddedBlockCipherImpl.doFinal` 抛 `RangeError (start): Invalid value: Only valid value is 0: -16`
- **原因**: pointycastle 的 PKCS7 填充实现在输入为空时计算子数组越界
- **解决**: 空字符串特殊处理 — `encrypt('')` 返回 `base64(IV):`（空 ciphertext），`decrypt` 识别空 ciphertext 直接返回空串

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings, 0 infos)
- `flutter test`: All tests passed! (40 tests)
  - Widget tests: 6 passed
  - Repository tests: 18 passed
  - Encryption service tests: 16 passed

### 技术决策
- **SharedPreferences 注入模式**: 使用 `Provider.overrideWithValue` 在 `main.dart` 中注入已初始化的 `SharedPreferences` 实例，确保整个应用同步可用，避免异步初始化的 UI 闪烁
- **密钥存储位置**: 当前存储在 `SharedPreferences`（明文），后续可迁移至 `flutter_secure_storage`（Android Keystore / iOS Keychain）增强安全性
- **密文格式**: `IV:ciphertext` 分隔符方案简单可解析，Base64 字符集不含 `:` 确保分隔安全
- **空字符串边界处理**: 使用空 ciphertext 标记空明文，避免 pointycastle 底层 bug，保持 API 透明

### Git 提交记录
```
5d20b1f feat: Week 1 Day 5 - encryption, preferences persistence, and unit tests
```

### 明日计划 (Week 2 Day 1)
- GitHub OAuth 认证流程实现
- WebView 授权页 + authorization_code 获取
- access_token 换取 + 加密存储

## 2026-08-15 | Week 2 Day 1 — GitHub OAuth 认证 + 笔记同步

### 今日完成

#### 1. GitHub OAuth 配置 (`lib/core/config/github_config.dart`)
- OAuth App 配置: Client ID / Client Secret / Redirect URI / Scope
- 授权 URL 构建: `https://github.com/login/oauth/authorize?client_id=...&scope=repo`
- Token 交换端点: `https://github.com/login/oauth/access_token`
- API 基础地址: `https://api.github.com`
- ⚠️ 安全警告: client_secret 嵌入客户端代码，生产环境应使用后端中转

#### 2. GitHub 服务 (`lib/services/github_service.dart`)
- OAuth 流程: `exchangeCodeForToken(code)` — POST 到 token 端点交换 access_token
- Token 加解密: `encryptToken(token)` / `decryptToken(encrypted)` — 委托 EncryptionService
- GitHub API 封装:
  - `getUser(token)` — 获取已认证用户信息（login, name, avatar_url）
  - `listRepos(token)` — 列出用户仓库（按更新时间排序）
  - `createRepo(token, name)` — 创建新仓库（默认私有 + auto_init）
  - `createOrUpdateFile(...)` — 创建/更新文件（支持 sha 更新已有文件）
  - `getFile(...)` — 获取文件内容 + SHA（404 返回 null）
  - `deleteFile(...)` — 删除文件（需提供 sha）
- 请求头: `Authorization: Bearer`, `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`

#### 3. 同步服务 (`lib/services/sync_service.dart`)
- `pushNote(...)` — 推送单条笔记到 `notes/{slug}.md`（含 YAML front matter）
- `pushAllNotes(...)` — 批量推送所有笔记，返回 `SyncResult`（成功/失败计数 + 错误列表）
- 笔记转 Markdown: YAML front matter（id/title/priority/status/tags/created_at/updated_at）+ 正文
- 文件名 slug: 支持中文，过滤特殊字符，截断 50 字符

#### 4. 同步状态管理 (`lib/features/sync/providers/sync_provider.dart`)
- `SyncState`: status（idle/syncing/success/error）/ user / lastSyncTime / message
- `SyncNotifier`:
  - `saveToken(token)` — 加密存储 token + 获取用户信息
  - `logout()` — 清除 token + 仓库配置 + 用户信息
  - `fetchUser()` — 获取 GitHub 用户信息
  - `syncAllNotes()` — 批量推送笔记，更新同步状态
  - `setSyncRepo(owner, repo)` — 配置同步仓库
- `isGitHubLoggedInProvider` — 布尔值判断登录状态
- `syncServiceProvider` — 依赖有效 token，未登录返回 null

#### 5. WebView OAuth 登录页 (`lib/features/sync/pages/github_login_page.dart`)
- `webview_flutter` 加载 GitHub 授权 URL
- `NavigationDelegate.onNavigationRequest` 拦截回调 URL
- 提取 `code` 参数 → `exchangeCodeForToken` → `saveToken`
- 三态 UI: 加载中（LinearProgressIndicator）/ 交换中（遮罩 + 圆形进度）/ 错误（重试按钮）

#### 6. 同步设置页 (`lib/features/sync/pages/sync_settings_page.dart`)
- 账户区域: 已登录显示头像 + 用户名 + 退出按钮；未登录显示登录入口
- 仓库配置: owner/repo 输入框 + 保存按钮
- 同步操作: 上次同步时间 + 状态消息卡片 + 立即同步按钮
- 状态消息: 成功（primaryContainer）/ 失败（errorContainer）/ 同步中（surface）

#### 7. Provider 与路由集成
- `service_providers.dart`: 新增 `githubServiceProvider` / `githubTokenProvider` / `syncServiceProvider`
- `preferences_service.dart`: 新增 token 加密存储 + 仓库配置 + `clearSyncConfig()`
- `app_router.dart`: 新增 `/github-login` 和 `/sync-settings` 路由
- `settings_page.dart`: "GitHub 同步" 入口从弹窗改为跳转同步设置页
- `AndroidManifest.xml`: 添加 `INTERNET` 权限 + `usesCleartextTraffic`

### 验证结果
- `flutter analyze`: No issues found
- `flutter test`: All tests passed! (40 tests)

### 技术决策
- **WebView 拦截方案**: 使用 `NavigationDelegate.onNavigationRequest` 拦截 redirect URL，避免自定义 URL scheme 注册复杂性
- **Token 加密存储**: access_token 通过 `EncryptionService.encrypt()` 加密后存储在 SharedPreferences，解密在 `githubTokenProvider` 中按需进行
- **SyncService 设计**: 每条笔记作为独立 Markdown 文件（含 YAML front matter），支持增量更新（通过 sha 检测已有文件）
- **StateNotifier vs AsyncNotifier**: 同步状态使用 `StateNotifier<SyncState>` 而非 `AsyncNotifier`，因为同步操作需要展示进度和错误消息，不适合简单的 `AsyncValue` 三态

### Git 提交记录
```
6b1ed7e feat: Week 2 Day 1-2 - GitHub OAuth, note sync, import, conflict handling, and 46 new tests
```

## 2026-08-15 | Week 2 Day 2 — 同步测试 + 笔记导入 + 冲突处理

### 今日完成

#### 1. GitHubService 可测试性重构
- 构造函数新增可选参数 `http.Client`，默认创建 `http.Client()`
- 所有 `http.get/post/put/delete` 替换为 `_client.get/post/put/delete`
- Provider 层无需修改，`githubServiceProvider` 仍创建默认实例
- 测试时注入 `MockClient`（`package:http/testing.dart`）实现 HTTP 模拟

#### 2. GitHubService 单元测试 (`test/services/github_service_test.dart`)
##### 测试覆盖 (22 项)
- **exchangeCodeForToken**: 成功返回 token / HTTP 错误抛异常 / access_token 缺失抛异常
- **encryptToken/decryptToken**: 加解密往返 / 密文不同于明文
- **getUser**: 成功解析用户信息 / HTTP 错误抛异常 / 缺失字段使用默认值
- **listRepos**: 返回仓库列表 / 空仓库返回空列表
- **createRepo**: 成功返回创建的仓库 / 非 201 状态抛异常
- **createOrUpdateFile**: Base64 编码验证 / sha 更新已有文件 / 错误响应抛异常
- **getFile**: 文件存在返回内容+sha / 404 返回 null / Base64 含换行符正确解码
- **deleteFile**: 发送 DELETE + sha / 错误抛异常
- **listFiles**: 列出目录文件（过滤目录）/ 404 返回空列表

#### 3. SyncService 单元测试 (`test/services/sync_service_test.dart`)
##### 测试覆盖 (24 项)
- **noteToMarkdown**: YAML front matter 完整性 / 空内容占位符
- **slugify**: 空格转连字符 / 移除特殊字符 / 小写转换 / 保留中文 / 50 字符截断
- **pushNote**: 新文件创建（无 sha）/ 已有文件更新（含 sha）/ 空标题用 id 做文件名
- **pushAllNotes**: 全部成功 / 全部失败收集错误 / 部分成功
- **pullNotes**: 远程笔记解析 / 空目录 / 跳过非 Markdown 文件
- **syncWithConflictCheck**: 远程不存在→推送 / 本地较新→推送 / 远程较新+skip→跳过 / 远程较新+localWins→推送 / 时间相同→跳过
- **SyncResult**: isSuccess / failed / skipped 逻辑

#### 4. 笔记导入功能
##### GitHubService 扩展
- 新增 `GitHubFile` 数据类（name/path/sha/size）
- 新增 `listFiles(...)` — 列出仓库目录文件，404 返回空列表
##### SyncService 扩展
- `pullNotes(...)` — 列出 `notes/` 目录下 `.md` 文件，逐个下载并解析为 `NoteModel`
- `_markdownToNote(String)` — 解析 YAML front matter（id/title/priority/status/tags/created_at/updated_at）+ 正文内容
- `noteToMarkdown(...)` / `slugify(...)` — 从私有方法改为公开方法，便于测试
##### SyncNotifier 扩展
- `importNotes()` — 拉取远程笔记 → 写入本地数据库 → 更新同步状态
##### UI 集成
- `sync_settings_page.dart` 新增"导入笔记"按钮（下载图标 + 从 GitHub 拉取描述）

#### 5. 冲突处理策略
##### 设计
- `ConflictResolution` 枚举: `localWins` / `remoteWins` / `skip`
- `syncWithConflictCheck(...)` — 比较本地与远程笔记的 `updatedAt`:
  - 本地较新 → 推送本地版本
  - 远程较新 → 根据 resolution 策略处理（localWins 推送 / remoteWins 跳过 / skip 跳过）
  - 时间相同 → 跳过（无需同步）
  - 远程不存在 → 推送新笔记
- `SyncResult` 新增 `skipped` 字段，区分跳过和失败
##### export 导出
- `sync_provider.dart` 中 `export ConflictResolution`，供 UI 层使用

#### 6. Bug 修复
- **_slugify RangeError**: 原代码用 `text.length`（原始长度）作为 substring 上限，替换特殊字符后字符串变短导致越界。改为使用处理后的 `slug.length`
- **tags 解析含方括号**: YAML front matter 中 `tags: [a, b]` 被解析为 `['[a', 'b]']`。增加 `replaceAll(RegExp(r'[\[\]]'), '')` 去除方括号

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (86 tests)
  - Widget tests: 6
  - Repository tests: 18
  - Encryption service tests: 16
  - GitHub service tests: 22
  - Sync service tests: 24

### 技术决策
- **MockClient 注入**: 通过构造函数注入 `http.Client`，而非使用全局 `http.runWithClient`，保持依赖显式、测试隔离
- **YAML front matter 解析**: 手动解析而非引入 yaml 包，front matter 结构简单固定（7 行 key: value），手动解析更轻量
- **冲突策略粒度**: 当前为全局策略（所有冲突统一处理），后续可扩展为逐条冲突交互式选择
- **SyncResult.skipped**: 区分"成功推送"、"跳过（无需同步）"和"失败（错误）"三种结果，提供更精确的同步反馈

### Git 提交记录
```
6b1ed7e feat: Week 2 Day 1-2 - GitHub OAuth, note sync, import, conflict handling, and 46 new tests
```

### 明日计划 (Week 2 Day 3)
- GitHub OAuth App 配置替换为真实 Client ID
- 同步功能端到端集成测试（真机/模拟器）
- 笔记编辑器 Markdown 渲染增强（代码高亮、表格支持）
