# Dart 语言基础复习

> Week 1 Day 1 学习笔记 — 类型系统、空安全、异步编程

---

## 一、类型系统

### 1.1 强类型 & 类型推断

Dart 是强类型语言，支持类型推断。`var` 声明的变量类型在编译期确定后不可更改。

```dart
var name = 'Flutter';    // 推断为 String
name = 42;               // 编译错误：String 不能赋值 int
final count = 10;        // 运行时常量（不可重新赋值）
const PI = 3.14;         // 编译时常量
```

### 1.2 常量：final vs const

| 特性 | `final` | `const` |
|------|---------|---------|
| 赋值时机 | 运行时 | 编译时 |
| 可用于实例变量 | 是 | 否 |
| 值可计算 | 是 | 否（必须字面量） |
| 列表/Map 深层不可变 | 否 | 是 |

```dart
final now = DateTime.now();    // OK — 运行时取值
const now = DateTime.now();    // 编译错误

const list1 = [1, 2, 3];       // 深层不可变
final list2 = [1, 2, 3];       // 仅引用不可变，内容可改
list2.add(4);                  // OK
list1.add(4);                  // 编译错误
```

### 1.3 泛型

Dart 泛型是**具体化泛型**（reified），类型信息在运行时保留。

```dart
List<int> numbers = [1, 2, 3];
Map<String, dynamic> config = {'version': 1, 'name': 'notes'};

// 泛型方法
T firstOrDefault<T>(List<T> list, T defaultValue) =>
    list.isEmpty ? defaultValue : list.first;
```

### 1.4 Record（Dart 3.0+）

```dart
// 匿名 Record
var note = ('Dart 基础', 'content', 3);
print(note.$1); // Dart 基础

// 命名 Record
({String title, int priority}) createNote() =>
    (title: 'Hello', priority: 2);
```

### 1.5 Pattern Matching（Dart 3.0+）

```dart
switch (priority) {
  case NotePriority.high:
    print('紧急');
  case NotePriority.medium:
    print('普通');
  case NotePriority.low:
    print('低优');
}

// 解构
final (title, content) = ('Dart', '基础复习');
```

---

## 二、空安全（Null Safety）

### 2.1 核心规则

Dart 3 的空安全是**健全的（sound）**：类型系统层面保证非空变量不会持有 `null`。

| 声明 | 含义 |
|------|------|
| `String name` | 不可为 null，必须初始化 |
| `String? name` | 可为 null |
| `late String name` | 延迟初始化，首次访问前必须赋值 |
| `String! name` | 强制解空（仅用于类型断言，运行时不安全） |

### 2.2 空值处理操作符

```dart
String? nickname;

// ?? 空值合并
String display = nickname ?? '匿名';

// ?. 空安全调用
int? length = nickname?.length;

// ! 空断言（若为 null 抛异常）
int forceLength = nickname!.length;

// ??= 空值赋值
nickname ??= '默认昵称';
```

### 2.3 流程提升（Flow Promotion）

```dart
void printLength(String? text) {
  if (text == null) return;
  // 此处 text 自动提升为 String（非空）
  print(text.length);
}

// is 类型检查也会提升
void process(dynamic value) {
  if (value is String) {
    print(value.toUpperCase()); // value 提升为 String
  }
}
```

### 2.4 late 关键字

```dart
class NoteEditor {
  late final TextEditingController controller;

  void init() {
    controller = TextEditingController(); // 延迟到此时初始化
  }
}
```

> **注意**：`late` 变量在首次访问前未赋值会抛出 `LateInitializationError`。

---

## 三、异步编程

### 3.1 Future

```dart
Future<String> fetchNote(String id) async {
  await Future.delayed(const Duration(seconds: 1));
  return 'Note content for $id';
}

// 调用
void main() async {
  final content = await fetchNote('1');
  print(content);
}
```

### 3.2 Stream

Stream 是异步事件序列，类似 RxJS Observable。

```dart
Stream<int> countDown(int from) async* {
  for (var i = from; i >= 0; i--) {
    await Future.delayed(const Duration(seconds: 1));
    yield i;
  }
}

// 消费
await for (final count in countDown(5)) {
  print(count);
}
```

### 3.3 async / await

| 关键字 | 作用 |
|--------|------|
| `async` | 标记函数为异步，返回值自动包装为 Future |
| `await` | 暂停执行直到 Future 完成 |
| `async*` | 标记为异步生成器，返回 Stream |
| `sync*` | 同步生成器，返回 Iterable |
| `yield` | 生成器中发射一个值 |

### 3.4 错误处理

```dart
try {
  final result = await riskyOperation();
} on FormatException catch (e) {
  // 特定异常类型
  print('格式错误: $e');
} catch (e, stackTrace) {
  // 任意异常 + 堆栈
  print('未知错误: $e\n$stackTrace');
} finally {
  cleanup();
}
```

### 3.5 Future 常用方法

```dart
// 并行等待多个 Future
final results = await Future.wait([
  fetchNote('1'),
  fetchNote('2'),
  fetchNote('3'),
]);

// 任一完成即返回
final fastest = await Future.any([
  fetchFromCache(),
  fetchFromNetwork(),
]);

// 超时控制
final data = await fetchNote('1').timeout(
  const Duration(seconds: 5),
  onTimeout: () => '默认值',
);
```

### 3.6 区域（Zone）

Zone 提供了异步代码的执行上下文隔离，Flutter 框架内部大量使用。

```dart
runZonedGuarded(() {
  // 在此区域内运行的异步代码
  // 未捕获的错误会被 zone 的 onError 捕获
  doSomethingAsync();
}, (error, stack) {
  print('Zone 捕获: $error');
});
```

---

## 四、本项目中的实践要点

1. **模型类空安全**：`NoteModel` 的 `id` 使用 `?? const Uuid().v4()` 确保非空
2. **JSON 解析**：`fromJson` 中所有字段使用 `?? 默认值` 防止 null
3. **异步服务**：后续 `GithubService` / `SyncService` 将大量使用 `async/await`
4. **Stream 应用**：数据库变更监听（drift `.watch()` 返回 Stream）
5. **空安全与 UI**：`Widget?` 用于条件渲染，配合 `if` 语句在 Collection 中

```dart
// UI 中的空安全实践
Column(
  children: [
    Text(note.title),
    if (note.content.isNotEmpty) Text(note.excerpt),
    if (note.tags.isNotEmpty) Wrap(children: note.tags.map(Tag.new).toList()),
  ],
)
```

---

## 参考链接

- [Dart 语言之旅](https://dart.dev/language)
- [空安全详解](https://dart.dev/null-safety)
- [异步编程](https://dart.dev/libraries/async)
