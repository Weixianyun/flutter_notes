[English](README.md) | **中文**

# flutter_notes

一款基于 Flutter 的 Markdown 笔记应用，支持本地加密存储与 GitHub 云端同步。

## 功能特性

- **Markdown 编辑器** — 所见即所得的编辑体验，基于 `flutter_markdown` 实时渲染预览
- **本地数据库** — 离线优先存储，使用 `sqflite` + `drift` ORM
- **AES-256 加密** — 所有笔记在本地加密存储，基于 `encrypt` + `crypto`
- **GitHub 云端同步** — 通过 GitHub REST API + OAuth 2.0 实现双向同步
- **知识图谱** — 可视化笔记关联关系（规划中）
- **全文搜索** — 应用内快速搜索笔记（规划中）
- **深色 / 浅色主题** — Material 3 自适应主题

## 技术栈

| 类别 | 技术 |
|---|---|
| 框架 | Flutter 3.x / Dart 3.x |
| 状态管理 | Riverpod 2.x + riverpod_generator |
| 本地数据库 | sqflite + drift |
| Markdown 渲染 | flutter_markdown + markdown |
| 加密 | AES-256 (encrypt + crypto) |
| 云端同步 | GitHub REST API + OAuth 2.0 |
| Android 目标 | API 36 (Android 16.0) |

## 项目结构

```
lib/
├── core/           # 路由、主题、工具类
│   ├── router/
│   ├── theme/
│   └── utils/
├── data/           # 数据层
│   ├── database/   # Drift 数据库定义
│   ├── models/     # 数据模型
│   └── repositories/ # 仓库模式
├── features/       # 功能模块
│   ├── editor/     # Markdown 编辑器
│   ├── graph/      # 知识图谱
│   ├── notes/      # 笔记列表与详情
│   ├── search/     # 全文搜索
│   └── sync/       # 云端同步界面
├── services/       # 业务服务
│   ├── crypto_service.dart
│   ├── github_service.dart
│   └── sync_service.dart
├── shared/         # 共享组件
├── app.dart        # 应用入口与主题配置
└── main.dart       # 主入口
```

## 快速开始

### 环境要求

- Flutter SDK 3.x (Dart 3.x)
- Android Studio（含 Android SDK API 36）
- Git

### 安装

```bash
# 克隆仓库
git clone https://github.com/Weixianyun/flutter_notes.git
cd flutter_notes

# 安装依赖
flutter pub get

# 运行代码生成（drift, riverpod）
dart run build_runner build --delete-conflicting-outputs
```

### 运行应用

```bash
# 调试模式
flutter run

# 发布构建
flutter build apk --release
```

## 开发指南

### 代码生成

修改模型或 Provider 后，需要重新生成代码：

```bash
dart run build_runner build --delete-conflicting-outputs

# 开发时使用监听模式
dart run build_runner watch --delete-conflicting-outputs
```

### 代码检查

```bash
flutter analyze
```

## 文档

- [开发日志](docs/dev-log.md)

## 许可证

本项目为个人使用，未授权公开发布。
