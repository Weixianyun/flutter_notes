import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'design_tokens.dart';

/// 自定义页面转场动画
///
/// 提供三档非默认转场，配合 Hero / 普通路由使用：
/// - [fadeUp] - 自下而上淡入（适合详情页 / 子页面）
/// - [sharedAxis] - 共享元素转场容器（适合编辑页 / 共享元素）
/// - [zoom] - 缩放淡入（适合模态 / 弹窗化页面）
///
/// 所有转场时长与曲线都引用 [AppDurations] / [AppCurves]，
/// 保持与设计系统其它动画一致。
class AppPageTransitions {
  AppPageTransitions._();

  /// 自下而上淡入：详情页 / 列表子项
  ///
  /// - 入场：从底部 16dp 向上滑动 + 淡入
  /// - 退场：向下滑动 + 淡出
  /// - 时长：`AppDurations.medium` (280ms)
  static PageRouteBuilder<T> fadeUp<T>(Widget child, {Duration? duration}) {
    return PageRouteBuilder<T>(
      transitionDuration: duration ?? AppDurations.medium,
      reverseTransitionDuration: duration ?? AppDurations.medium,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.easeOut,
          reverseCurve: AppCurves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// 缩放淡入：模态 / 弹窗化页面
  ///
  /// - 入场：从 0.92 放大到 1.0 + 淡入
  /// - 退场：缩小 + 淡出
  /// - 时长：`AppDurations.medium` (280ms)
  static PageRouteBuilder<T> zoom<T>(Widget child, {Duration? duration}) {
    return PageRouteBuilder<T>(
      transitionDuration: duration ?? AppDurations.medium,
      reverseTransitionDuration: duration ?? AppDurations.medium,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.easeOut,
          reverseCurve: AppCurves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// 共享轴转场：与 [Hero] 配合的转场容器
  ///
  /// 单独使用仅是淡入 + 轻微 X 轴位移，强烈建议与 [AppAnimations.noteHero]
  /// 等 Hero 包装组合，可达到 Material 3 Shared Axis 风格效果。
  /// 时长：`AppDurations.medium` (280ms)
  static PageRouteBuilder<T> sharedAxis<T>(
    Widget child, {
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration ?? AppDurations.medium,
      reverseTransitionDuration: duration ?? AppDurations.medium,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.easeOut,
          reverseCurve: AppCurves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// 走 go_router 时的 Page（带自定义转场）
  ///
  /// 给 `pageBuilder` 使用的 `CustomTransitionPage`，
  /// 让单个路由可独立使用非默认转场而不影响其它路由。
  static CustomTransitionPage<T> sharedAxisPage<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: AppDurations.medium,
      reverseTransitionDuration: AppDurations.medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppCurves.easeOut,
          reverseCurve: AppCurves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
