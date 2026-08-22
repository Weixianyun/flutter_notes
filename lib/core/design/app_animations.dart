import 'package:flutter/material.dart';

import '../design/design_tokens.dart';

/// 通用动画工具集
///
/// 提供以下能力：
/// - [listItem]:列表项进入动画（淡入 + 上移，可选错位）
/// - [SwitchingView]:三态切换动画（loading / empty / content）
/// - [pressable]:按钮按下缩放反馈
/// - [iconSwap]:两个图标之间平滑切换
class AppAnimations {
  AppAnimations._();

  /// 列表项错位进入动画
  ///
  /// 第 N 个元素延迟 `N * staggerMs`，营造自然错位效果。
  /// 适合 [ListView.builder] 顶部 20~30 条以内，超过会失去节奏感。
  static Widget listItem({
    required int index,
    required Widget child,
    int staggerMs = 30,
  }) {
    final delay = Duration(milliseconds: staggerMs * index);
    return TweenAnimationBuilder<double>(
      key: ValueKey('list-item-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.medium + delay,
      curve: AppCurves.easeOut,
      builder: (context, value, c) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  /// 图标淡入淡出切换
  static Widget iconSwap({
    required IconData icon,
    double size = 24,
    Color? color,
  }) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Icon(
        icon,
        key: ValueKey(icon.codePoint),
        size: size,
        color: color,
      ),
    );
  }

  /// 按钮按下缩放反馈包装
  static Widget pressable({
    required Widget child,
    required VoidCallback? onTap,
    double scaleDown = 0.96,
  }) {
    return _AnimatedPressable(
      onTap: onTap,
      scaleDown: scaleDown,
      child: child,
    );
  }
}

/// 三态切换视图（loading / empty / content）
///
/// 使用 [AnimatedSwitcher] 在三态之间淡入淡出（280ms），
/// 避免列表初次加载 → 空态 → 有数据 切换时突兀跳变。
class SwitchingView extends StatelessWidget {
  const SwitchingView({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.content,
    required this.loading,
    required this.empty,
  });

  final bool isLoading;
  final bool isEmpty;
  final Widget content;
  final Widget loading;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    final stateName = isLoading ? 'loading' : (isEmpty ? 'empty' : 'content');
    final child = switch (stateName) {
      'loading' => loading,
      'empty' => empty,
      _ => content,
    };
    return AnimatedSwitcher(
      duration: AppDurations.medium,
      switchInCurve: AppCurves.easeOut,
      switchOutCurve: AppCurves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey('switch-$stateName'),
        child: child,
      ),
    );
  }
}

/// 私有：按下缩放反馈
class _AnimatedPressable extends StatefulWidget {
  const _AnimatedPressable({
    required this.child,
    required this.onTap,
    this.scaleDown = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  @override
  State<_AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<_AnimatedPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp:
          widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: AppDurations.fast,
        curve: AppCurves.easeOut,
        child: widget.child,
      ),
    );
  }
}
