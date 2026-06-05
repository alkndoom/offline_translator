# How to Architect and Build a Scalable Flutter App

> A generalized, domain-agnostic blueprint for structuring a production Flutter
> application. It is distilled from a real, large codebase (~750 Dart files,
> ~18 feature modules) and stripped of all business-specific naming. Use it as a
> template: copy the folder structure, the layer contracts, and the patterns,
> then drop your own domain on top.
>
> Throughout this guide, `app_app` stands in for your package name and `Xx`
> stands in for your app's two-to-three-letter design-system prefix (e.g. a
> button widget is `XxButton`). Replace both with your own.

---

## Table of Contents

1. [Guiding Philosophy](#1-guiding-philosophy)
2. [The Three-Tier Folder Structure](#2-the-three-tier-folder-structure)
3. [Layer 1 — `app/`: The Composition Root](#3-layer-1--app-the-composition-root)
4. [Layer 2 — `core/`: The Shared Kernel](#4-layer-2--core-the-shared-kernel)
5. [Layer 3 — `features/`: Vertical Slices](#5-layer-3--features-vertical-slices)
6. [The Data Layer: Repositories, Gateways, Mappers](#6-the-data-layer-repositories-gateways-mappers)
7. [The Domain Layer: Entities & Use Cases](#7-the-domain-layer-entities--use-cases)
8. [The Presentation Layer: Controllers, State, Views](#8-the-presentation-layer-controllers-state-views)
9. [State Management Strategy](#9-state-management-strategy)
10. [Dependency Injection & Bindings](#10-dependency-injection--bindings)
11. [Ports & Adapters: Keeping `core` Pure](#11-ports--adapters-keeping-core-pure)
12. [The Network Stack](#12-the-network-stack)
13. [Cross-Platform Abstraction](#13-cross-platform-abstraction)
14. [Error Handling Strategy](#14-error-handling-strategy)
15. [The Design System](#15-the-design-system)
16. [Navigation & Routing](#16-navigation--routing)
17. [Adding a New Feature: A Step-by-Step Recipe](#17-adding-a-new-feature-a-step-by-step-recipe)
18. [Testing Architecture](#18-testing-architecture)
19. [CI/CD Pipeline & Release Gates](#19-cicd-pipeline--release-gates)
20. [Security Hardening Checklist](#20-security-hardening-checklist)
21. [Performance, Web/Wasm & Footprint Budgets](#21-performance-webwasm--footprint-budgets)
22. [Architectural Enforcement](#22-architectural-enforcement)
23. [Architectural Rules (The Short List)](#23-architectural-rules-the-short-list)

---

## 1. Guiding Philosophy

The architecture rests on four ideas that, together, let a codebase grow to
hundreds of files without collapsing into a ball of mud:

1. **Clean Architecture, applied per feature.** Each feature is internally split
   into three layers — **data**, **domain**, **presentation** — with a strict
   dependency rule: *dependencies point inward*. Presentation depends on domain;
   data depends on domain; **domain depends on nothing**. The domain layer is
   the stable core; outer layers are replaceable details.

2. **Feature-first (vertical slicing), not layer-first.** The top-level
   organizing unit is the *feature*, not the *layer*. All the code for one
   capability lives together under `features/<name>/`. You can understand,
   test, or delete a feature by looking in one folder.

3. **Program to contracts, not implementations.** Every boundary is an abstract
   class (interface). Repositories, gateways, ports, session providers, the
   navigator — all are abstractions with concrete implementations wired in at
   composition time. This is what makes the app testable and the layers swappable.

4. **A shared kernel that knows nothing about features.** Cross-cutting
   concerns (design system, network, error handling, config) live in `core/`.
   Crucially, `core/` never imports from `features/` and never imports
   generated or vendor-specific code directly — it depends only on *ports* it
   defines itself.

The result is a dependency graph shaped like this:

```
   ┌───────────────────────────────────────────────────────────────┐
   │  app/   composition root — wires the graph and OWNS the        │
   │         infrastructure adapters (API registry, HTTP chain)     │
   └───────┬───────────────────────────────────────────┬───────────┘
           │ depends on                                 │ owns / binds
           ▼                                            ▼
   ┌──────────────────────────┐  data uses  ┌───────────────────────────┐
   │     features/<name>/      │────────────▶│      infrastructure/      │
   │  presentation ──▶ domain  │             │  adapters wrap generated/ │
   │  data ──────────▶ domain  │             │  & implement core ports   │
   └────────────┬─────────────┘             └──────┬──────────────┬─────┘
                │ depends on                        │ wraps        │ implements
                ▼                                   ▼              ▼
   ┌──────────────────────────┐      ┌──────────────────┐  ┌──────────────┐
   │          core/           │      │    generated/    │  │  core/ports  │
   │  pure: defines ports;     │      │  (codegen DTOs   │  │ (interfaces, │
   │  imports no features,     │      │  + per-resource  │  │  part of     │
   │  generated, or infra      │      │   API services)  │  │  core/)      │
   └──────────────────────────┘      └──────────────────┘  └──────────────┘
```

The **infrastructure adapter** (the API registry + HTTP decorator chain) is
app-wide and owned by the composition root — not a feature. It is the single
place that wraps `generated/` and implements `core/ports`. A feature's `data`
layer *uses* that adapter (and maps DTOs to entities); it never owns the shared
client. See [§11.2](#112-where-does-the-generated-api-adapter-live).

---

## 2. The Three-Tier Folder Structure

At the top level, `lib/` has exactly three meaningful directories plus a thin
entrypoint:

```
lib/
├── main.dart                 # Entrypoint only — delegates immediately
├── app/                      # TIER 1: Composition root
│   ├── bootstrap/            #   - Startup sequence, lifecycle, root widget
│   ├── di/                   #   - Global dependency registration
│   └── routing/              #   - Route table aggregation
├── core/                     # TIER 2: Shared kernel (feature-agnostic)
│   ├── config/               #   - Environment configuration
│   ├── constants/            #   - App-wide constants & route names
│   ├── controllers/          #   - Base controller classes
│   ├── design_system/        #   - Reusable UI: tokens + components
│   ├── error/                #   - Exception hierarchy + handlers
│   ├── middlewares/          #   - Route guards
│   ├── navigation/           #   - Navigation abstraction
│   ├── network/              #   - HTTP client decorators, TLS pinning
│   ├── ports/                #   - Abstract interfaces core needs
│   ├── services/             #   - App-lifetime singletons (session, theme…)
│   ├── session/              #   - Session-state abstraction
│   ├── cache/                #   - Local storage wrappers
│   └── utils/                #   - Pure helpers & extensions
├── features/                 # TIER 3: Vertical feature slices
│   └── <feature>/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── generated/                # Code-generated API client (never hand-edited)
```

**Why this split scales:** the three tiers map directly onto *rate of change*
and *blast radius*. `generated/` changes when the backend contract changes.
`features/` change constantly but in isolation. `core/` changes rarely and
deliberately, because everything depends on it. `app/` changes only when you
add a feature or a global dependency.

---

## 3. Layer 1 — `app/`: The Composition Root

The `app/` directory is the only place that is allowed to know about *all*
features at once. It is where the object graph is assembled. Keep it thin.

### 3.1 The entrypoint stays trivial

`main.dart` should do almost nothing except hand off to the bootstrap and wrap
the app in a crash-reporting zone:

```dart
// lib/main.dart
Future<void> main() async {
  // 1. Bind FIRST. Crash SDKs and most plugins need the Flutter binding
  //    initialized before they can run; the bootstrap below can rely on it too.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Stand up crash/log capture before any risky bootstrap work, so failures
  //    during initialization are still recorded.
  await CrashReporter.init();

  // 3. A COMPLETE error funnel needs all three hooks — runZonedGuarded alone
  //    does not catch synchronous framework errors or platform-dispatcher errors.
  FlutterError.onError = (details) {
    CrashReporter.recordFlutterError(details);
    FlutterError.presentError(details);   // keep the red screen / console dump in debug
  };
  PlatformDispatcher.instance.onError = (error, stack) {            // async errors escaping the framework
    CrashReporter.recordError(error, stack, fatal: true);
    return true;
  };

  // 4. The zone catches uncaught async errors in non-framework callbacks.
  runZonedGuarded(() async {
    await AppBootstrap.initialize();              // deterministic startup
    runApp(const AppRoot());                       // first frame
  }, (error, stack) {
    CrashReporter.recordError(error, stack, fatal: true);
    AppLogger.error('Unhandled zoned error', exception: error, stackTrace: stack, tag: 'Main');
  });
}
```

> **`runZonedGuarded` is *not* a complete error funnel — it is one of three.**
> A frequent production bug is wiring only the zone and assuming everything is
> covered. The three hooks are complementary:
>
> | Hook | Catches |
> |------|---------|
> | `FlutterError.onError` | Synchronous errors inside Flutter framework callbacks (build, layout, paint, gestures). |
> | `PlatformDispatcher.instance.onError` | Asynchronous errors that escape the framework (engine/platform callbacks). |
> | `runZonedGuarded` | Uncaught errors in the Dart zone — async gaps not tied to a framework callback. |
>
> Initialize observability **before** `AppBootstrap.initialize()`, not after,
> or early-startup failures will only reach your logger and never your crash
> reporter. (Some crash SDKs expose an `appRunner:` wrapper that installs these
> hooks for you — if so, use it, but verify all three are covered.)

### 3.2 A deterministic bootstrap sequence

All ordered startup work lives in one place, behind a private constructor so it
can never be instantiated:

```dart
// lib/app/bootstrap/app_bootstrap.dart
class AppBootstrap {
  AppBootstrap._();

  static Future<void> initialize() async {
    // `main()` already called this before initializing the crash reporter; the
    // call is idempotent, so a defensive repeat here keeps the bootstrap usable
    // standalone (e.g. from integration tests) without requiring a double-init.
    WidgetsFlutterBinding.ensureInitialized();

    GlobalBindings().dependencies();             // register global singletons
    await Get.find<ThemeService>().init();        // hydrate persisted theme
    await Get.find<SessionService>().init();      // restore session from cache

    await _configureLocalization();
    await _lockOrientationOnMobile();
    _registerLifecycleObserver();
  }
}
```

The bootstrap is the single source of truth for "what must be true before the
first frame renders." Anything async and global — localization, persisted
settings, session restoration, third-party SDK init — belongs here, *in order*.

### 3.3 The root widget owns global UI concerns

The root widget configures the app shell: theme, localization delegates, the
route table, and a global builder that can inject app-wide overlays (a version
banner, a connectivity banner, a global back-gesture guard). It holds **no
business logic**.

```dart
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: GlobalBindings(),
      theme: buildTheme(AppColors.lightScheme),
      darkTheme: buildTheme(AppColors.darkScheme),
      themeMode: ThemeService.to.currentMode,
      initialRoute: AppRouter.initial,
      getPages: AppRouter.routes,
      unknownRoute: AppRouter.notFoundPage,
      builder: (context, child) => RootShell(child: child!),
    );
  }
}
```

### 3.4 Centralize the theme builder

Define your `ThemeData` once, mapping design-system tokens onto Material's
`TextTheme` and `ColorScheme` slots. This makes the *entire* default widget
catalog inherit your typography and color without per-widget styling.

---

## 4. Layer 2 — `core/`: The Shared Kernel

`core/` is the reusable foundation every feature builds on. Its golden rule:

> **`core/` may import from `core/`. It must never import from `features/` or
> from generated/vendor code.** When `core/` needs something the outer world
> provides, it declares a **port** (an abstract interface) and lets the
> composition root inject an implementation.

Subdivide `core/` by concern:

| Folder           | Responsibility                                                          |
|------------------|-------------------------------------------------------------------------|
| `config/`        | Typed access to environment values (base URLs, tokens, flags).          |
| `constants/`     | App-wide constants and shared route names.                              |
| `controllers/`   | Base controller classes every feature controller extends.              |
| `design_system/` | Tokens (color, type, spacing) + reusable widgets.                      |
| `error/`         | The exception hierarchy and centralized error handlers.                |
| `middlewares/`   | Route guards (auth redirects, onboarding redirects).                   |
| `navigation/`    | An injectable navigation abstraction.                                  |
| `network/`       | HTTP client decorators (retry, timeout), TLS pinning.                  |
| `ports/`         | Abstract interfaces `core` needs the outside world to fulfill.        |
| `services/`      | App-lifetime singletons orchestrating cross-feature concerns.         |
| `session/`       | A read-only abstraction over "who is the current user."               |
| `cache/`         | Wrappers over local/secure storage.                                   |
| `utils/`         | Pure functions, extensions, platform helpers.                         |

The distinction between `services/` and `ports/` is important and covered in
[§11](#11-ports--adapters-keeping-core-pure).

---

## 5. Layer 3 — `features/`: Vertical Slices

Every user-facing capability is a self-contained module under `features/`. The
canonical internal structure is identical for every feature, which means a
developer who learns one feature can navigate all of them:

```
features/<feature>/
├── data/
│   ├── repositories/      # Implementations of domain repository interfaces
│   ├── gateways/          # Implementations of domain gateway interfaces
│   ├── mappers/           # DTO  ⇆  domain-entity translation
│   └── datasources/       # (optional) low-level fetch/persist helpers
├── domain/
│   ├── entities/          # Plain, dependency-free business objects
│   ├── repositories/      # Abstract repository contracts (backend data)
│   ├── gateways/          # Abstract gateway contracts (device/platform)
│   └── usecases/          # One callable class per business operation
└── presentation/
    ├── bindings/          # Per-feature DI wiring
    ├── controllers/       # State holders + presentation logic
    ├── views/             # Full-screen pages
    ├── widgets/           # Feature-private widgets
    ├── constants/         # Feature-local strings, dimensions, validation
    └── <feature>_pages.dart  # Route table + route-name constants
```

**Consistency is the feature.** In the reference codebase, ~16 of ~18 features
follow this exact shape. The two exceptions are instructive:

- A **pure-presentation feature** (e.g. a screen that only composes existing
  controllers) may have *only* `presentation/`. Don't manufacture empty
  `data/` and `domain/` folders to satisfy symmetry.
- A trivial **leaf screen** (e.g. a splash screen) may be a single file. Not
  every screen deserves three layers — apply the full structure when a feature
  has real business logic and backend interaction.

> **Pragmatism rule:** the layered structure is a tool for managing complexity,
> not a tax to pay on every screen. Scale the ceremony to the complexity.

---

## 6. The Data Layer: Repositories, Gateways, Mappers

The data layer's job is to *implement the domain's contracts* using real I/O,
and to *translate* between the wire format and domain entities.

### 6.1 Repository vs. Gateway — a useful distinction

The reference codebase draws a deliberate line between two kinds of external
dependency:

- **Repository** → an abstraction over **backend/remote data**. "Fetch the list
  of items," "submit this form." Implemented against the generated API client.
- **Gateway** → an abstraction over a **device or platform capability**. "Read
  the device's contacts," "request a runtime permission," "write the session to
  secure storage." Implemented against OS/plugin APIs.

Both are interfaces declared in `domain/` and implemented in `data/`. Splitting
them keeps each implementation focused and makes it obvious whether a dependency
is "the server" or "the phone."

### 6.2 The repository pattern

The **interface lives in the domain layer** and speaks only in domain entities:

```dart
// domain/repositories/item_repository.dart
abstract class ItemRepository {
  Future<List<ItemEntity>> fetchItems({required int page});
  Future<ItemEntity?> submitItem(ItemDraft draft);
}
```

The **implementation lives in the data layer** and depends on the generated API
client plus a mapper. Note that it never lets a DTO escape — it maps to entities
before returning:

```dart
// data/repositories/item_repository_impl.dart
class ItemRepositoryImpl implements ItemRepository {
  final api.ItemsApi _itemsApi;
  final ItemMapper _mapper;

  ItemRepositoryImpl(this._itemsApi, {ItemMapper? mapper})
      : _mapper = mapper ?? const ItemMapper();

  @override
  Future<List<ItemEntity>> fetchItems({required int page}) async {
    final result = await _itemsApi.list(page: page);
    final dtos = result?.items ?? const <api.ItemDto>[];
    return dtos.map(_mapper.toEntity).toList(growable: false);
  }
}
```

### 6.3 The mapper pattern (anti-corruption layer)

Mappers are the **only** place where generated DTOs touch domain entities. They
are the seam that protects your domain from backend churn: when a field is
renamed on the wire, you change one mapper, not fifty call sites.

```dart
// data/mappers/item_mapper.dart
class ItemMapper {
  const ItemMapper();

  ItemEntity toEntity(api.ItemDto dto) => ItemEntity(
        id: dto.id,
        title: dto.title,
        status: _mapStatus(dto.status),     // enum ⇆ enum translation
      );

  ItemStatus _mapStatus(api.ItemStatusDto dto) {
    switch (dto) {
      case api.ItemStatusDto.active:   return ItemStatus.active;
      case api.ItemStatusDto.archived: return ItemStatus.archived;
    }
    throw ArgumentError('Unsupported status: ${dto.value}');
  }
}
```

Two rules for mappers: keep them **`const` and stateless**, and map enums
*explicitly* with an exhaustive switch — a new backend enum value should cause a
loud, obvious failure, not a silent default.

---

## 7. The Domain Layer: Entities & Use Cases

The domain is the **stable, dependency-free core**. A file in `domain/` should
import nothing but other domain files and the Dart SDK — no Flutter, no `http`,
no generated code, no state-management library.

### 7.1 Entities are plain business objects

Entities model your business concepts with immutable fields, named constructors
for distinct states, and computed getters that encode business rules:

```dart
// domain/entities/item_entities.dart
class ItemEntity {
  final String id;
  final String title;
  final ItemStatus status;

  const ItemEntity({required this.id, required this.title, required this.status});

  // Business rule expressed as a getter — not duplicated across the UI.
  bool get isEditable => status == ItemStatus.active;
}

enum ItemStatus { active, archived }
```

A useful refinement seen in the reference code: an **"intent" object** that
carries possibly-incomplete data plus a getter that validates whether it is
complete enough to proceed. This pushes validation into the domain where it
belongs:

```dart
class SubmissionIntent {
  final String token;
  final String? userId;
  final String? displayName;
  const SubmissionIntent({required this.token, this.userId, this.displayName});

  bool get isComplete => userId != null && displayName != null;
}
```

### 7.2 Use cases: one class, one operation

A **use case** wraps a single business operation as a callable object. It holds
its dependencies (repositories/gateways) by interface and exposes a `call`
method, so it can be invoked like a function:

```dart
// domain/usecases/item_usecases.dart
class FetchItemsUseCase {
  final ItemRepository _repository;
  FetchItemsUseCase(this._repository);

  Future<List<ItemEntity>> call({required int page}) =>
      _repository.fetchItems(page: page);
}

class SubmitItemUseCase {
  final ItemRepository _repository;
  SubmitItemUseCase(this._repository);

  Future<ItemEntity?> call(ItemDraft draft) => _repository.submitItem(draft);
}
```

**Why bother, when the use case often just forwards to the repository?** Three
reasons that pay off at scale:

1. **A vocabulary.** `SubmitItemUseCase` names a business action; a controller
   reads as a list of intentions, not a list of repository calls.
2. **A composition point.** When an operation needs *two* repositories or a
   gateway plus a repository (e.g. "complete registration" touches the backend
   *and* writes the local session), the use case is where that orchestration
   lives — keeping controllers thin and repositories single-purpose.
3. **A stable injection unit.** Controllers depend on use cases, so repository
   refactors don't ripple into presentation.

> If a use case would *only ever* forward a single call and you value brevity,
> it is legitimate to let the controller depend on the repository directly. The
> reference codebase chooses the explicit use-case layer for uniformity — pick
> one convention and apply it consistently.

---

## 8. The Presentation Layer: Controllers, State, Views

The presentation layer is split into four collaborating roles.

### 8.1 A base controller does the heavy lifting

Every feature controller extends a shared `BaseController` that centralizes the
three things every screen needs: **scoped loading state**, **safe async
execution**, and **session/navigation access**. This eliminates a huge amount of
boilerplate and makes error/loading behavior uniform across the app.

```dart
class BaseController<T extends SharedState> extends GetxController {
  final _loadingStates = <String>[].obs;     // tag-based, supports concurrency

  bool isLoading([String? tag]) =>
      tag == null ? _loadingStates.isNotEmpty : _loadingStates.contains(tag);

  void setLoading(bool value, [String? tag]) { /* add/remove tag */ }

  /// Run an async action with automatic loading + error handling and
  /// re-entrancy guarding (won't fire twice while already loading).
  Future<void> runSafe({
    String? tag,
    String? errorMessage,
    bool silent = false,
    required Future<void> Function() action,
    FutureOr<void> Function(Object e, StackTrace st)? onError,
    FutureOr<void> Function()? onSuccess,
    FutureOr<void> Function()? onFinally,
  }) async {
    if (isLoading(tag)) return;                          // re-entrancy guard
    await safeExecute(
      () async { if (!silent) setLoading(true, tag); await action(); },
      errorMessage: errorMessage,
      onError: onError, onSuccess: onSuccess,
      onFinally: () async { await onFinally?.call(); if (!silent) setLoading(false, tag); },
    );
  }
}
```

The **tag-based loading** model is worth highlighting: instead of a single
`isLoading` boolean, the controller tracks a *set* of in-flight operation tags.
A screen can show three independent spinners (e.g. "submitting", "loading more",
"refreshing") from one controller without them clobbering each other.

A feature controller then becomes refreshingly small — it composes use cases and
exposes intent methods:

```dart
class ItemController extends BaseController<ItemSharedState> {
  final FetchItemsUseCase _fetchItems;
  ItemController(ItemSharedState super.state, this._fetchItems);

  final _items = <ItemEntity>[].obs;
  List<ItemEntity> get items => _items.toList();

  Future<void> load() => runSafe(
        tag: 'load',
        action: () async => _items.assignAll(await _fetchItems(page: 1)),
      );
}
```

### 8.2 Specialized base controllers for recurring shapes

When a *pattern* of screen recurs — say, "search box + paginated results +
search history" — promote it to its own abstract base controller with a
contract. The reference codebase has a `BaseControllerWithSearch` that
implements debouncing, pagination (`loadMore`), pull-to-refresh, and persisted
search history once, so every search screen gets it for free by overriding two
methods (`onSearch` and `initialSearchBehavior`). Look for these repeated shapes
and factor them up.

### 8.3 Shared state: per-feature, resettable

State that must outlive a single controller or be shared across several
controllers in a feature lives in a `SharedState` object. It extends a base that
mandates a `reset()` method — essential for clearing user data on logout:

```dart
abstract class SharedState extends GetxController {
  void reset();      // every shared state must define how it clears itself
}

class ItemSharedState extends SharedState {
  final _selectedId = ''.obs;
  String get selectedId => _selectedId.value;
  void select(String id) => _selectedId.value = id;

  @override
  void reset() => _selectedId.value = '';
}
```

There is also a single app-wide `GlobalSharedState` for genuinely
cross-feature, ephemeral signals (e.g. "item X was just favorited" so any open
screen can react). This object is the most dangerous one in the app: it is a
global, long-lived root that everything can reach. A capped map is *necessary
but not sufficient*. Hold it to strict rules so it never decays into an
unbounded event bus and hidden memory root:

- **Bounded by construction.** Cap size with TTL/LRU eviction; expose only
  **typed events**, never arbitrary `dynamic` payloads.
- **No retained framework objects.** Never store a `BuildContext`, a widget, a
  controller, or a live `Stream`/subscription in global state.
- **Deterministic teardown.** It must `reset()` on logout (wired into the
  session service) and clean up any workers/timers/subscriptions in `onClose()`.
- **Leak-tested.** Add a test that drives heavy navigation churn and asserts the
  global state's footprint stays flat — this is where unmanaged growth hides.

If you find yourself reaching for global state to pass data *between two
features*, prefer an explicit port or a navigation argument instead.

### 8.4 Views are dumb; widgets are private

- **Views** (`presentation/views/`) are full screens. They are typically
  `StatelessWidget`s that compose design-system scaffolding and feature widgets.
  They contain *no business logic* — they read from a controller fetched via the
  DI container.
- **Widgets** (`presentation/widgets/`) are feature-private building blocks. A
  widget reaches for its controller with the service locator and wraps only the
  reactive parts in an observer:

```dart
class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ItemController>();
    return Obx(() => XxPrimaryButton(           // only this subtree rebuilds
          isLoading: controller.isLoading('submit'),
          onPressed: controller.submit,
        ));
  }
}
```

> **Rebuild discipline:** wrap the *smallest possible subtree* in a reactive
> observer (`Obx`), not the whole screen. The button above rebuilds when the
> loading flag flips; the static labels around it never do.

---

## 9. State Management Strategy

The reference codebase uses **GetX** as a unified solution for three jobs that
are often three separate libraries: reactive state, dependency injection, and
routing. The principles below transfer to Riverpod/BLoC/Provider even if the API
differs — what matters is the *discipline*, not the package.

### 9.1 Two complementary reactivity modes

- **Fine-grained reactive (`.obs` + `Obx`)** — for frequently-changing values
  bound to a small piece of UI (text fields, toggles, counters, lists). The
  observer subscribes automatically to any observable read inside it.
- **Coarse, id-targeted updates (`update([id])` + a builder keyed by `id`)** —
  for "notify exactly these listeners" semantics, used by the global shared
  state to ping specific widgets (e.g. only the favorite-button for item 42)
  without rebuilding everything.

### 9.2 The data-flow contract

```
View / Widget ──reads──▶ Controller ──calls──▶ UseCase ──▶ Repository/Gateway
     ▲                       │                                    │
     └──────reacts to────────┘                                    │
            (.obs / update)                                       ▼
                                          Mapper ⇄ Generated API / Platform
```

Data flows **down** through method calls (`view → controller → use case →
repository`); state changes flow **up** through observables (`controller →
view`). The view never calls a repository; the controller never touches a DTO;
the domain never imports the UI. Each arrow crosses exactly one layer boundary.

---

## 10. Dependency Injection & Bindings

DI is done with a **service locator** plus **per-route bindings**. There are two
scopes of lifetime, chosen deliberately:

| Mechanism                          | Lifetime                                            | Use for                                    |
|------------------------------------|-----------------------------------------------------|--------------------------------------------|
| `Get.put(..., permanent: true)`    | Created at bootstrap, never disposed                | Services, ports, session, theme, navigator |
| `Get.putAsync(() async => …)`      | Awaited at registration, then app-lifetime          | Singletons needing async init (storage, package info) |
| `Get.lazyPut(() => …, fenix: true)`| Built on first use, disposed on route exit, **rebuilt on revisit** | Controllers, repositories, use cases (the default) |
| `Get.lazyPut(() => …, fenix: false)`| Built on first use, disposed once and **not rebuilt** | Single-use objects that should not survive a back-and-forth |
| `Get.create(() => …)`              | **New instance per `find`**                          | Per-item controllers (e.g. one per list row) |

- **`permanent: true`** singletons are created once at bootstrap and never
  disposed (`GlobalBindings`). Never make a *controller* permanent — controllers
  hold view state and must die with their route.
- **`lazyPut` + `fenix: true`** is the right default for feature objects: they
  don't consume memory when off-screen, but they survive navigation churn.

**Lifecycle anti-patterns to forbid in review:**

- ❌ `fenix: true` on an object that owns **unmanaged external resources**
  (timers, streams, isolates, native handles) **unless** its `onClose()` fully
  releases them — `fenix` rebuilds will otherwise leak one set per revisit.
- ❌ Permanent controllers, or permanent anything that transitively holds a
  `BuildContext`.
- ❌ Eagerly resolving (`Get.find`) inside a binding (see §10.2) — it defeats
  laziness and forces construction of objects the route may never use.

### 10.1 Global bindings: idempotent and ordered

The global binding registers app-lifetime objects, guarding each with an
`isRegistered` check so re-entry (e.g. hot restart, re-running the initial
binding) is safe. Register **ports before the services that consume them**:

```dart
class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiClientRegistry>()) {
      Get.put(ApiClientRegistry().init(), permanent: true);
    }
    // Register the registry under the *port* interfaces it implements:
    if (!Get.isRegistered<ApiTokenPort>()) {
      Get.put<ApiTokenPort>(Get.find<ApiClientRegistry>(), permanent: true);
    }
    if (!Get.isRegistered<BackendSessionPort>()) {
      Get.put<BackendSessionPort>(Get.find<ApiClientRegistry>(), permanent: true);
    }
    // Services depend only on the ports above — never on the concrete registry:
    if (!Get.isRegistered<SessionService>()) {
      Get.put(SessionService(Get.find<ApiTokenPort>()), permanent: true);
    }
    // ...session, theme, navigator, global state...
  }
}
```

### 10.2 Feature bindings: wire the slice top-down

A feature's binding constructs its entire object graph in dependency order:
**state → repository → gateways → use cases → controllers**. Everything is
`lazyPut(fenix: true)` and every binding reads its dependencies by *interface*:

Resolve every dependency **inside the builder closure** with `Get.find()`. Do
**not** call `Get.find()` at the top level of the binding to capture a local —
that instantiates the object eagerly and defeats the entire point of `lazyPut`:

```dart
class ItemBindings implements Bindings {
  @override
  void dependencies() {
    // State
    Get.lazyPut(() => ItemSharedState(), fenix: true);

    // Repository — resolves its API client lazily, inside the closure
    Get.lazyPut<ItemRepository>(
      () => ItemRepositoryImpl(Get.find<ApiClientRegistry>().itemsApi),
      fenix: true,
    );

    // Use cases — each resolves the repository lazily
    Get.lazyPut(() => FetchItemsUseCase(Get.find<ItemRepository>()), fenix: true);
    Get.lazyPut(() => SubmitItemUseCase(Get.find<ItemRepository>()), fenix: true);

    // Controller — `Get.find()` infers the type from the constructor parameter
    Get.lazyPut(
      () => ItemController(Get.find(), Get.find<FetchItemsUseCase>()),
      fenix: true,
    );
  }
}
```

> **Why this matters:** with closures, *nothing* in the graph is built until the
> view actually calls `Get.find<ItemController>()`, which then cascades
> construction of exactly the objects that controller needs — and no more. The
> common shortcut of writing `final repo = Get.find<ItemRepository>();` right
> after `lazyPut` forces immediate construction and silently turns lazy
> registration into eager registration.

The binding is attached to the route ([§16](#16-navigation--routing)), so simply
navigating to a feature instantiates exactly the objects that feature needs, and
leaving disposes them.

---

## 11. Ports & Adapters: Keeping `core` Pure

This is the keystone pattern that lets `core/` depend on *no* feature and *no*
generated code, while still using them at runtime.

**The problem:** `core/`'s session service needs to set an auth token on the
HTTP client, and the HTTP client is the generated API client, which lives behind
an app-wide infrastructure adapter ([§11.2](#112-where-does-the-generated-api-adapter-live)).
If `core/` imported it directly, `core/` would depend on generated code — a
layering violation.

**The solution (Hexagonal / Ports & Adapters):**

1. `core/ports/` declares tiny, intention-revealing interfaces describing *only
   what core needs*:

   ```dart
   // core/ports/api_token_port.dart
   abstract class ApiTokenPort {
     void setToken(String token);
     void clearToken();
   }

   // core/ports/backend_session_port.dart
   abstract class BackendSessionPort {
     Future<void> logout();
     Future<bool> validateCurrentToken();
     Future<void> checkHealth();
   }
   ```

2. The concrete adapter (the generated-API registry, in the app-wide
   infrastructure module) *implements* those ports:

   ```dart
   class ApiClientRegistry extends GetxService
       implements ApiTokenPort, BackendSessionPort {
     // owns the generated ApiClient + every generated *Api service
     @override
     void setToken(String token) =>
         apiClient.defaultHeaderMap['Authorization'] = 'Bearer $token';
     @override
     Future<bool> validateCurrentToken() async { /* call generated authApi */ }
     // ...
   }
   ```

3. The composition root binds the concrete object *under the port interface*
   ([§10.1](#101-global-bindings-idempotent-and-ordered)), so `core/` services
   receive an `ApiTokenPort` and never learn the concrete type.

The same inversion appears in two more places, and you should reach for it
whenever an inner layer needs an outer capability:

- **`SessionProvider`** — a read-only interface (`sessionUser`, `isLoggedIn`)
  that any controller can depend on to ask "who's logged in," without coupling
  to the concrete auth service.
- **`AppNavigator`** — an injectable navigation facade whose methods are
  function fields with sensible defaults, so tests can substitute fakes and the
  app can support tab-scoped nested navigation (see [§16](#16-navigation--routing)).

### 11.1 Five roles, one decision table

The repository / gateway / port / service / adapter vocabulary is easy to
conflate. Pin the distinctions:

| Role | Layer | Direction | Definition |
|------|-------|-----------|------------|
| **Repository** | feature `domain` (interface) → `data` (impl) | feature needs backend | An interface over **backend/remote data**. |
| **Gateway** | feature `domain` (interface) → `data` (impl) | feature needs the device | An interface over a **device/platform capability** (contacts, permissions, camera). |
| **Core port** | `core/ports` (interface) | core needs infrastructure | An interface for what **`core` needs from the outer world** (token setter, session validator). |
| **Core service** | `core/services` | depends on ports | A cross-cutting **policy** that orchestrates ports (session/auth, theme). |
| **Adapter** | infrastructure module (impl) | binds outer → ports | A concrete class binding **generated/plugin/vendor code** to a port. |

### 11.2 Where does the generated-API adapter live?

The object that owns the generated client and implements `ApiTokenPort` /
`BackendSessionPort` is an **app-wide adapter**, not a feature. The reference
codebase places it under a `features/**/data` folder with a comment explaining
the intent was "keep generated API usage out of `core/`." That works, but it
creates confusing ownership: a global infrastructure object lives inside one
"feature" that has no UI.

**Preferred convention for new projects:** give app-wide adapters their own
home — `app/infrastructure/` or `app/adapters/` (or a dedicated top-level
`infrastructure/` module). Reserve `features/` for things that own a slice of
the UI. This keeps "the one HTTP client everyone shares" from masquerading as a
feature.

> **The litmus test for a port:** if `core/` (or any inner layer) is tempted to
> `import` something from an outer layer, stop and define a port instead.

---

## 12. The Network Stack

The HTTP layer is built from **composable client decorators** wrapping a base
`http.Client`. Each decorator does one thing and wraps the next — the classic
decorator pattern applied to networking:

```dart
// Composition (innermost first):
//   pinnedClient → RetryClient → TimeoutClient → generated ApiClient
apiClient = ApiClient(basePath: baseUrl)
  ..client = TimeoutClient(RetryClient(innerClient))
  ..defaultHeaderMap['X-App-Token'] = appToken;
```

The decorators, from the reference implementation:

- **`RetryClient`** — retries failed requests with **exponential backoff**, but
  *only when it is safe*: idempotent methods (`GET`/`HEAD`) retry on 5xx and
  timeouts; non-idempotent methods (`POST`/`PUT`/`PATCH`/`DELETE`) retry **only**
  on `503 Service Unavailable`. It carefully *copies* the request on each
  attempt (streamed bodies can't be re-sent) and fixes multipart boundaries.
- **`TimeoutClient`** — enforces a per-request deadline and raises a typed
  timeout exception the error layer understands.
- **Certificate pinning** — for production builds, pins the server's public-key
  (SPKI) hashes so a compromised CA can't MITM the app. It is applied
  conditionally: only for the configured host, and only when pins are present,
  with loud warnings if pinning is silently disabled.

**Why decorators:** each concern (retry, timeout, pinning) is independently
testable, independently toggleable, and added without touching the others or the
generated client. You can insert a logging or auth-refresh decorator into the
chain the same way.

**The generated client itself** lives under `generated/` and is owned by a
single **registry adapter** in the app-wide infrastructure module
([§11.2](#112-where-does-the-generated-api-adapter-live)) — *not* in any
feature. The registry constructs every per-resource API service once, shares one
configured `ApiClient` (with the decorator chain applied), and exposes the
services as fields. Feature `data` layers consume those services and immediately
map DTOs to entities, so generated types never escape a `data` layer.

---

## 13. Cross-Platform Abstraction

The app targets mobile *and* web from one codebase. Platform-specific
implementations are selected at **compile time** via Dart's conditional imports,
never with runtime `if (kIsWeb)` scattered through business logic.

The pattern uses three files per capability and a stub:

```
core/cache/
├── secure_token_storage.dart          # public API + conditional import
├── secure_token_storage_mobile.dart   # mobile implementation
├── secure_token_storage_web.dart      # web implementation
└── secure_token_storage_stub.dart     # compile-time fallback
```

```dart
// secure_token_storage.dart
export 'secure_token_storage_stub.dart'
    if (dart.library.io) 'secure_token_storage_mobile.dart'
    if (dart.library.js_interop) 'secure_token_storage_web.dart';
```

The rest of the app imports only the public file and is compiled against the
right implementation for the target platform. The same technique appears for the
pinned HTTP client (`_io` / `_stub`) and platform image views (`_web` / `_stub`).
Runtime platform checks (`kIsWeb`) are reserved for small, local decisions like
"lock orientation on mobile only."

**Make the convention disciplined so it doesn't sprawl into N copies of subtly
different code:**

- **`dart.library.io` is not "mobile" — it is "has `dart:io`,"** which includes
  **desktop** (Windows/macOS/Linux). If a capability is genuinely mobile-only,
  gate it on the actual platform at runtime, not on `dart.library.io`.
- **Stubs must fail loudly, not silently.** A `_stub.dart` fallback should
  either `throw UnsupportedError(...)` from each method or expose an
  `bool get isSupported => false` so callers can branch deliberately. A stub
  that returns fake-success data hides platform gaps until production.
- **One adapter per capability.** Wrap each platform-specific capability behind a
  single public interface file; don't scatter conditional imports across the
  call sites. This keeps the platform matrix in one place per capability.
- **Test every target.** Each platform variant must be exercised in CI
  (`flutter test` for io/stub, web test runner for the web variant), or the
  unused branch will rot.

---

## 14. Error Handling Strategy

Errors are handled with a **typed exception hierarchy** plus a **single funnel**
for converting any thrown object into user-facing feedback.

### 14.1 A typed exception hierarchy

A sealed-style base with specific subtypes lets you reason about failure modes
and (where useful) construct messages from HTTP status codes:

```dart
abstract class AppException implements Exception {
  final String message;
  final int? code;
  const AppException({required this.message, this.code});
}

class ServerException     extends AppException { /* fromCode(401) → "Unauthorized…" */ }
class NetworkException    extends AppException { /* connectivity */ }
class ValidationException extends AppException { /* bad input */ }
class AuthException       extends AppException { /* auth failed */ }
class TimeoutException    extends AppException { /* deadline exceeded */ }
// …Cache, Authorization, Parsing…
```

### 14.2 One funnel: `safeExecute` + `handleError`

`safeExecute` is the universal try/catch wrapper. It runs an action and routes
any error either to a caller-supplied `onError` or to the global `handleError`,
always running `onFinally`:

```dart
FutureOr<void> safeExecute(
  Future<void> Function() action, {
  String? errorMessage,
  FutureOr<void> Function(Object e, StackTrace st)? onError,
  FutureOr<void> Function()? onSuccess,
  FutureOr<void> Function()? onFinally,
}) async {
  try {
    await action();
    await onSuccess?.call();
  } catch (e, st) {
    if (onError != null) { await onError(e, st); }
    else { handleError(e, st: st, customMessage: errorMessage); }
  } finally {
    await onFinally?.call();
  }
}
```

`handleError` inspects the error type, extracts a human-readable message
(including parsing structured error bodies from the API), shows a uniform
dialog, and logs to the crash reporter. Because **every** controller action goes
through `runSafe` → `safeExecute`, the app has exactly one error-presentation
path. A developer adding a new screen gets correct, consistent error handling
for free — they never write a raw `try/catch` in presentation code.

### 14.3 Logging

A thin `AppLogger` facade (tagged, leveled) wraps the logging package so log
calls are uniform and the backend (console, crash reporter) is swappable in one
place.

---

## 15. The Design System

UI consistency is enforced by a first-class design system in
`core/design_system/`, organized into two tiers plus a barrel export:

```
core/design_system/
├── foundation/          # TOKENS + atomic widgets
│   ├── app_colors.dart        #   color scheme (light/dark)
│   ├── app_text_styles.dart   #   the type scale
│   ├── app_dimensions.dart    #   spacing / radius scale
│   ├── buttons/  containers/  inputs/  graphics/  indicators/
├── composite/           # higher-order, multi-part components
│   ├── app_scaffold.dart  app_bar.dart  bottom_sheet.dart  dialog.dart …
└── index.dart           # barrel: one import for the common catalog
```

Principles:

- **Tokens, not literals.** Colors, text styles, and spacing are defined once as
  named constants and referenced everywhere. No raw `Color(0xFF…)` or magic
  paddings in feature code.
- **A consistent component prefix.** Every reusable widget shares a short prefix
  (here, `Xx…`) so the catalog is discoverable via autocomplete and instantly
  distinguishable from framework widgets.
- **Foundation → Composite layering.** Atomic widgets (a button, an avatar) live
  in `foundation/`; multi-part assemblies (a scaffold with standard app bar +
  back gesture, a standard dialog) live in `composite/` and are built *from*
  foundation pieces.
- **A barrel export** (`index.dart`) gives features a single import for the
  common widgets, reducing import noise.
- **Tokens feed the theme.** The design-system type/color tokens are mapped onto
  Material's `ThemeData` in the root widget, so even default widgets inherit the
  system.

The payoff: a feature screen is assembled almost entirely from design-system
components, so visual changes are made once, centrally, and propagate everywhere.

---

## 16. Navigation & Routing

### 16.1 Decentralized route tables, centrally aggregated

Each feature owns its routes in a `<feature>_pages.dart` file that declares both
the **route-name constants** and the **route table** (page + binding +
middlewares):

```dart
class ItemPages {
  ItemPages._();
  static const _prefix = '/item';
  static const list   = '$_prefix/list';
  static const detail = '$_prefix/detail';

  static final routes = [
    GetPage(name: list,   page: () => const ItemListPage(),  binding: ItemBindings()),
    GetPage(name: detail, page: () => const ItemDetailPage()),
  ];
}
```

The app router simply **aggregates** every feature's routes — it is the one
place that imports all features, and it stays a flat, readable list:

```dart
class AppRouter {
  AppRouter._();
  static const initial = '/splash';

  static final routes = <GetPage>[
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/home',   page: () => const HomeShell(),
            binding: HomeBinding(), middlewares: [AuthMiddleware()]),
    ...ItemPages.routes,
    ...ProfilePages.routes,
    // ...every other feature...
  ];
}
```

Attaching a feature's `binding` to its `GetPage` is what ties DI to navigation:
visiting the route builds the slice's object graph; leaving it tears the graph
down.

### 16.2 Route guards via middleware

Cross-cutting redirect rules are middlewares, kept out of the screens:

```dart
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = Get.find<AuthService>();
    if (session.isLoggedIn && !session.isTokenExpired()) return null;  // allow
    return const RouteSettings(name: '/onboarding');                   // redirect
  }
}
```

A complementary "onboarding" middleware does the reverse (bounces an
already-logged-in user away from the login flow). Guarding is declarative and
attached at the route, never re-implemented per screen.

### 16.3 An injectable navigator abstraction

Rather than scattering static navigation calls, the app wraps navigation in an
`AppNavigator` whose operations are **injectable function fields** with default
implementations. This buys two things:

- **Testability** — tests inject fakes and assert navigations without a widget
  tree.
- **Tab-scoped nested navigation** — the navigator resolves the *current tab's*
  nested navigator id, so "go to detail" pushes within the active tab's stack,
  enabling independent per-tab back stacks in a bottom-nav shell.

---

## 17. Adding a New Feature: A Step-by-Step Recipe

Putting it all together, here is the mechanical process to add a feature called,
say, `catalog`:

1. **Scaffold the folders:**
   ```
   features/catalog/{data/{repositories,mappers},domain/{entities,repositories,usecases},presentation/{bindings,controllers,views,widgets,constants}}
   ```
2. **Domain first.** Define `entities/catalog_entities.dart` (plain objects),
   then `repositories/catalog_repository.dart` (abstract contract in entity
   terms), then `usecases/catalog_usecases.dart` (one callable per operation).
3. **Data layer.** Write `mappers/catalog_mapper.dart` (DTO ⇆ entity) and
   `repositories/catalog_repository_impl.dart` (implements the domain contract
   using the generated API + mapper). Add gateways if you touch device APIs.
4. **Presentation state & controllers.** Create `controllers/catalog_shared_state.dart`
   (extends `SharedState`, implements `reset()`) and one or more controllers
   extending `BaseController`, composing the use cases.
5. **Views & widgets.** Build screens in `views/` from design-system components;
   put feature-private widgets in `widgets/`, wrapping only reactive subtrees in
   observers.
6. **Wire DI.** In `bindings/catalog_bindings.dart`, `lazyPut(fenix: true)` the
   state → repository → use cases → controllers, in dependency order.
7. **Register routes.** Create `catalog_pages.dart` with route constants and a
   `routes` list (attaching the binding and any middlewares), then add
   `...CatalogPages.routes` to `AppRouter.routes`.
8. **Touch nothing else.** No edits to `core/`, no edits to other features. If
   you find yourself needing to modify `core/`, ask whether you actually need a
   new *port* rather than a new concrete dependency.

If the feature has no backend or device interaction, collapse it to
`presentation/` only — don't create empty layers.

---

## 18. Testing Architecture

A blueprint without a testing contract is a sketch. Every architectural seam
introduced above exists partly *to be tested in isolation* — so the test suite
mirrors the architecture.

### 18.1 Mirror the feature layout under `test/`

```text
test/
├── core/                              # base controller, retry/timeout, error mapping, ports
├── features/<feature>/
│   ├── domain/                        # entities (getters/business rules), use cases
│   ├── data/                          # repositories (fake API), mappers, gateways
│   └── presentation/                  # controllers (fake use cases), shared state reset
integration_test/                      # full-journey, on-device/emulator tests
```

### 18.2 What every layer must prove before merge

| Layer | Mandatory unit tests |
|-------|----------------------|
| **Domain entities** | Computed getters and business-rule methods (`isEditable`, `isComplete`, …). |
| **Use cases** | Correct delegation/orchestration; multi-dependency composition paths. |
| **Mappers** | DTO → entity field mapping **and** the exhaustive enum switch (every value, plus the "unknown value throws" path). |
| **Repositories** | Against a **fake/mocked generated API**: success, empty, and error mapping. |
| **Network decorators** | `RetryClient` (retry-on-5xx, no-retry on non-idempotent except 503, backoff), `TimeoutClient` (deadline → typed exception). |
| **Error layer** | `safeExecute` routes to `onError` vs. funnel; status-code → message mapping. |
| **Route guards** | Each middleware's allow/redirect decision for logged-in / expired / anonymous. |
| **Shared state** | `reset()` actually clears every field (this is what protects logout). |

### 18.3 Controller tests with the DI container

For GetX-style controllers, document the test harness once so every feature
copies it:

```dart
setUp(() {
  Get.testMode = true;                 // no real navigation / overlays
  Get.put<FetchItemsUseCase>(FakeFetchItemsUseCase());
  Get.put(ItemSharedState());
});
tearDown(() => Get.reset());           // wipe the container between tests

test('load() populates items and toggles its own loading tag', () async {
  final c = ItemController(Get.find(), Get.find());
  final future = c.load();
  expect(c.isLoading('load'), isTrue);
  await future;
  expect(c.isLoading('load'), isFalse);
  expect(c.items, isNotEmpty);
});
```

### 18.4 Widget tests: the state matrix, not just the happy path

Every design-system component and feature widget should be verified across the
states that actually break in production:

- **Content states:** loading, empty, error, loaded.
- **Localization & direction:** each supported locale; LTR **and** RTL.
- **Theming:** light and dark.
- **Accessibility:** large text scale factor (e.g. 1.3–2.0) without overflow.
- **Guards:** widgets behind a route middleware render only when permitted.

### 18.5 Integration tests for high-value journeys

Reserve `integration_test/` for the flows whose breakage is most costly: cold
start, session restore from cache, login/logout, token expiry → forced logout,
route-guard redirects, deep links, offline → retry recovery, and your two or
three critical forms. Tag a **smoke** subset (the few must-not-break journeys)
so CI can run it per-PR and defer the full suite to nightly — see the tiering
table in [§19.1](#191-per-pr-gates-must-pass-to-merge).

> **The pyramid:** follow Flutter's guidance — *many* fast unit tests, a healthy
> band of widget tests, and *enough* integration tests to cover important
> journeys (they are slow, so be selective).
> See [Flutter testing overview](https://docs.flutter.dev/testing/overview).

---

## 19. CI/CD Pipeline & Release Gates

The structure only stays intact if a machine enforces it on every PR. Define a
pipeline with **hard gates** (block merge) and **release steps**.

### 19.1 Per-PR gates (must pass to merge)

```bash
dart format --output=none --set-exit-if-changed .   # formatting is not negotiable
flutter analyze                                       # static analysis (incl. custom lints)
flutter test --coverage                               # unit + widget, with coverage
flutter test integration_test                         # SMOKE journeys only on PRs (see note)
flutter build appbundle --release                     # Android compiles for release
flutter build ios --release --no-codesign             # iOS compiles for release
flutter build web --wasm                              # web/Wasm compiles (see §21)
```

> **Tier the integration suite — don't run the full device matrix on every PR.**
> Integration tests are slow and need real runners, so split them by cadence and
> name the target explicitly:
>
> | Cadence | Scope | Where it runs |
> |---------|-------|---------------|
> | **Per PR** | A small **smoke** set (cold start, login/logout, one critical form) | One fast emulator/simulator per platform (e.g. a pinned Android API level + one iOS sim), or a single cloud-device-farm lane. |
> | **Nightly / pre-release** | The **full** journey suite across the supported device matrix (min + current OS, a low-end device, tablet, web) | Device farm / matrixed CI. |
>
> Block merges on the per-PR smoke set; let the nightly matrix gate releases.

Plus the checks a build alone won't catch:

- **Codegen drift check** — regenerate the API client and `dart format`, then
  `git diff --exit-code`. A non-zero exit means someone hand-edited generated
  code or forgot to regenerate after a contract change.
- **Dependency audit** — `flutter pub outdated` / advisory scan; fail on known
  vulnerable transitive deps.
- **Coverage threshold** — fail if total (or per-package) coverage drops below
  the agreed floor; never let it ratchet down silently.
- **Binary-size diff** — `--analyze-size`, store the JSON, diff against `main`,
  fail PRs that blow the budget (see §21).

### 19.2 Release steps (post-merge / tagged)

- Build with **obfuscation + split debug info** (see §20) and **upload the debug
  symbols** to your crash reporter so production stack traces deobfuscate.
- Generate release notes from the merged PRs/commits.
- Ship via **staged rollout** (e.g. 5% → 20% → 100%) with a documented
  **rollback policy** and a halt criterion tied to the crash-free-sessions
  metric.

See [Flutter continuous delivery](https://docs.flutter.dev/deployment/cd).

---

## 20. Security Hardening Checklist

Security must be a mandatory checklist, not incidental mentions. Treat each item
as a release gate.

**Build & code protection**

- [ ] Release builds use `flutter build … --obfuscate --split-debug-info=<secure-dir>`;
      symbols are archived per release for crash deobfuscation.
      ([obfuscation docs](https://docs.flutter.dev/deployment/obfuscate))
- [ ] Android release uses R8/code shrinking with reviewed **keep rules**; test
      reflection/plugin paths for shrink-induced breakage.
      ([Android deployment](https://docs.flutter.dev/deployment/android))

**Secrets & storage**

- [ ] **No real secrets in the binary at all.** A client app ships to untrusted
      devices and can be decompiled, so anything compiled in — including
      `--dart-define` values — is effectively public. Only *public* config
      (base URLs, public keys, feature flags) goes through build-time env;
      genuine secrets (API signing keys, private credentials) stay **server-side**
      behind your backend. Never place secrets in assets, generated clients, or
      source.
- [ ] Tokens use **platform secure storage** (Keychain/Keystore) on mobile.
- [ ] On **web**, browser storage is *not* equivalent to Keychain/Keystore —
      prefer **secure, `HttpOnly`, `SameSite` cookies** for auth material where
      the backend allows it; never put long-lived tokens in `localStorage`.

**Logging & PII**

- [ ] Logs **redact by default**: tokens, emails, phone numbers, precise
      location, and request/response bodies are never logged in the clear.

**Transport**

- [ ] HTTPS-only; **cleartext traffic denied** at the platform level
      (Android `usesCleartextTraffic=false`, iOS ATS enforced).
- [ ] Certificate/SPKI **pin rotation** procedure documented:
      - **Bundle backup pins ahead of time.** Ship the *next* key's pin inside
        the app *before* rotating, so a key change doesn't brick installed apps.
        You cannot rely on fetching a new pin after the fact — if validation
        fails, the app may be unable to reach the very backend that would serve
        the update.
      - **Define failure behavior:** fail closed, with a clear user message.
      - **Any remote pin override must arrive over an independently trusted
        path** (a separately pinned/hosted config endpoint or signed payload),
        *not* the same pinned connection it is meant to repair — otherwise a pin
        mismatch locks out its own fix.

---

## 21. Performance, Web/Wasm & Footprint Budgets

Rendering and size are not automatic — they are budgeted and verified.

### 21.1 Impeller & render performance

Impeller precompiles a smaller shader set and removes most runtime shader-compile
jank, and is the default renderer on modern Flutter (iOS, and Android API 29+ as
of Flutter 3.27). It is **not** a substitute for profiling. Require **profile-mode**
verification on real low-end target devices for the usual offenders:

- blur / backdrop filters, `Opacity` and `saveLayer`, large image decode,
  platform views, and unbounded list/animation work.

Track frame budget (UI build + raster under the device's frame interval) and
investigate jank with the DevTools timeline.
See [Impeller docs](https://docs.flutter.dev/perf/impeller).

### 21.2 Web & WebAssembly (Wasm) correctness

`dart.library.js_interop` in §13 is the modern, Wasm-compatible seam. Make the
constraints explicit so the web build doesn't silently fall back or fail to
compile to Wasm:

- **Wasm-compatible web code must avoid** `dart:html`, `dart:js`, `dart:js_util`,
  and the legacy `package:js`. Use **`package:web` + `dart:js_interop`** instead.
- Add a CI gate: `flutter build web --wasm`. The build still emits a JS fallback
  bundle for browsers without Wasm, so don't assume a single output.
- **Wasm threading needs cross-origin isolation** — host with the
  `Cross-Origin-Opener-Policy: same-origin` and
  `Cross-Origin-Embedder-Policy: require-corp` (or `credentialless`) headers.
- Branch on the compile target at runtime when needed with
  `const bool.fromEnvironment('dart.tool.dart2wasm')`.

See [Flutter Wasm support](https://docs.flutter.dev/platform-integration/web/wasm).

### 21.3 Footprint budgets

- Build release artifacts with `--analyze-size`; it emits a
  `*-code-size-analysis_*.json` you can open in DevTools.
- Store that JSON as a CI artifact, **diff it against `main`**, and fail PRs that
  exceed agreed thresholds for Dart code, assets, fonts, native libraries, or
  deferred bundles.
- Budget deferred/feature bundles separately so a heavy feature can't bloat the
  initial download.

See [measuring app size](https://docs.flutter.dev/perf/app-size).

---

## 22. Architectural Enforcement

The guide should make the right path **mechanical**, not a matter of memory or
taste. Encode the rules from §1–§21 into tooling and process.

### 22.1 Enforce layer boundaries with lint, not goodwill

The dependency rules are only real if a linter rejects violations. Configure
forbidden-import / layering rules (e.g. via `dart_code_linter`'s
`avoid-banned-imports`, `custom_lint`, or an import-boundary linter) to fail CI
when:

- anything in `core/` imports from `features/` or from `generated/`;
- anything in `domain/` imports Flutter, `http`, the state-management package, or
  generated code;
- a DTO type from `generated/` is referenced outside a `data/` layer;
- a `presentation/` file imports another feature's `presentation/` internals.

Also enforce metric thresholds (cyclomatic complexity, file length, number of
parameters) so controllers and widgets can't quietly balloon.

### 22.2 Make the golden path copy-pasteable

- **Feature template** — a scaffolded `features/_template/` (or a code generator)
  containing the empty `data/domain/presentation` skeleton, a binding, a pages
  file, and a sample controller. Adding a feature starts from the template, not
  from a blank folder.
- **Test template** — matching `test/` skeleton so the test layout is never
  improvised.

### 22.3 Definition of Done (per feature / PR)

A feature is "done" only when:

- [ ] Domain/data/presentation respect the dependency rule (lint-enforced).
- [ ] Use cases, mappers, repository (fake API), and `reset()` are unit-tested.
- [ ] Key widget states (loading/empty/error, dark, RTL, large text) are tested.
- [ ] New external boundaries are interfaces with injected implementations.
- [ ] No raw `try/catch` in presentation; all async goes through `runSafe`.
- [ ] Routes registered with binding + guards; no other feature was modified.
- [ ] No new secrets, no unredacted PII logging, size diff within budget.

### 22.4 A PR checklist that references this guide

Keep a short `PULL_REQUEST_TEMPLATE.md` that asks the author to confirm the
Definition of Done above and to flag any change to `core/` or a shared port —
those deserve extra scrutiny because their blast radius is the whole app.

---

## 23. Architectural Rules (The Short List)

Pin these to the wall. They are the invariants that keep the structure intact as
the team and codebase grow:

1. **Dependencies point inward.** `presentation → domain ← data`. Domain imports
   nothing but Dart + domain.
2. **`core/` never imports `features/` or generated code.** When it needs an
   outer capability, it defines a **port**.
3. **DTOs never leave the data layer.** Mappers convert to entities at the
   boundary; the domain and presentation see only entities.
4. **Every external boundary is an interface.** Repositories, gateways, ports,
   session, navigator — all abstract, all injected.
5. **Controllers compose use cases; they don't do I/O.** No `http`, no DTOs, no
   raw `try/catch` in presentation — use the base controller's `runSafe`.
6. **One feature = one folder = one route table = one binding.** Adding a
   feature should not require editing another feature.
7. **DI lifetime is deliberate:** `permanent` for app-lifetime services/ports,
   `lazyPut(fenix: true)` for feature objects.
8. **Wrap the smallest reactive subtree**, not the whole screen.
9. **Tokens over literals** for color, type, and spacing; build screens from the
   design system.
10. **Scale ceremony to complexity.** The full three-layer structure is for
    features with real logic; trivial screens may be a single file. Consistency
    where it counts, pragmatism where it doesn't.
11. **The error funnel is three hooks, not one.** `FlutterError.onError` +
    `PlatformDispatcher.instance.onError` + `runZonedGuarded`, with crash
    capture initialized *first*.
12. **Resolve dependencies inside binding closures**, never eagerly at the top
    of a binding.
13. **Every seam has a test.** Mappers (incl. unknown-enum), repositories (fake
    API), decorators, guards, and `reset()` are non-negotiable units.
14. **Security and size are release gates**, not afterthoughts: obfuscate +
    upload symbols, redact PII, deny cleartext, rotate pins safely, diff the
    size budget.
15. **Boundaries are lint-enforced.** If a human has to remember the dependency
    rule, it will eventually be broken — make CI reject the violation.

---

### Appendix: Reference Technology Mapping

The blueprint above is stack-agnostic in principle. The reference codebase
realizes it with these choices — substitute your own freely:

| Concern                | Reference choice                          | Common alternatives                     |
|------------------------|-------------------------------------------|-----------------------------------------|
| State + DI + routing   | GetX (`GetxController`, `Bindings`, `GetPage`) | Riverpod, BLoC + get_it + go_router     |
| Reactivity             | `.obs` / `Obx` + id-targeted `update()`   | `StateNotifier`, `Cubit`, `ChangeNotifier` |
| API client             | OpenAPI-generated client + registry       | Retrofit/dio, hand-written client       |
| HTTP composition       | `http` + decorator clients (retry/timeout/pinning) | dio interceptors                  |
| Local storage          | secure storage + shared-preferences wrappers | hive, isar, drift                    |
| Crash reporting        | zoned-guard + hosted error monitoring     | any APM/crash SDK                       |
| Cross-platform select  | Dart conditional imports                  | (same — it's the idiomatic Dart way)    |

The patterns — layered features, ports, repositories/gateways, mappers, use
cases, a base controller, decorator networking, conditional imports, a tokenized
design system — are what make the app scalable. The packages are just how this
particular codebase spells them.
