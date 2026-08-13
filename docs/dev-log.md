# Flutter Notes 开发日志

## 2026-08-13 | 环境搭建 + 项目初始化

### 今日完成

#### 1. 开发环境搭建 (Step 1-6)

| 组件 | 版本 | 说明 |
|------|------|------|
| Flutter SDK | 3.44.9 (stable) | 安装到 `C:\flutter`,配置国内镜像 |
| Dart | 3.12.2 | 随 Flutter 自带 |
| Android Studio | 2026.1.3.7 | 含 Android SDK |
| Android SDK | Platform 34/35/36 + Build Tools | 含 NDK 28.2、CMake 3.22.1 |
| Android 模拟器 | Pixel 7 (API 36, Android 16) | 已创建并验证运行 |
| Git | 2.55.0.windows.4 | 用户: weixianyun <weixianyun55@gmail.com> |
| SSH 密钥 | ed25519 | 已生成 |
| Windows 开发者模式 | 已启用 | 插件符号链接需要 |

**flutter doctor 结果**: Flutter / Windows / Android toolchain / Connected device / Network resources 全部通过。

#### 2. 项目初始化 (Step 4)

- 创建 Flutter 项目: `flutter create --org com.weixianyun flutter_notes`
- 配置 14 个依赖包: Riverpod, Drift, flutter_markdown, encrypt, http, oauth2, uuid 等
- 建立目录结构: `core/` `data/` `features/` `services/` `shared/`
- 配置代码规范: 4 条 lint 规则 (prefer_const, avoid_print, require_trailing_commas)
- Git 初始化 + 2 次提交
- **flutter run 验证通过**: 应用在模拟器上成功启动

### 遇到的问题与解决方案

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| Windows 开发者模式未开启 | Flutter 插件需要符号链接 | 注册表启用 Developer Mode |
| file_picker 6.2.1 编译失败 | 使用已废弃的 Flutter v1 API | 升级到 11.0.3 |
| file_picker 11.0.3 Kotlin 冲突 | AGP 9.0 内置 Kotlin,插件未适配 | 暂时移除,Week 9 再添加 |
| Kotlin 增量编译缓存损坏 | 项目路径含空格 | `kotlin.incremental=false` |
| 模拟器首次启动 ADB 连接失败 | ADB 服务器状态异常 | 重启 ADB 服务器 |
| GitHub OAuth App 未创建 | 网络原因需 VPN | 待手动创建 |

### 待办事项

- [ ] TraeCode 安装 Flutter 插件
- [ ] GitHub 添加 SSH 公钥
- [ ] 创建 GitHub OAuth App (Client ID + Secret)
- [ ] Week 1: Dart 语言基础与 UI 原型

### Git 提交记录

```
a549d39 fix: disable Kotlin incremental compilation, defer file_picker to Week 9
ea6bfe8 chore: initial Flutter project setup
```

### 备注

- `file_picker` 因 AGP 9.0 兼容性问题暂时移除,计划在 Week 9 (导入导出功能) 时重新评估
- 项目路径含空格 (`Flutter Markdown`),已禁用 Kotlin 增量编译避免缓存问题
- 后续每次开发完成后需:提交代码、推送 GitHub、更新本日志
