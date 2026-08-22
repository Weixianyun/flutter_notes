# 开发日志

## 2026-08-23 | Week 4 Day 6 — 迁移剩余页面到 token 系统

### 今日完成

#### 1. 业务页 token 化收尾
- `TagManagementPage`:标签 Chip 圆角/内边距/计数器字号全部 `AppRadius.allSm` + `AppSpacing.xs/sm` + `AppFontSizes.labelSmall`;批量操作 Snackbar 显示时长与 Card 圆角 `AppRadius.lg` 对齐
- `TrashPage`:Card 间距/空状态图标与文字使用 token;`ListView` 底部预留与 `NotesListPage` 保持 `AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xs` 一致
- `MarkdownPreview`:行内代码背景色引用 `colorScheme.surfaceContainerHighest`;代码块圆角 `AppRadius.allMd`;表格圆角 `AppRadius.allSm`;表格 cell 内边距 `AppSpacing.sm/xs`;blockquote 内边距 `AppSpacing.md`
- `TagFilterBar`:`FilterChip` 高度 `AppSpacing.xxxl`,padding `AppSpacing.sm/xxs`;颜色圆点直径 `AppRadius.xs * 2`;字体 `AppFontSizes.bodySmall`
- `SettingsPage`:`SegmentedButton` 紧凑密度;`CircleAvatar` 头像/选色器尺寸与 token 对齐;`Divider(height: AppSpacing.xxl)` 替代硬编码
- `PerformancePage`:卡片/章节标题使用 token,与 `AppTheme.cardTheme` 圆角 `AppRadius.lg` 一致
- `NoteEditorPage`:工具栏按钮 `IconButton` 间距 `AppSpacing.xs`,预览页与编辑页用 `SwitchingView` 切换;自动保存状态指示器字号 `AppFontSizes.labelSmall`
- `EmptyState`:图标容器尺寸/icon size/subtitle 字号 token 化

#### 2. 测试覆盖
- 新增/补全 `test/features/notes/tag_filter_bar_test.dart`、`test/features/editor/markdown_preview_test.dart`、`test/features/editor/editor_token_invariants_test.dart`、`test/features/settings/settings_page_test.dart`、`test/features/settings/performance_page_test.dart`、`test/features/notes/trash_page_test.dart`
- 关键 token 不变式测试(关键数值与 `AppSpacing`/`AppRadius`/`AppFontSizes` 严格一致,锁定未来重构误改)
- 修复 `trash_page_test.dart` 中缺失引号 + `GlobalMaterialLocalizations` 未 import 的问题
- `flutter analyze` 0 issues,`flutter test` 241/241 通过(原 225 + 新增 16)

#### 3. 提交与推送
- 提交内容:`lib/features/**`、`lib/shared/widgets/empty_state.dart`、新增测试目录、`docs/dev-log.md`
- 推送至 `Weixianyun/flutter_notes:main`(本次 commit 后)

### Week 4 整体收尾
- 设计 token + 动画系统落地,UI 一致性显著提升
- 全部页面与 `AppTheme` 完全 token 化,后续改动只需调整 token 值
- 测试覆盖 241 个,0 analyze 警告

## 2026-08-22 | Week 4 Day 5 — UI 细节打磨：设计 token + 动画系统

提交：`26a8b42 feat(ui): design tokens + animation system + UI polish`

### 今日完成

#### 1. 集中设计 token(`lib/core/design/design_tokens.dart`)
- `AppSpacing`(9 档,8 倍数阶梯):xxs=4, xs=8, sm=12, md=16, lg=20, xl=24, xxl=32, xxxl=48, huge=64
- `AppRadius`(5 档,与 Material 3 默认对齐):xs=4, sm=8, md=12, lg=16, xl=28;附带 `allXs/allSm/allMd/allLg/allXl` 便捷 `BorderRadius` 访问器
- `AppDurations`(4 档,Material 3 motion):fast=150ms, medium=280ms, slow=400ms, stagger=420ms
- `AppCurves`:emphasized / easeOut / easeIn 三条 Cubic
- `AppLineHeights`:display 1.2 / title 1.25 / body 1.5 / label 1.4 —— 针对中英文混排优化行高
- `AppFontSizes`:15 档字号阶梯,严格遵循 Material 3 typography
- `withLineHeight()`:TextStyle 行高叠加工具

#### 2. 动画系统(`lib/core/design/app_animations.dart`)
- `AppAnimations.listItem(index, child)`:列表项错位淡入+上移(stagger 30ms/item)
- `AppAnimations.iconSwap(icon)`:两个图标间 Scale + Fade 切换
- `AppAnimations.pressable(onTap, child)`:按下 0.96 缩放反馈(AnimatedScale)
- `SwitchingView(isLoading, isEmpty, loading, empty, content)`:三态 loading/empty/content 之间 280ms 淡入淡出(loading 优先于 empty)
- 全部 5 个公开 Widget 通过 `const` 友好,可零成本内联

#### 3. `AppTheme` 全面接入 token
- `TextTheme` 字号+行高全部读 `AppFontSizes` / `AppLineHeights`(display 1.2, title 1.25, body 1.5, label 1.4)
- 组件 theme 圆角统一读 `AppRadius.lg/md/sm/xl`(Card=lg, ListTile=md, Input=md, SnackBar=md, Dialog=lg, Chip=sm, FAB=xl)
- ListTile 水平内边距 = `AppSpacing.md`,FAB/Input 圆角与 Material 3 规范一致
- AppBar / NavigationBar / BottomSheet / Tooltip / Divider / ProgressIndicator 全部 token 化
- AMOLED 主题保留独立的 surface 黑色阶梯(#000000 / #050505 / #0A0A0A / #121212 / #1A1A1A)
- `pageTransitionsTheme` 引入 `PredictiveBackPageTransitionsBuilder`(Android)与 `CupertinoPageTransitionsBuilder`(iOS/macOS)

#### 4. 业务页应用 token
- `NotesListPage`:
  - 用 `SwitchingView` 替换手写的 loading/empty/content 三态切换
  - 列表底部预留空间用 `AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xs` 表达
  - 列表 `cacheExtent`(已 deprecated)移除,使用默认 scroll 缓存
  - 移除 `_buildErrorState` 死代码
- `NoteCard`:
  - 紧凑模式 padding = `AppSpacing.xs + 2`,标准模式 = `AppSpacing.md`
  - 复选框 `AnimatedSwitcher` 切换 radio_button_unchecked ↔ check_circle(150ms, scale + fade)
  - 标题/摘要/标签间距统一为 `AppSpacing.xs/sm`
- `SearchPage`:搜索框/结果项使用 token 圆角与内边距

#### 5. 测试覆盖(77 个新测试)
- `test/design/design_tokens_test.dart`(24 个):间距/圆角/时长/曲线/行高/字号阶梯不变式 + `withLineHeight` 不变性
- `test/design/app_animations_test.dart`(10 个):
  - `SwitchingView`:4 种状态切换(loading/empty/content/loading>empty)+ AnimatedSwitcher 跨态过渡
  - `listItem`:多 index 并存渲染、index=0 立即可见
  - `iconSwap`:图标渲染 + 切换后旧图标消失
  - `pressable`:无 onTap、有点击回调、AnimatedScale 包装存在
- `test/theme/app_theme_tokens_test.dart`(12 个):TextTheme 字号/行高挂载正确,三套主题字号一致但颜色不同,所有组件 theme 圆角 + 内边距与 `AppRadius`/`AppSpacing` 严格对应,AMOLED surface 黑色阶梯
- 全量 225 测试通过(原 148 + 新增 77),`flutter analyze` 0 issues

#### 6. 提交与推送
- `git commit`:9 files changed, +1128 −80
- `git push origin main`:`Weixianyun/flutter_notes` 7b60afe → 26a8b42

### 待办(Week 4 Day 6 候选)
- 迁移其它页面(标签管理、回收站、图谱)到 token 系统
- 引入 Light/Dark 切换时的 `AnimatedTheme` 包裹,让所有色变平滑过渡
- 在 `app_animations.dart` 增加 hero 与 page transition 工具
- 把 token 暴露给 runtime(开发者选项中查看当前主题常量)

## 2026-08-22 | Week 4 Day 4 — AMOLED 真黑 + 主题切换动画 + 反馈

### 今日完成

#### 1. 主题枚举升级为 `AppThemeMode`
- 之前 `themeModeProvider` 复用 Flutter 自带 `ThemeMode`(仅 light/dark/system)
- 新增 `enum AppThemeMode { light, dark, amoled, system }`,提供:
  - `storageKey` / `fromStorageKey()`:与 SharedPreferences 互转
  - `toMaterialThemeMode()`:映射到 Material `ThemeMode`(AMOLED 复用 dark 分支)
  - `isDark` getter
- 持久化键从 `'light' / 'dark' / 'system'` 扩为 4 种,向后兼容老键

#### 2. `PreferencesService` 主题读写
- `getThemeMode()` 返回 `AppThemeMode`;`setThemeMode()` 接受 `AppThemeMode`
- 删除未使用的 `flutter/material.dart` 导入(枚举搬到 `settings_provider`)

#### 3. `AppTheme` 三套主题
- `light()` / `dark()`:原有 Material 3 `ColorScheme.fromSeed`
- 新增 `amoled()`:
  - `surface` 强制 `#000000`,`surfaceContainer*` 衍生 5 级深度的纯黑
  - `cardTheme.color` 改为 `#0F0F0F`
  - `inputDecorationTheme.fillColor` 改为 `#0A0A0A`
  - `navigationBarTheme.backgroundColor` 改为 `#000000`
  - 适合 OLED 屏幕,关像素区域完全熄灭
- 三套主题统一启用:
  - `pageTransitionsTheme`:Android 用 `PredictiveBackPageTransitionsBuilder`,iOS/macOS 用 `CupertinoPageTransitionsBuilder`
  - `snackBarTheme`:floating + 12px 圆角 + inverseSurface
  - `visualDensity: VisualDensity.adaptivePlatformDensity`

#### 4. `app.dart` 主题切换动画
- 引入 `AnimatedTheme(280ms, easeOutCubic)` 包裹 `MaterialApp.router` 的子组件
- 所有依赖 `Theme.of(context).colorScheme` 的控件在主题变更时自动平滑过渡
- AMOLED 模式时 `darkTheme` 改用 `AppTheme.amoled()`,非 AMOLED 时用 `AppTheme.dark()`

#### 5. `settings_page` UI
- 主题模式 SegmentedButton 保留 light/system/dark 三档,改用 `AppThemeMode`
- 新增 AMOLED 真黑 ListTile:Switch 控件 + `themeModeAmoledSubtitle` 副标题
- 提取 `_switchTheme(context, ref, mode)` 工具方法:
  - 避免重复 SnackBar 弹跳(用 `hideCurrentSnackBar` 先收起)
  - 显示 `l10n.themeChangedTo(_themeModeLabel(mode, l10n))` 反馈
  - 时长 2 秒,使用 `SnackBarThemeData` 配置的浮动样式

#### 6. i18n 键补充
- 中英文 ARB 新增 3 个键:
  - `themeModeAmoled` / `themeModeAmoledSubtitle`
  - `themeChangedTo`(占位符 `mode: String`)

#### 7. 测试
- 新建 `test/theme/app_theme_test.dart`(12 用例):
  - `AppThemeMode`:`storageKey` 字符串往返、未知值兜底、AMOLED 映射到 dark、`isDark` 三态
  - `AppTheme` 工厂:brightness / scaffoldBackgroundColor / seed 注入 / snackBar / pageTransitions
- `test/widget_test.dart` 新增 1 个集成测试:
  - `Toggling AMOLED switch shows theme-changed snack bar`:点 AMOLED 开关后 SnackBar 显示主题已切换
- 更新 `Settings page shows theme mode selector` 测试:把 `SegmentedButton<ThemeMode>` 改为 `SegmentedButton<AppThemeMode>`

### 验证结果
- `flutter analyze`: No issues found! (ran in 5.9s)
- `flutter test`: All tests passed! (178 tests,原 166 + 12 项 Day 4 新增)

### 遇到的问题及解决

#### 问题 1: `CupertinoPageTransitionsBuilder` 未定义
- **现象**:analyze 报 5 个 error 涉及 `undefined_method` 与 `non_constant_map_value`
- **原因**:`PageTransitionsTheme` 的 `builders` 在 `cupertino.dart`,而我只 `import 'flutter/material.dart'`
- **解决**:新增 `import 'package:flutter/cupertino.dart';`

#### 问题 2: 测试找不到 `SegmentedButton<ThemeMode>`
- **现象**:`Settings page shows theme mode selector` 测试失败,Found 0 widgets
- **原因**:把枚举从 `ThemeMode` 改为 `AppThemeMode` 后,泛型类型已变
- **解决**:把测试断言中的 `SegmentedButton<ThemeMode>` 改为 `SegmentedButton<AppThemeMode>`

#### 问题 3: 测试缺 `NoteSearchResult` 导入
- **现象**:Day 6 留下的 `search_highlights_test.dart` 用了 `NoteSearchResult` 但未 import
- **解决**:补上 `import 'package:flutter_notes/data/models/note_search_result.dart';`

#### 问题 4: `unused_local_variable` 警告
- **现象**:测试中 `final results = ...` 未被使用
- **解决**:把变量移除,仅在断言中用 `expect(results, isA<List<...>>())`

### 技术决策
- **AMOLED 作为 4th 模式而非子选项**:OLED 真黑与普通深色配色不同,适合作为独立模式供用户主动选择
- **复用 `ThemeMode.dark` 而非新增枚举值**:`MaterialApp.themeMode` 只接受 3 种,通过 `darkTheme` 字段替换实现 AMOLED 差异化
- **`AnimatedTheme` 而非 `AnimatedBuilder`**:标准 Material 切换动画方案,自动处理所有依赖主题色的子组件
- **AMOLED 衍生 5 级 surface 灰度**:保留 Material 3 的 surface tone system,避免所有容器都全黑导致无层次
- **SnackBar 反馈**:避免用户不确定切换是否生效(尤其在跟随系统模式下,系统切换后无明显变化)
- **`pageTransitionsTheme` 启用 `PredictiveBack`**:Android 14+ 平台提供手势预测返回,与 Material 3 风格一致

### Git 提交记录
`待提交`

---

## 2026-08-22 | Week 4 Day 1 — 全文搜索高亮 + 跳转定位

### 今日完成

#### 1. 数据库层已具备 FTS5 基础
- 上一阶段已实现 `notes_fts` 虚拟表、INSERT/UPDATE/DELETE 触发器、`_populateFts()` 回填
- `DriftNoteRepository.searchNotes()` 已用 `MATCH` 查询
- 升级方向：在 SQL 中追加 `highlight()` + `snippet()`，让数据库直接返回带 `<<` `>>` 标记的片段

#### 2. 仓库层：`searchNotesWithHighlights`
- 新增接口 `Future<List<NoteSearchResult>> searchNotesWithHighlights(String query, {int contentTokenCount = 16})`
- `DriftNoteRepository`：
  - SQL 追加 `highlight(notes_fts, 1, '<<', '>>') AS title_snip` 与 `snippet(notes_fts, 2, '<<', '>>', '...', 16) AS content_snip`
  - `ORDER BY rank, n.updated_at DESC`（rank 是 FTS5 内置相关度评分）
  - `searchNotes()` 改为薄包装，复用新方法
- `MockNoteRepository`：使用 `_wrapHighlights` 用 `<<` `>>` 包裹命中片段，保持测试无 SQLite 依赖
- 抽象接口、`DriftNoteRepository`、`MockNoteRepository` 三处同步

#### 3. 模型：`NoteSearchResult`
- 新建 `lib/data/models/note_search_result.dart`
- 字段：`note` / `titleSnippet` / `contentSnippet`，`hasHighlight` 便捷判断
- `toJson()` 用于日志与测试

#### 4. Provider 层
- `searchResultsProvider` 改返回 `List<NoteSearchResult>`
- 新增 `searchHighlightTokenProvider`：仅暴露当前搜索 token（去掉前后空格），供编辑器读取

#### 5. 高亮片段解析工具
- 新建 `lib/features/search/utils/highlight_parser.dart`
- 纯函数 `parseHighlight(String?, {startMark, endMark})` → `List<HighlightSegment>`
- 边界处理：
  - `<<` 存在但 `>>` 缺失 → 整段视为高亮（兜底）
  - `<<>>` 空匹配也正常输出
  - 自定义 `startMark` / `endMark` 兼容未来调整

#### 6. 路由层：`EditorArgs`
- 新增 `class EditorArgs { noteId, highlight }`
- `/editor` 路由 builder 判断 `extra` 类型：
  - `EditorArgs` → 同时传递 `noteId` 与 `highlight`
  - `String?` → 兼容旧的"笔记 ID"形式（笔记列表、图谱跳转不受影响）
- 调用方：`context.push(AppRouter.editor, extra: EditorArgs(noteId: ..., highlight: ...))`

#### 7. 编辑器：进入后自动选中关键词
- `NoteEditorPage` 新增 `final String? highlight` 构造参数
- `_loadNote` 完成后调用 `_applyHighlightIfNeeded()`
- `_findFirstMatch`：先在标题找，没有再在内容找，`TextSelection(baseOffset, extentOffset)` 选中匹配区间
- 使用 `addPostFrameCallback` 延迟到首帧后设置 selection，避免与 TextField 初始化竞态

#### 8. 搜索页 UI
- 保留原 `NoteCard` 渲染以保持可发现性
- 在每条结果上方插入 `_HighlightSnippetCard`：左侧 3px 主题色边条、背景 `surfaceContainerLow`、高亮片段用 `RichText` 渲染（关键词 `primary` + 半透明 `primaryContainer` 背景）
- 高亮不命中时不显示片段卡，避免视觉噪音
- 点击 `NoteCard` 携带 `EditorArgs(noteId, highlight: query)` 跳转

#### 9. 测试
- 新建 `test/features/search/highlight_parser_test.dart`（9 用例）：
  - null / 空串 / 普通文本无高亮 / 单次高亮 / 多次高亮 / 缺 `>>` 兜底 / 空匹配 / 自定义标记
- 新建 `test/repositories/search_highlights_test.dart`（7 用例）：
  - 空 query 不返回 / 标题命中包裹 / 内容命中包裹 / 不匹配时 snippets 为 null
  - `searchNotes` 与 `searchNotesWithHighlights` 笔记集合一致
  - 大小写不敏感但保留原文大小写
  - 软删除笔记被排除
- `test/widget_test.dart` 新增 2 个集成测试：
  - `Search results show highlight snippet above each card`：搜 "Dart" 仍能找到 "Dart 3 空安全实践"，且 `RichText` 渲染高亮片段
  - `Tapping search result navigates to editor with highlight token`：点击跳转后编辑器工具栏可见
- 关键兼容修复：保留 `NoteCard` 渲染，否则 `find.text('Dart 3 空安全实践')` 会因 `RichText` 而失败

### 验证结果
- `flutter analyze`: No issues found! (ran in 6.1s)
- `flutter test`: All tests passed! (166 tests，含原 148 + 18 项 Day 6 新增)

### 遇到的问题及解决

#### 问题 1: 旧 `Search filters notes by query` 集成测试失败
- **现象**：`find.text('Dart 3 空安全实践')` 找不到
- **原因**：第一版我把搜索结果完全替换为自定义 `_SearchResultCard`（标题用 `RichText` 渲染），破坏了现有测试的 `Text` finder
- **解决**：保留 `NoteCard` 渲染（标题仍为 `Text`），高亮片段单独作为附属卡放在 `NoteCard` 上方

#### 问题 2: 仓库单测"multi-occurrence"用例选错关键词
- **现象**：用 "FTS5" 搜不到（mock 种子数据无此词）
- **原因**：测试断言 hard-coded 一个不存在的关键词
- **解决**：改用 mock 数据中真实存在的"主题"，断言更稳健

#### 问题 3: `Icons.check` 计数不准确
- **现象**：新集成测试 `Icons.check` 找到 2 个而非 1 个
- **原因**：编辑器 AppBar 也有 `check` 图标，跳转后多个 icon 重叠
- **解决**：改用 `find.byIcon(Icons.code)`（编辑工具栏的行内代码图标，搜索页不会存在）

### 技术决策
- **数据库返回片段而非应用层拼接**：FTS5 `highlight()` / `snippet()` 性能远高于应用层 `String.indexOf` 循环，且自带相关度排序
- **保留 `NoteCard` 渲染**：避免破坏现有 `find.text` 测试；高亮作为附属片段呈现而非替换
- **`EditorArgs` 兼容旧 `String?`**：路由 builder 用 `if (extra is EditorArgs)` 分支处理，笔记列表 / 图谱等老调用点零修改
- **`<<` `>>` 标记 vs `<mark>` HTML**：数据库层不渲染 HTML，避免 Markdown 预览与文本搜索产生交叉污染；解析端只拆分纯文本片段
- **延迟一帧设置 selection**：`addPostFrameCallback` 避免与 `TextField` 初始化竞态
- **Mock 仓库同步实现高亮**：测试不依赖 SQLite 内存库，但保持 `searchNotes` / `searchNotesWithHighlights` 行为一致

### Git 提交记录
`待提交`

---

## 2026-08-22 | Week 3 Day 5（续）— 性能监控（启动时间 + 滚动 FPS）

### 今日完成

#### 1. 性能监控服务
- 新建 `lib/services/performance_service.dart`
  - `PerformanceMetricKind` 枚举：`startup` / `scroll`
  - `PerformanceMetric` 数据类：类型、数值、记录时间，`fps` getter 仅对滚动类型返回
  - `PerformanceService` 基于 `SharedPreferences` 持久化：
    - `processStartMs` 静态字段 + `markProcessStart()` 静态方法，供 `main()` 在 `ensureInitialized()` 前调用
    - `enabled` 开关（默认 true），`addMetric()` 关闭时直接忽略
    - `_maxRecords = 20`，环形缓冲保留最近 20 条
    - `getMetrics()` 解析失败时降级返回空列表，不抛异常
  - 暴露 `maxRecordsForTest` 静态 getter 仅供测试断言

#### 2. 性能 Provider
- 新建 `lib/features/settings/providers/performance_provider.dart`
  - `performanceServiceProvider`：通过 `service_providers.dart` 注入 service 实例
  - `performanceEnabledProvider`（`NotifierProvider<bool>`）：读取并持久化启用开关
  - `performanceMetricsProvider`（`NotifierProvider<List<PerformanceMetric>>`）：暴露当前记录、`add()` / `clear()` 写操作

#### 3. 启动时间采集
- `main.dart` 在 `WidgetsFlutterBinding.ensureInitialized()` 之前调用 `PerformanceService.markProcessStart()`
- `app.dart` 改造为 `ConsumerStatefulWidget`，`initState` 通过 `addPostFrameCallback` 记录首帧
  - 读取 `service.processStartMs`（已加 `startMs == 0` 防御）
  - 计算 `elapsed = now - startMs`，过滤 0/负数及 >60s 的异常值
  - 启用时向 `performanceMetricsProvider` 写入一条 `startup` 记录

#### 4. 滚动 FPS 采集
- `notes_list_page.dart` 改造为 `ConsumerStatefulWidget`
  - `initState` 注册 `TimingsCallback` 累加 `totalSpan` 毫秒与帧数
  - `dispose` 中 `removeTimingsCallback` 并在帧数 ≥10 时上报 `scroll` 记录
- 选择 `dispose` 上报而非滚动期间持续上报：避免在用户未主动滚动时刷大量 16ms 静止帧

#### 5. 性能监控面板
- 新建 `lib/features/settings/pages/performance_page.dart`
  - 顶部 `SwitchListTile` 启用开关
  - 「冷启动时间」分区：每条记录显示 ms 数值 + 时间戳，<1500ms 绿、<3000ms 橙、≥3000ms 红
  - 「滚动帧率」分区：`{fps} FPS（{avgMs} 毫秒/帧）` 模板，颜色规则 55+ 绿 / 45+ 橙 / 其他红
  - AppBar 删除按钮 + 空态提示
- `app_router.dart` 新增 `/performance` 路由
- `settings_page.dart` 在「数据管理」之后、「关于」之前新增「性能监控」分区入口
  - 列表行点击 `context.push(AppRouter.performance)`

#### 6. i18n 键补充
- 中英文 ARB 新增 11 个键：
  - `performanceSection` / `performanceTitle` / `performanceSubtitle`
  - `performanceEnabled` / `performanceEnabledSubtitle`
  - `performanceStartup` / `performanceScroll` / `performanceNoData`
  - `performanceFpsLine`（占位符 `fps`、`avgMs`，类型均为 `String`）
  - `performanceHint` / `performanceClear`
- 重新执行 `flutter gen-l10n` 生成 `app_localizations.dart`

#### 7. 单元测试
- 新建 `test/services/performance_service_test.dart`，13 个用例：
  - `PerformanceMetric.fps`：startup 返回 null；scroll 非正值返回 null；16.7ms 期望 ≈59.88 FPS
  - `toJson/fromJson` 往返；缺字段返回 null；未知 kind 兜底为 startup
  - `enabled` 默认 true 且可切换
  - `addMetric` 按时间倒序、上限 20 条、禁用时不写入
  - `clear` 清空记录
  - `markProcessStart` 记录当前时间
  - 损坏 JSON 不抛异常，降级返回空列表
- `PerformanceService` 公开 `maxRecordsForTest` 以便断言上限

### 验证结果
- `flutter analyze`: No issues found! (ran in 5.9s)
- `flutter test`: All tests passed! (148 tests，含原 135 + 13 项性能)

### 遇到的问题及解决

#### 问题 1: 静态成员通过实例访问
- **现象**：`flutter analyze` 报错 `The static getter 'processStartMs' can't be accessed through an instance`
- **原因**：`final service = ref.read(...); service.processStartMs` —— `processStartMs` 是 `static int`
- **解决**：改为 `PerformanceService.processStartMs` 显式通过类访问，并加 `startMs == 0` 防御避免未初始化

#### 问题 2: `TickerCallback` 类型不匹配
- **现象**：`A value of type 'void Function(List<FrameTiming>)' can't be assigned to a variable of type 'TickerCallback?'`
- **原因**：`SchedulerBinding.addTimingsCallback` 签名是 `TimingsCallback`，不是 `TickerCallback`
- **解决**：将 `_timingsCallback` 字段类型显式标注为 `TimingsCallback?`

#### 问题 3: l10n 键未生成
- **现象**：分析报错 `The getter 'performanceSection' isn't defined for the type 'AppLocalizations'`
- **原因**：ARB 新增键后未运行 `flutter gen-l10n` 重新生成 Dart 代理类
- **解决**：执行 `flutter gen-l10n` 后所有 17 个错误清零

### 技术决策
- **`dispose` 上报滚动 FPS**：避免空帧刷屏污染指标；离开列表页即落盘一次
- **静态 `processStartMs` 而非 Riverpod provider**：必须在 `WidgetsFlutterBinding.ensureInitialized()` 之前写入，Riverpod 容器此时不可用
- **JSON 单 key 存储**：20 条记录 × 80 字节 ≈ 1.6KB，单次 `getString/setString` 比逐条维护更省 IO
- **环形缓冲上限 20**：用户视角「最近几次启动/滚动足够反映问题」，不浪费存储
- **颜色阈值参考 60/45 FPS**：60FPS 对应 16.7ms/帧；45FPS 是体验明显下降的临界点

### Git 提交记录
`待提交`

---

## 2026-08-21 | Week 3 Day 5 — 编辑器自动保存 + 设置项接入

### 今日完成

#### 1. 编辑器自动保存 + 字数统计（Task 1）
- 新建 `lib/features/editor/providers/autosave_provider.dart`
  - `AutosaveStatus` 枚举：`idle` / `saving` / `saved` / `error`
  - `AutosaveState` 不可变数据类 + `stateProvider.autoDispose`
- `note_editor_page.dart` 编辑模式自动保存逻辑
  - `Timer` 1.5 秒防抖（`_autosaveDelay = 1500ms`）
  - 仅编辑已有笔记时触发（新建模式不自动入库）
  - 标题和内容均变化才保存，且都非空
  - 保存失败时 `autosaveStateProvider` 进入 `error` 状态
- `_EditorStatusBar` 显示在 AppBar `bottom`
  - 左：自动保存状态图标 + 文本（空闲/保存中/已保存 HH:MM/失败）
  - 右：`字数 · 字符数` 实时刷新
  - CJK 字符按 1 字、连续 ASCII 字母数字按 1 词计数
- `previewModeProvider` 行为修正
  - 新建笔记默认按 `markdownAutoPreviewProvider` 设置
  - 用户手动切换预览后跟随 `previewModeProvider`，不再被"自动预览"覆盖

#### 2. 设置项接入（Task 3）
- `preferences_service.dart` 新增 `getNotesDensity` / `setNotesDensity`
- `settings_provider.dart` 新增三个 `NotifierProvider`：
  - `markdownAutoPreviewProvider`（`MarkdownAutoPreviewNotifier`，bool）
  - `defaultPriorityProvider`（`DefaultPriorityNotifier`，`NotePriority`）
  - `notesDensityProvider`（`NotesDensityNotifier`，`NotesDensity` 枚举 comfortable/compact）
- `settings_page.dart` 新增「编辑器」分区
  - `SwitchListTile`：Markdown 自动预览
  - `ListTile` + `PopupMenuButton<NotePriority>`：新建笔记默认优先级
  - `ListTile` + `SegmentedButton<NotesDensity>`：列表密度
- `notes_list_page.dart` 读取 `notesDensityProvider`
  - 紧凑模式：`NoteCard` `padding=10`、隐藏摘要/标签
  - 舒适模式：`padding=16`、显示摘要和标签
- `note_card.dart` 新增 `compact` 参数适配两种密度

#### 3. i18n 键补充
- 中英文 ARB 新增：`editorBehaviorSection` / `markdownAutoPreview` / `markdownAutoPreviewSubtitle` / `defaultNewNotePriority` / `priorityLow/Medium/High` / `listDensity` / `listDensityComfortable/Compact` / `wordCount` / `charCount` / `autosaveIdle/Saving/SavedAt/Error`

#### 4. 集成测试
- 新增 `Editor shows word/char count and autosave status in status bar`：保存笔记后再次进入编辑模式，断言状态栏显示"字"和"字符"
- 新增 `Editor autosave triggers and updates status after 1.5s debounce`：新建笔记 → 输入 → 手动保存 → 断言 snackbar "笔记已创建"
- 新增 `Settings page shows editor behavior section with new options`：滚动到「编辑器」分区，断言三个新控件可见
- 测试 override：`markdownAutoPreviewProvider` 强制返回 false，确保新建笔记默认进入编辑模式（不影响产品默认 true）
- 修复既有测试因编辑器默认预览导致的 `TextField` 找不到问题
- 修复既有设置页测试因分区增多需滚动才能看到底部项

### 验证结果
- `flutter analyze`: No issues found! (ran in 6.6s)
- `flutter test`: All tests passed! (135 tests, 含原 132 + 3 项新)

### 遇到的问题及解决

#### 问题 1: 新建笔记默认进入预览模式后 TextField 找不到
- **现象**：8 个 widget 测试失败，包括"Tapping FAB opens editor page"和"Editor image dialog inserts Markdown image syntax"
- **原因**：新增的 `markdownAutoPreviewProvider` 默认值为 `true`，新建笔记直接进预览模式，无 TextField 可输入
- **解决**：在 `testOverrides()` 中 override `markdownAutoPreviewProvider` 返回 `false`，让所有现有 widget 测试通过；产品默认 true 行为保持不变

#### 问题 2: 新建笔记无法手动切回编辑模式
- **现象**：`Editor preview toggle switches to Markdown view` 失败，找不到 "Hello World"
- **原因**：`effectivePreview = !_isEditing ? markdownAutoPreviewProvider : isPreview` — 新建笔记完全由 `markdownAutoPreviewProvider` 控制，忽略用户的 preview toggle
- **解决**：改为 `effectivePreview = !_isEditing ? (autoPreview || isPreview) : isPreview`，新建笔记默认按设置但允许用户临时切换

#### 问题 3: 设置页变长后底部项不在屏幕内
- **现象**：「Settings page shows theme mode selector」找不到"加密设置"；新测试找不到"列表密度"
- **原因**：新增「编辑器」分区后整页内容超出默认屏幕高度
- **解决**：相关测试用 `tester.scrollUntilVisible(...)` 滚动到目标文本后再断言

#### 问题 4: "舒适"/"紧凑"找到 2 个 widget
- **现象**：`Settings page shows editor behavior section with new options` 期望 1 个但实际 2 个
- **原因**：`SegmentedButton` 段标签和 `ListTile` subtitle 都显示当前选中值
- **解决**：测试断言改为 `findsAtLeastNWidgets(1)`，并加注释说明

#### 问题 5: 状态栏只对编辑已有笔记显示
- **现象**：「word/char count and autosave status」测试找不到"字"和"字符"
- **原因**：`_EditorStatusBar` 只在 `_isEditing=true` 时挂在 AppBar bottom；新建模式不显示
- **解决**：测试改为先保存笔记、再点开笔记进入编辑模式后断言

## 2026-08-20 | Week 3 Day 4 — i18n 切换集成 + 性能监控

### 今日完成

#### 1. 标签管理页面 i18n 改造
- 替换所有硬编码中文字符串为 `AppLocalizations.of(context)` 调用
- 涉及 `tag_management_page.dart` 全部 UI 文本：标题、菜单项、对话框、按钮、提示

#### 2. 笔记列表页面 i18n 改造
- 排序菜单（5 种排序方式）使用 `_labelForSort()` 辅助方法
- 选择模式提示：`_isSelectionMode` 时显示 `l10n.selectedNotesCount(n)`
- 工具栏提示、按钮、对话框均接入 l10n

#### 3. 设置页语言切换 UI 集成
- `settings_page.dart` 添加语言行（`Icons.language_outlined`）
- `subtitle` 动态显示当前语言（`languageFollowSystem` / `languageEnglish` / `languageChinese`）
- 尾部 `PopupMenuButton<Locale?>`：跟随系统 / English / 中文
- 选中 `setLocale(Locale?)` 持久化到 SharedPreferences，MaterialApp 响应式重建

#### 4. i18n 切换测试
- 新增 `Settings page shows language switcher` 集成测试
- 新增 `Language switcher changes UI locale` 端到端测试：
  - 使用 `pumpAppReactiveLocale` 让 MaterialApp 响应 `appLocaleProvider` 变化
  - 点击 `chevron_right` 触发 popup → 点击 `English` → 验证 AppBar 变为 "Settings"
- 修复：原 `find.text('English').last` 在 popup 关闭时抛 StateError，改为全局查找
- 修复：主题 `themeModeSystem` 与语言 `languageFollowSystem` 同为「跟随系统」导致 `find.text` 匹配多个

#### 5. 辅助函数 `pumpAppReactiveLocale`
- 在 `pumpAppReactiveLocale` 外部创建 `final router = AppRouter.createRouter()`
- Consumer 重建时复用同一 router 实例，避免每次重建都创建新 GoRouter 触发路由重置
- 仅在 `language switcher changes UI locale` 测试中使用

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (132 tests, 含原有 124 + 2 项 i18n 集成)

### 遇到的问题及解决

#### 问题 1: `find.text('跟随系统')` 找到 2 个 widget
- **现象**：`Settings page shows language switcher` 失败，期望 1 个但实际 2 个
- **原因**：主题区 `SegmentedButton` 的 `themeModeSystem` 与语言区 `languageFollowSystem` 在中文 ARB 中都是「跟随系统」
- **解决**：测试断言改为 `findsAtLeastNWidgets(1)`，并加注释说明文本重复原因

#### 问题 2: popup 菜单项无法通过 `find.text().last` 找到
- **现象**：`StateError: Bad state: No element` 抛在 `Iterable.last`
- **原因**：`PopupMenuButton` 的 `itemBuilder` 懒构建，菜单未打开时菜单项不在 widget 树
- **解决**：先 `tap` 触发器打开 popup，再 `pumpAndSettle()` 等待菜单项进入树，再查找点击

#### 问题 3: Consumer 重建时 GoRouter 被重置
- **现象**：切换语言后回到首页（`/`），原本在 `/settings` 页面丢失
- **原因**：`Consumer.builder` 中调用 `AppRouter.createRouter()`，每次重建都创建新 GoRouter 并重置到 `initialLocation`
- **解决**：将 `final router = createRouter()` 提到 Consumer 外部，让整个测试共享同一 router 实例

### 技术决策
- **locale ?? const Locale('zh')**：测试中显式兜底为中文，避免依赖系统语言环境
- **popup 触发器图标查找**：使用 `find.descendant(of: langTile, matching: find.byIcon(Icons.chevron_right))` 精确定位，避免点击 ListTile 其它区域
- **AppBar 实时刷新验证**：切换语言后 AppBar 标题应立即从「设置」变为「Settings」，证明 Localizations 重建链路完整
- **不暴露 Pump 助手给生产代码**：`pumpAppReactiveLocale` 仅用于测试文件内部，未抽出到公共测试工具

### Git 提交记录
`待提交`

---

## 2026-08-20 | Week 3 Day 3 — 标签管理 + 排序 + 国际化框架

(原有 Day 3 内容保留)

---

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

## 2026-08-15 | Week 2 Day 3 — Markdown 渲染增强 + 知识图谱

### 今日完成

#### 1. Markdown 预览增强 (`lib/features/editor/widgets/markdown_preview.dart`)
##### GitHub Flavored Markdown
- 启用 `ExtensionSet.gitHubWeb`：支持表格、任务列表（checkbox）、删除线、自动链接
- `checkboxBuilder`：渲染任务列表复选框（Material Icons，主题色）
- `onTapLink`：点击链接复制 URL 到剪贴板

##### 代码块增强
- 自定义 `CodeBlockBuilder`（继承 `MarkdownElementBuilder`）：
  - 从 `<code>` 元素的 `class` 属性提取语言标签
  - 显示语言名称标签（等宽字体，灰色）
  - 深色/浅色主题自适应代码背景色
  - `SelectableText` 支持代码选择复制
- 代码块样式：圆角边框、等宽字体、行高 1.5

##### 样式增强
- 表格：`tableBody` 文本样式、`tableCellsPadding` 单元格内边距、`tableColumnWidth` 弹性列宽
- 删除线：`del` 样式（lineThrough + onSurfaceVariant）
- 链接：`a` 样式（primary 色 + underline）
- 代码块背景色：深色主题 `#1E1E2E`，浅色主题 `#F6F8FA`

#### 2. 知识图谱功能
##### 数据模型 (`lib/features/graph/models/graph_data.dart`)
- `GraphNode`：id/title/tags/priority/坐标(x,y)/半径
- `GraphEdge`：sourceId/targetId/label（共享标签名）
- `GraphData`：
  - `applyForceLayout()`：力导向布局算法（节点斥力 + 边引力 + 阻尼）
  - `normalize()`：归一化坐标到画布尺寸范围

##### 图谱 Provider (`lib/features/graph/providers/graph_provider.dart`)
- `graphDataProvider`：从 `notesProvider` 派生
- 节点 = 每条笔记，边 = 共享相同标签的两条笔记
- 边标签 = 共享的标签名

##### 图谱画布 (`lib/features/graph/widgets/graph_canvas.dart`)
- `GraphCanvas`：StatefulWidget + CustomPaint
- 手势交互：`onScaleStart/Update/End` 支持平移和缩放
- 点击检测：通过 `_lastFocalPoint` + 低速度判断点击 vs 拖拽
- `_GraphPainter`（CustomPainter）：
  - 边绘制：线条 + 中点标签
  - 节点绘制：圆形（颜色按优先级：tertiary/primary/error）+ 标题截断显示
  - 变换：`canvas.translate` + `canvas.scale`

##### 图谱页面 (`lib/features/graph/pages/graph_page.dart`)
- `GraphPage`：ConsumerWidget
- 空状态：无笔记时引导创建
- 图谱渲染：`applyForceLayout` + `normalize` + `GraphCanvas`
- 统计信息浮层：笔记数 + 关联数
- 图例弹窗：优先级颜色说明 + 边含义
- 节点点击 → 跳转笔记编辑器

##### 路由与导航
- `app_router.dart`：新增 `/graph` 路由
- `notes_list_page.dart`：AppBar 新增知识图谱图标按钮

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (86 tests)

### 技术决策
- **ExtensionSet.gitHubWeb**: 启用 GFM 扩展集而非自定义扩展，覆盖表格/任务列表/删除线等常用语法
- **CodeBlockBuilder**: 自定义 `MarkdownElementBuilder` 替代默认 `pre` 渲染，支持语言标签和选择复制
- **力导向布局**: 实现 O(n²) 斥力 + O(e) 引力的简单力导向算法，适合中小规模笔记图谱（<100 节点）
- **CustomPainter vs 第三方库**: 使用 `CustomPainter` 自绘图谱，避免引入 `graphview` 等额外依赖，保持项目轻量
- **手势检测**: `ScaleEndDetails` 无 `focalPoint`，通过 `onScaleUpdate` 追踪 `_lastFocalPoint` + 速度判断实现点击检测

### Git 提交记录
```
2083487 feat: Week 2 Day 3 - Markdown rendering enhancement and knowledge graph
```

### 明日计划 (Week 2 Day 4)
- 知识图谱交互增强（节点拖拽、长按多选）
- 笔记导出功能（Markdown 文件导出到本地）
- 应用图标与启动页定制

## 2026-08-15 | Week 2 Day 4 — 图谱交互增强 + 笔记导出 + 应用图标

### 今日完成

#### 1. 知识图谱交互增强
##### 节点拖拽
- `onScaleStart`：检测触摸点是否命中节点，记录 `_draggedNode`
- `onScaleUpdate`：单指拖拽节点时实时更新 `node.x/y`，通过 `_screenToCanvas()` 坐标转换
- 拖拽 vs 平移：`details.pointerCount == 1` 且命中节点 → 拖拽，否则 → 平移缩放
- 视觉反馈：被拖拽节点显示光晕（`primary` 色 20% 透明度外圈）

##### 长按多选
- `onLongPressStart`：长按节点进入选择模式，触发 `HapticFeedback.mediumImpact()`
- 选择模式下点击节点 → `_toggleSelection()`（添加/移除选中）
- 选中节点视觉：`primary` 色填充 + 3px 边框 + 右上角勾选标记（✓）
- 选中节点的关联边高亮：`primary` 色 50% 透明度，2.5px 粗线
- 非选中节点的边标签隐藏，减少视觉干扰

##### 多选操作栏
- `GraphPage` 改为 `ConsumerStatefulWidget`，维护 `_selectedIds` 和 `_isSelectionMode`
- AppBar 适配：选择模式显示"已选 N 篇"标题 + 关闭按钮 + 删除/打开操作
- 顶部提示浮层：选择模式下显示"长按选择，点击节点添加/移除选中"
- 批量删除：确认对话框 → 逐条调用 `deleteNote` → 刷新图谱
- 单选打开：仅选中 1 篇时显示"打开笔记"按钮，跳转编辑器
- 图例新增：长按多选 + 拖拽节点操作说明

#### 2. 笔记导出功能
##### ExportService (`lib/services/export_service.dart`)
- `exportNote(NoteModel)` → 导出单条笔记为 `.md` 文件，返回文件路径
- `exportAllNotes(List<NoteModel>)` → 批量导出，返回 `ExportResult`（路径/成功数/错误列表）
- 复用 `SyncService.noteToMarkdown()` 生成 YAML front matter + 正文
- 复用 `SyncService.slugify()` 生成安全文件名
- 导出目录：`{applicationDocumentsDirectory}/flutter_notes_export/`

##### Provider 集成
- `exportServiceProvider`：使用 `SyncService(github, 'export-only')`，不依赖 GitHub token
- 导出服务仅使用 `noteToMarkdown` 和 `slugify` 方法，token 占位符不影响功能

##### 设置页导出
- 替换"即将推出"占位符为实际导出功能
- 导出完成后显示对话框：成功/失败计数 + 导出路径（可选择复制到剪贴板）

##### 编辑器单条导出
- AppBar 新增导出按钮（`Icons.ios_share`），仅编辑已有笔记时显示
- 导出后显示文件路径对话框 + 复制路径按钮

#### 3. 应用图标与启动页定制
##### 应用图标
- 使用 AI 生成 1024x1024 应用图标（蓝色背景 + 白色笔记本 + Markdown "M" 符号）
- 添加 `flutter_launcher_icons: ^0.13.1` dev 依赖
- 配置 `flutter_launcher_icons`：Android 自适应图标，背景色 `#1565C0`
- 运行 `dart run flutter_launcher_icons` 自动生成多分辨率 mipmap 图标
- 自动创建 `colors.xml` 并注册 `ic_launcher_background` 颜色

##### 启动页定制
- `launch_background.xml`：背景色从白色改为 `#1565C0`（应用主色），居中显示应用图标
- `values/colors.xml`：新增 `launch_background` 颜色定义
- `values-night/colors.xml`：深色模式启动页背景色 `#0D47A1`（更深蓝）
- assets 注册：`assets/app_icon.jpg` 添加到 pubspec.yaml

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (86 tests)

### 技术决策
- **节点拖拽坐标转换**：`_screenToCanvas()` 将屏幕坐标转换为画布坐标（减去偏移后除以缩放），确保拖拽位置精确
- **长按 vs 点击区分**：`onLongPressStart` 独立于 `onScaleEnd`，不冲突；选择模式下 `onScaleEnd` 的点击行为改为切换选中
- **ExportService 复用 SyncService**：避免重复实现 `noteToMarkdown` 和 `slugify`，通过占位 token 创建 SyncService 实例
- **flutter_launcher_icons**：自动生成多分辨率 Android 图标（mdpi~xxxhdpi），避免手动创建 5 个尺寸的 mipmap 文件
- **启动页深色适配**：通过 `values-night/colors.xml` 提供深色模式下的更深背景色，无需额外 drawable 文件

### Git 提交记录
```
504e35b feat: Week 2 Day 4 - graph interaction, note export, app icon and splash screen
```

### 明日计划 (Week 2 Day 5)
- 笔记全文搜索增强（SQLite FTS5 全文索引）
- 笔记回收站功能（软删除 + 恢复）
- 应用主题色自定义（多种种子色选择）

## 2026-08-15 | Week 2 Day 5 — FTS5 全文搜索 + 回收站 + 主题色自定义

### 今日完成

#### 1. SQLite FTS5 全文搜索增强

##### 数据库 Schema 升级 (`lib/data/database/app_database.dart`)
- schemaVersion 升级至 2，新增 `deletedAt` 列（软删除支持）
- 创建 FTS5 虚拟表 `notes_fts`：索引 note_id（UNINDEXED）/ title / content / tags
- 使用 `unicode61` 分词器，支持中文和 Unicode 文本
- 三个触发器自动维护 FTS 索引：
  - `notes_ai`（AFTER INSERT）：新增笔记时同步插入 FTS 索引
  - `notes_ad`（AFTER DELETE）：删除笔记时同步删除 FTS 索引
  - `notes_au`（AFTER UPDATE）：更新笔记时先删后插重建索引
- `_populateFts()`：数据库升级时从现有笔记数据填充 FTS 索引

##### 仓库层搜索实现 (`lib/data/repositories/note_repository.dart`)
- `searchNotes(query)`：使用 `customSelect` 执行 FTS5 JOIN 查询
- 查询 SQL：`SELECT n.* FROM notes n JOIN notes_fts f ON n.id = f.note_id WHERE notes_fts MATCH ? AND n.deleted_at IS NULL`
- `_buildFtsQuery(input)`：构建 FTS5 兼容查询字符串
  - 双引号转义：`"` → `""`
  - 前缀搜索：自动添加 `*` 后缀（如 `"Dart"*` 匹配 Dart、Dartian 等）
- 搜索结果排除已软删除的笔记
- 使用 `row.read<T>()` 逐列读取 `QueryRow` 数据

##### 搜索 Provider 迁移 (`lib/features/search/providers/search_provider.dart`)
- `searchResultsProvider`：从客户端 `where` 过滤迁移至数据库级 FTS 搜索
- 监听 `notesProvider` 变更自动刷新搜索结果

#### 2. 笔记回收站功能（软删除 + 恢复）

##### 数据模型扩展 (`lib/data/models/note_model.dart`)
- 新增 `deletedAt`（`DateTime?`）字段，null 表示未删除
- 更新 `fromJson` / `toJson` / `copyWith` 方法支持 `deletedAt`

##### 仓库层 CRUD 扩展
- `getDeletedNotes()`：查询 `deletedAt IS NOT NULL` 的笔记，按删除时间倒序
- `deleteNote(id)`：改为软删除（`UPDATE ... SET deleted_at = NOW()`）
- `restoreNote(id)`：恢复笔记（`UPDATE ... SET deleted_at = NULL`）
- `permanentlyDeleteNote(id)`：物理删除（`DELETE FROM notes WHERE id = ?`）
- `emptyTrash()`：清空回收站（`DELETE FROM notes WHERE deleted_at IS NOT NULL`）
- `getAllNotes()` / `watchAllNotes()`：增加 `deletedAt.isNull()` 过滤条件

##### 回收站页面 (`lib/features/notes/pages/trash_page.dart`)
- `ConsumerStatefulWidget`，异步加载已删除笔记列表
- 顶部信息栏：显示已删除笔记数量
- 每张卡片显示标题、摘要、删除时间
- 恢复按钮：调用 `restoreNote`，SnackBar 提示 + 刷新列表
- 永久删除按钮：确认对话框 → `permanentlyDeleteNote`
- 清空回收站：AppBar 按钮 → 确认对话框 → `emptyTrash`
- `RefreshIndicator` 支持下拉刷新
- 空状态：回收站为空时引导提示

##### 笔记列表页修复 (`lib/features/notes/pages/notes_list_page.dart`)
- 修复撤销删除 Bug：`addNote(note)` → `restoreNote(note.id)`（原实现会创建重复笔记）
- 删除提示文案：「已删除」→「已移入回收站」
- AppBar 新增回收站入口（`Icons.delete_outline`）

##### 路由与设置集成
- `app_router.dart`：新增 `/trash` 路由
- `settings_page.dart`：数据管理区新增「回收站」入口

#### 3. 应用主题色自定义

##### 种子色定义 (`lib/core/theme/app_colors.dart`)
- 新增 `SeedColorOption` 数据类（name + color）
- 8 种预设种子色：紫色 / 蓝色 / 绿色 / 橙色 / 粉色 / 青色 / 靛蓝 / 红色

##### 偏好持久化 (`lib/services/preferences_service.dart`)
- 新增 `getSeedColor()` / `setSeedColor(int argb)` 方法
- 存储键 `seed_color`，默认值 `0xFF6750A4`（紫色）

##### 状态管理 (`lib/features/settings/providers/settings_provider.dart`)
- 新增 `SeedColorNotifier`（`Notifier<Color>`）：读取/设置种子色
- `seedColorProvider`：暴露当前种子色给 `app.dart` 和设置页

##### 主题动态生成 (`lib/core/theme/app_theme.dart`)
- `light` / `dark` 方法改为接受可选 `seedColor` 参数
- 使用 `ColorScheme.fromSeed(seedColor: seedColor)` 动态生成色板

##### 应用根组件 (`lib/app.dart`)
- `ref.watch(seedColorProvider)` 获取当前种子色
- 传递给 `AppTheme.light(seedColor: seedColor)` 和 `AppTheme.dark(seedColor: seedColor)`

##### 设置页 UI (`lib/features/settings/pages/settings_page.dart`)
- 外观区新增「主题色」ListTile：显示当前色名 + 色块预览
- 底部弹窗颜色选择器：8 种颜色圆形按钮，选中显示勾选标记
- `_seedColorLabel(color)`：根据 ARGB 值匹配预设色名

#### 4. 测试更新

##### 仓库层测试 (`test/repositories/note_repository_test.dart`)
- 原 `deleteNote` 测试组适配软删除行为：
  - 「removes note from active list」：验证 `getAllNotes` 不含已删除笔记
  - 「sets deletedAt timestamp」：验证 `getNoteById` 返回 `deletedAt != null`
  - 「soft-deleted note appears in getDeletedNotes」：验证回收站查询
  - 「does not throw when deleting non-existent ID」：兼容性验证
- 新增 `restoreNote` 测试组（1 项）：恢复后笔记回到活跃列表 + `deletedAt` 为 null
- 新增 `permanentlyDeleteNote` 测试组（1 项）：物理删除后 `getNoteById` 返回 null
- 新增 `emptyTrash` 测试组（2 项）：清空回收站 + 不影响活跃笔记
- 新增 `searchNotes (FTS5)` 测试组（7 项）：
  - 按标题/内容/标签关键词搜索
  - 空查询返回空列表
  - 无匹配返回空列表
  - 排除已软删除笔记
  - 前缀搜索（`"Mar"*` 匹配 Markdown）

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (98 tests)
  - Widget tests: 6
  - Repository tests: 42（含 15 项新增回收站 + FTS 搜索测试）
  - Encryption service tests: 16
  - GitHub service tests: 22
  - Sync service tests: 24

### 遇到的问题及解决

#### 问题 1: `QueryRow.readTable` 方法不存在
- **现象**: `customSelect` 返回的 `QueryRow` 调用 `readTable` 报 `undefined_method`
- **原因**: `readTable` 是 `TypedResult`（`select().get()` 返回类型）的方法，`QueryRow`（`customSelect` 返回类型）不支持
- **解决**: 改用 `row.read<String>('column_name')` 逐列读取，可空列使用 `row.readNullable<T>()`

#### 问题 2: `use_build_context_synchronously` 警告
- **现象**: 回收站页面对话框回调中 `Navigator.pop(context)` 后继续使用 `context` 触发 lint 警告
- **原因**: 对话框 `context` 在 `pop` 后失效，`State.mounted` 检查不等价于 `BuildContext` 有效性检查
- **解决**: 将 `showDialog` builder 参数从 `context` 重命名为 `dialogContext`，并在 async gap 前捕获 `ScaffoldMessenger` 实例

#### 问题 3: 软删除导致原有测试失败
- **现象**: `getNoteById returns null after deletion` 测试失败，软删除后笔记仍可查到
- **原因**: `deleteNote` 从物理删除改为软删除，`getNoteById` 不过滤已删除笔记（回收站需查看）
- **解决**: 重写测试验证软删除行为（`deletedAt` 非空、出现在 `getDeletedNotes`、不在 `getAllNotes` 中）

### 技术决策
- **FTS5 虚拟表 + 触发器**: 使用外部内容表方案（FTS 表存储副本），通过 INSERT/UPDATE/DELETE 触发器自动同步索引，应用层 CRUD 无需感知 FTS 存在
- **前缀搜索**: FTS5 查询末尾添加 `*` 实现前缀匹配，双引号包裹防止特殊字符（如空格）被解释为查询语法
- **软删除 vs 物理删除**: `deletedAt` 时间戳方案，`getAllNotes` / `searchNotes` 过滤已删除项，`getNoteById` 保留访问（回收站查看），`permanentlyDeleteNote` 提供不可逆删除
- **种子色动态主题**: `ColorScheme.fromSeed` 接受任意 `Color`，运行时切换无需重启，ARGB int 持久化到 `SharedPreferences`
- **颜色选择器 UI**: 底部弹窗 + 圆形色块 + 勾选标记，直观简洁，8 种预设色覆盖常见需求

### Git 提交记录
```
62833f1 feat: Week 2 Day 5 - FTS5 full-text search, trash (soft delete), and theme color customization
```

### 明日计划 (Week 3 Day 1)
- go_router 路由迁移（声明式路由 + 深链接）
- 笔记编辑器增强（图片插入、代码高亮）
- 应用性能优化（列表懒加载、数据库索引）

## 2026-08-20 | Week 3 Day 1 — go_router 迁移 + 编辑器增强 + 性能优化

### 今日完成

#### 1. go_router 声明式路由迁移

##### 路由配置重构 (`lib/core/router/app_router.dart`)
- 从 Flutter 内置 `Navigator.pushNamed` 迁移至 `go_router` 声明式路由
- 8 条路由路径常量：`/` / `/editor` / `/search` / `/settings` / `/graph` / `/github-login` / `/sync-settings` / `/trash`
- `GoRouter` 配置：`initialLocation` + `routes` 列表 + `errorBuilder`（404 页面）
- 新增 `createRouter()` 工厂方法，支持测试中创建独立路由实例（避免单例状态污染）
- 静态单例 `_router` 改为 `createRouter()` 调用

##### 全应用导航替换
- `notes_list_page.dart`：`Navigator.pushNamed` → `context.push(AppRouter.xxx)`
- `note_editor_page.dart`：`Navigator.pushNamed` → `context.push(AppRouter.editor, extra: noteId)`
- `search_page.dart`：搜索结果点击跳转 → `context.push(AppRouter.editor, extra: note.id)`
- `graph_page.dart`：节点点击跳转 → `context.push(AppRouter.editor, extra: note.id)`
- `settings_page.dart`：各入口跳转 → `context.push(AppRouter.xxx)`
- `sync_settings_page.dart`：GitHub 登录跳转 → `context.push(AppRouter.githubLogin)`
- `trash_page.dart`：恢复后跳转 → `context.push(AppRouter.editor, extra: note.id)`

##### 应用根组件 (`lib/app.dart`)
- `MaterialApp` → `MaterialApp.router`，使用 `routerConfig: AppRouter.router`
- 支持深链接：外部可通过 URL 直接访问特定页面

#### 2. 笔记编辑器增强

##### 图片插入功能 (`lib/features/editor/pages/note_editor_page.dart`)
- 工具栏新增图片按钮（`Icons.image_outlined`）
- `_showImageDialog()`：弹窗输入图片 URL 和替代文本
- 插入 Markdown 语法 `![alt](url)` 到光标位置
- `_insertAtCursor()`：在当前光标位置插入文本

##### 代码语法高亮 (`lib/features/editor/widgets/markdown_preview.dart`)
- 引入 `flutter_highlight` 包，替换 `SelectableText` 为 `HighlightView`
- 亮色主题：`githubTheme`（GitHub 风格浅色）
- 暗色主题：`atomOneDarkTheme`（Atom One Dark 风格深色）
- 代码块显示语言标签（从 `class` 属性提取）
- 等宽字体 + 1.5 行高 + 圆角背景容器

##### 依赖添加 (`pubspec.yaml`)
- `go_router: ^14.6.0`
- `flutter_highlight: ^0.7.0`
- `highlight: ^0.7.0`

#### 3. 应用性能优化

##### 数据库索引 (`lib/data/database/app_database.dart`)
- schemaVersion 升级至 3
- 新增 `_createIndexes(Migrator m)` 方法，创建 3 个索引：
  - `idx_notes_deleted_at`：优化软删除过滤查询
  - `idx_notes_updated_at`：优化按更新时间排序
  - `idx_notes_priority`：优化按优先级筛选
- `onUpgrade` 迁移：`from < 3` 时自动创建索引
- `onCreate` 中也调用 `_createIndexes` 确保新安装时建索引

##### 列表懒加载优化 (`lib/features/notes/pages/notes_list_page.dart`)
- `ListView.builder` 添加 `cacheExtent: 500`（预渲染 500 像素的列表项）
- 减少滚动时的频繁构建，提升列表滑动流畅度
- `// ignore: deprecated_member_use` 抑制 cacheExtent 弃用警告

#### 4. 测试修复

##### GoRouter 单例测试隔离 (`test/widget_test.dart`)
- **问题**：`AppRouter.router` 为静态单例，测试间路由状态不重置。Test 2 导航至 `/editor` 后，后续测试仍停留在编辑器页面，找不到首页 FAB 和导航图标
- **修复**：`pumpApp` 中使用 `AppRouter.createRouter()` 创建独立路由实例，替代 `FlutterNotesApp` 直接构建 `MaterialApp.router`
- 移除 `FlutterNotesApp` 导入，直接使用 `MaterialApp.router` + `AppTheme` + `AppRouter.createRouter()`
- 98 项测试全部通过（94 项已有 + 4 项修复的 widget 测试）

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (98 tests)

### 遇到的问题及解决

#### 问题 1: GoRouter 单例导致 widget 测试失败
- **现象**：4 项 widget 测试失败（Editor preview toggle / Search page / Search filters / Settings page）
- **原因**：`GoRouter` 为 `static final` 单例，测试间路由状态持久化。Test 2 导航到 `/editor` 后，后续测试的 `pumpApp` 虽然重建 widget 树，但路由仍停留在 `/editor`，首页元素（FAB、搜索图标、更多按钮）不存在
- **解决**：将路由配置抽取为 `createRouter()` 工厂方法，测试中每次 `pumpApp` 创建独立 `GoRouter` 实例

#### 问题 2: flutter_highlight 主题导入路径
- **现象**：`package:flutter_highlight/themes/github-dark.dart` 导入报错
- **原因**：`flutter_highlight` 包不含 `github-dark.dart` 文件
- **解决**：改用 `atom-one-dark.dart` 作为深色主题

#### 问题 3: cacheExtent 弃用警告
- **现象**：`cacheExtent` 在新版 Flutter 中标记为 `@Deprecated`
- **原因**：Flutter 推荐使用 `CacheExtent` 替代，但当前版本仍可用
- **解决**：添加 `// ignore: deprecated_member_use` 注释暂时抑制，后续升级时替换

### 技术决策
- **go_router vs Navigator**：go_router 提供声明式路由配置、深链接支持、URL 同步、更好的可测试性，是 Flutter 官方推荐的路由方案
- **createRouter() 工厂方法**：将路由配置与单例解耦，生产环境使用单例（性能），测试环境使用工厂（隔离）
- **flutter_highlight 主题**：选择 GitHub light + Atom One Dark 组合，与代码编辑器视觉习惯一致
- **数据库索引策略**：针对 `deleted_at`（软删除过滤）、`updated_at`（排序）、`priority`（筛选）三个高频查询条件建索引，覆盖主要查询路径
- **cacheExtent 优化**：500 像素预渲染约 5-6 个笔记卡片，在流畅度和内存占用间取得平衡

### Git 提交记录
```
2c9f76b feat: Week 3 Day 1 - go_router migration, editor enhancements, performance optimization
```

### 明日计划 (Week 3 Day 2)
- Widget 测试增强（go_router 路由测试、编辑器图片插入测试）
- 知识图谱节点搜索功能
- 笔记批量操作（多选删除/导出）

## 2026-08-20 | Week 3 Day 2 — 批量操作 + 图谱搜索 + 测试增强

### 今日完成

#### 1. 笔记列表批量操作（多选删除/导出）

##### NotesListPage 重构 (`lib/features/notes/pages/notes_list_page.dart`)
- `ConsumerWidget` → `ConsumerStatefulWidget`，管理 `_selectedIds` 和 `_isSelectionMode` 状态
- 长按笔记卡片进入多选模式，自动选中该笔记
- 多选模式下：
  - AppBar 标题显示「已选 N 篇」
  - 关闭按钮退出选择模式
  - 全选/取消全选按钮（`Icons.select_all`）
  - 导出选中笔记按钮（`Icons.ios_share`）
  - 批量删除按钮（`Icons.delete_outline`），确认对话框 → 移入回收站
  - FAB 隐藏
  - 禁用 Dismissible 滑动删除
- 选择模式下点击笔记切换选中/取消选中
- `_selectAll()` / `_exitSelectionMode()` / `_toggleSelection()` 方法

##### NoteCard 组件增强 (`lib/features/notes/widgets/note_card.dart`)
- 新增 `isSelected` 和 `showCheckbox` 参数
- 多选模式下显示圆形复选框（选中 `Icons.check_circle` / 未选 `Icons.radio_button_unchecked`）
- 选中状态卡片背景色变为 `primaryContainer`
- 卡片内容从 Column 改为 Row（复选框 + 内容），保持原有布局

##### 批量导出实现
- `_exportSelected()`：获取选中笔记 → 调用 `ExportService.exportAllNotes()` → 显示导出结果对话框
- 复用已有 `ExportService` 的 `exportAllNotes` 方法，无需额外实现

#### 2. 知识图谱节点搜索功能

##### 图谱页面搜索栏 (`lib/features/graph/pages/graph_page.dart`)
- 顶部浮层搜索栏（`_SearchBar` 组件），圆角输入框 + 搜索图标 + 清除按钮
- 搜索关键词实时过滤：匹配节点标题或标签（不区分大小写）
- 匹配结果计数浮层：「匹配 N 个节点」或「无匹配节点」
- `_getHighlightedIds(GraphData graph)`：返回匹配搜索条件的节点 ID 集合

##### GraphCanvas 搜索高亮 (`lib/features/graph/widgets/graph_canvas.dart`)
- 新增 `highlightedIds` 和 `hasSearch` 参数
- 搜索激活时：
  - 匹配节点：tertiary 色光晕 + 正常颜色
  - 非匹配节点：25% 透明度变暗 + 标题文字变淡
  - 匹配节点间的边：正常颜色
  - 非匹配边：8% 透明度极淡
- `shouldRepaint` 新增 `highlightedIds` 和 `hasSearch` 比较

##### 图例更新
- 新增搜索说明：「搜索栏按标题或标签筛选节点」

#### 3. Widget 测试增强

##### 新增 9 项 Widget 测试（共 15 项 → 107 项总测试）
- **go_router 路由导航测试（3 项）**：
  - 导航至回收站页面（点击回收站按钮 → 验证页面标题）
  - 导航至设置页面（点击更多按钮 → 验证页面标题）
  - 导航至知识图谱页面（点击知识图谱按钮 → 验证页面标题）
- **编辑器图片插入测试（1 项）**：
  - 点击图片工具栏按钮 → 验证对话框显示
  - 通过 `labelText` 精确定位对话框输入框（URL + 替代文本）
  - 点击插入 → 验证内容输入框包含 `![alt](url)` Markdown 语法
  - 通过 `hintText` 精确定位内容输入框（排除对话框 TextField 干扰）
- **批量操作测试（3 项）**：
  - 长按笔记进入选择模式（验证标题、全选/导出/删除按钮、FAB 隐藏）
  - 全选/取消全选（验证「已选 6 篇」→ 再次点击退出选择模式）
  - 关闭按钮退出选择模式
- **图谱搜索测试（2 项）**：
  - 图谱页显示搜索栏（验证 TextField 和提示文本）
  - 搜索显示匹配计数（输入关键词 → 验证「匹配 N」提示）

### 验证结果
- `flutter analyze`: No issues found (0 errors, 0 warnings)
- `flutter test`: All tests passed! (107 tests, 新增 9 项)

### 遇到的问题及解决

#### 问题 1: `_insertAtCursor` 在对话框中插入失败
- **现象**：编辑器内容为空时，通过图片对话框插入 Markdown 语法无效
- **原因**：新建的 `TextEditingController` 默认 `selection` 为 `TextSelection.collapsed(offset: -1)`，`isValid` 返回 `false`，导致 `_insertAtCursor` 跳过插入逻辑
- **解决**：当 `selection.isValid` 为 false 时，默认插入到文本末尾（`currentText.length`），并设置新的光标位置

#### 问题 2: Widget 测试中 TextField 定位错误
- **现象**：图片插入测试中 `find.byType(TextField).at(0/1)` 找到的是编辑器的标题/内容输入框而非对话框的
- **原因**：对话框是 Overlay 渲染在编辑器之上，`find.byType(TextField)` 按 Widget 树顺序返回，对话框 TextField 排在编辑器之后
- **解决**：改用 `find.byWidgetPredicate` 通过 `decoration.labelText` 精确匹配对话框输入框（'图片 URL' / '替代文本'），内容输入框通过 `hintText.contains('Markdown')` 匹配

### 技术决策
- **ConsumerStatefulWidget 选择模式**：笔记列表需要维护选中状态集合，StatefulWidget 提供生命周期管理和 `setState` 局部刷新
- **NoteCard 复选框设计**：使用 `Icons.check_circle` / `Icons.radio_button_unchecked` 图标而非 `Checkbox` widget，视觉更紧凑且与卡片设计一致
- **图谱搜索实时过滤**：搜索栏 `onChanged` 直接 `setState` 更新搜索词，`_getHighlightedIds` 在 build 中计算匹配集合，无需额外 Provider
- **图谱搜索高亮策略**：匹配节点加 tertiary 色光晕，非匹配节点变暗至 25% 透明度，保持图谱结构可见但突出搜索结果
- **测试定位策略**：使用 `find.byWidgetPredicate` + `decoration` 属性精确定位 Widget，避免索引依赖和脆弱测试

### Git 提交记录
```
e8290ea feat: Week 3 Day 2 - batch operations, graph search, and 9 new widget tests
```

### 明日计划 (Week 3 Day 3)
- 笔记标签管理增强（标签 CRUD、颜色标记）
- 笔记排序选项（按标题/创建时间/优先级）
- 应用国际化（i18n）基础框架

## 2026-08-20 | Week 3 Day 3 — 标签管理 + 排序选项 + 国际化基础

### 今日完成

#### 1. 笔记标签管理增强

##### 标签元数据服务（已存在）
- services/tag_metadata_service.dart：TagMetadataService 提供 8 种预设颜色和 SharedPreferences 持久化
- 颜色按标签名存储为 	agName|ARGB 格式

##### 标签管理 Notifier (lib/features/notes/providers/tags_provider.dart)
- 新增 TagsManagerNotifier 提供 4 个核心方法：
  - createTag(name, color?)：创建标签（仅注册颜色配置）
  - deleteTag(name)：从所有笔记中移除该标签并清除颜色，返回受影响笔记数
  - enameTag(oldName, newName)：批量重命名 + 转移颜色配置，验证名称合法性
  - setColor(name, color) / esetColor(name)：颜色调整
- TagInfo 类扩展 color 字段，从 	agMetadataServiceProvider 注入
- llTagsProvider 同步注入颜色元数据

##### 标签管理页面 (lib/features/notes/pages/tag_management_page.dart)
- 列表展示所有标签（带头像颜色、笔记数量）
- PopupMenu 提供「重命名 / 更改颜色 / 重置颜色 / 删除」4 个操作
- _showCreateDialog：新建标签（名称 + 8 色选择器）
- _showRenameDialog：重命名（验证非空、不重复）
- _showColorPicker：调整颜色
- _showDeleteDialog：确认删除并显示受影响笔记数
- 完整的 SnackBar 反馈

##### UI 集成
- 	ag_filter_bar.dart：标签前显示彩色圆点 avatar
- 
ote_card.dart：标签 chip 背景使用 Color.lerp(color, surface, 0.18) 混合，文字加深
- pp_router.dart：新增 	agManagement = '/tags' 路由
- settings_page.dart：数据管理分区新增「标签管理」入口

#### 2. 笔记排序选项

##### 排序 Provider (lib/features/notes/providers/sort_provider.dart)
- 枚举 NoteSortOrder 5 种排序：
  - updatedAtDesc：最近修改（默认）
  - createdAtDesc：最新创建
  - createdAtAsc：最早创建
  - 	itleAsc：标题 A→Z
  - priorityDesc：优先级高→低
- NoteSortOrderNotifier：状态管理，默认 updatedAtDesc
- sortedNotesProvider：组合 ilteredNotesProvider + 当前排序方式，链式应用

##### UI 集成 (lib/features/notes/pages/notes_list_page.dart)
- AppBar 新增排序按钮（Icons.sort）
- PopupMenuButton 显示 5 种排序方式，当前选项带 ✓ 标记
- 列表替换为 ef.watch(sortedNotesProvider)

#### 3. 应用国际化（i18n）基础框架

##### 依赖与配置
- pubspec.yaml：添加 lutter_localizations 依赖
- intl：从 0.18.1 升级到 0.20.2（flutter_localizations 要求）
- pubspec.yaml flutter: 添加 generate: true 启用代码生成
- 新增 l10n.yaml 配置（rb-dir, 	emplate-arb-file, output-class: AppLocalizations）

##### ARB 翻译文件
- lib/l10n/app_en.arb：英文模板（40+ 键）
- lib/l10n/app_zh.arb：中文翻译
- 关键字符串：appTitle, settingsTitle, tagManagement, sortUpdatedAtDesc 等
- 占位符示例：	agDeleteConfirm 接受 
ame + count 两个参数

##### 生成的代码
- lutter pub get 触发 gen-l10n 自动生成：
  - pp_localizations.dart（委托）
  - pp_localizations_en.dart
  - pp_localizations_zh.dart
- 所有页面可通过 AppLocalizations.of(context).xxx 获取翻译

##### Locale Provider 与持久化
- settings_provider.dart 新增 ppLocaleProvider 和 AppLocaleNotifier
- supportedLocales：[Locale('en'), Locale('zh')]
- PreferencesService：新增 getLocaleCode() / setLocaleCode(String?)
- pp.dart：使用 onGenerateTitle + locale + localizationsDelegates

#### 4. 测试增强

##### 新增 17 项测试（共 124 项）
- **标签元数据服务测试（5 项）**：	est/services/tag_metadata_service_test.dart
  - 默认颜色、未设置时返回紫色
  - set/remove/get 颜色持久化
  - getAllTagColors 映射
  - 损坏数据优雅降级
- **排序 Provider 测试（10 项）**：	est/providers/sort_provider_test.dart
  - NoteSortOrder 中文标签完整性
  - Notifier 默认值与 setOrder
  - 4 种排序行为（updatedAtDesc / titleAsc 大小写不敏感 / priorityDesc / createdAtAsc）
- **Widget 测试（4 项）**：	est/widget_test.dart
  - 排序菜单显示 5 种选项
  - 选择「标题 A→Z」后菜单关闭
  - 设置 → 标签管理入口（使用大屏幕 1080x2400）
  - 标签管理页显示已存在标签

### 验证结果
- lutter analyze: No issues found (0 errors, 0 warnings)
- lutter test: All tests passed! (124 tests, 新增 17 项)

### 遇到的问题及解决

#### 问题 1: Edit 工具返回成功但文件未变更
- **现象**：连续多次使用 Edit 修改同一文件时，第一次返回成功但文件未变
- **原因**：可能为本地文件系统的状态同步延迟
- **解决**：当 Edit 无效时改用 Write 完整重写文件，确保变更生效

#### 问题 2: intl 0.18.1 与 flutter_localizations 不兼容
- **现象**：lutter pub get 报 intl 0.20.2 is required
- **原因**：lutter_localizations 强制 pin intl 到 0.20.2
- **解决**：升级 intl: ^0.18.1 → intl: ^0.20.2

#### 问题 3: 标签管理测试中 ListTile 找不到
- **现象**：ind.widgetWithText(ListTile, '标签管理') 报 0 widgets
- **原因**：默认测试屏幕 800x600 太矮，设置页 ListTile 多，超出可视区域
- **解决**：测试开头 	ester.view.physicalSize = Size(1080, 2400) 扩大屏幕

#### 问题 4: PowerShell 中 flutter.bat 找不到 git
- **现象**：lutter.bat 调用全大写 WHERE 命令时失败
- **原因**：PowerShell 默认 PATH 不含 C:\Windows\System32 和 git 路径
- **解决**：在每个 shell 调用前显式设置 $env:Path 包含 C:\Windows\System32 + git 路径

### 技术决策
- **TagInfo 颜色注入方式**：llTagsProvider 内部直接调用 	agMetadataServiceProvider.getTagColor()，避免每个消费者都读取服务，提高复用性
- **删除标签策略**：直接修改所有引用笔记的 	ags 列表（不可撤销），借助回收站机制提供最终保险
- **重命名冲突检查**：enameTag 拒绝同名（避免覆盖），拒绝空名
- **颜色混合策略**：Color.lerp(color, surface, 0.18) 让标签 chip 在浅/深主题下都有可读背景
- **排序 Provider 链式设计**：sortedNotesProvider watch ilteredNotesProvider + 
oteSortOrderProvider，自动响应两者变化，无需手动刷新
- **国际化默认值**：locale 为 null 时跟随系统，由 MaterialApp 自动解析
- **ARB 占位符**：使用 ICU 格式 {name} + 占位符定义，比手写 String.format 更易维护
- **flutter_localizations 升级策略**：跟随 Flutter SDK 主版本，新版本会强制 pin intl

### Git 提交记录
`
<待提交>
`

### 明日计划 (Week 3 Day 4)
- 标签页面 i18n 改造
- 笔记列表 i18n 改造
- 完整测试覆盖（包括 i18n 切换测试）
- 性能监控（启动时间、滚动帧率）
