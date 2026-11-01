# Project Guidelines

## 1. Project Overview

Velo Cambo is a Flutter bike-sharing application. Its implemented flows include a station map, station and slot selection, bike booking, subscription activation, and a user profile showing subscription and booking details. The root navigation has Pass, Map, and Profile tabs; Map is initially selected.

These guidelines describe the inspected implementation. Recommendations for future changes are identified separately from existing behavior. No `AI_CODING_RULES.md` or applicable `AGENTS.md` was found during inspection. The root `README.md` still contains the Flutter starter text.

## 2. Technology Stack

| Technology | Project usage and evidence |
| --- | --- |
| Dart / Flutter | Application code in `lib/`; Material widgets and Material 3 theme. `pubspec.yaml` declares Dart `^3.11.4`. |
| Provider `^6.1.5+1` | Dependency injection, `ChangeNotifierProvider`, and `context.read`/`context.watch`. |
| HTTP `^1.6.0` | Firebase Realtime Database REST requests in concrete repositories. No Firebase SDK dependency is declared. |
| Google Maps Flutter `^2.17.0` | Station maps, markers, and map controller. |
| intl `^0.18.0` | Date rendering through `DateTimeUtils`. |
| geolocator `^14.0.2` | Declared dependency; no use in the inspected Dart source. |
| cupertino_icons `^1.0.8` | Declared icon package; current screens primarily use Material icons. |
| flutter_test / flutter_lints `^6.0.0` | Test tooling is available; `analysis_options.yaml` includes the standard Flutter lint set with no active custom rules. |

Versions above are manifest constraints, not claims about the newest package releases. `pubspec.lock` records dependency resolution and currently requires Dart `>=3.12.0 <4.0.0` and Flutter `>=3.44.0`, which is stricter than the manifest's Dart lower bound.

Flutter/Pub manages Dart packages. Android uses Gradle Kotlin DSL, Kotlin, and Java 17 compatibility (`android/app/build.gradle.kts`); plugin versions are in `android/settings.gradle.kts`. iOS uses Xcode/Swift runner files and CocoaPods, with iOS 14.0 specified in `ios/Podfile`. Platform scaffolding also exists for web, macOS, Linux, and Windows; its presence does not establish that every feature works on every platform.

## 3. Architecture and Layer Responsibilities

The implementation is **MVVM-style UI over a layered domain/data structure**, with repositories and small aggregation services. This is supported by the screen constructors, ViewModel calls, and repository implementations, rather than folder names alone.

The usual flow is:

```text
Screen creates ViewModel with Provider dependencies
  -> Content watches ViewModel and invokes actions
  -> ViewModel calls a domain service, repository, or UserState
  -> Service combines repository results when necessary
  -> Firebase repository calls HTTP and DTO converters
  -> Domain models return to ViewModel
  -> AsyncValue assignment + notifyListeners rebuild Content
```

- **UI:** `lib/ui/screens/` contains feature screens, ViewModels, and content widgets. Screens normally wire dependencies; content widgets render state and invoke actions. ViewModels manage loading, selection, submission, and feature orchestration.
- **Domain models:** `lib/domain/models/` holds data objects and derived rules, such as booking expiry and subscription end dates. Models do not perform networking or import UI code.
- **Domain services:** `lib/domain/services/` combines repository reads into `StationDetail` or `UserDetail` aggregates.
- **Data:** `lib/data/repositories/` contains both abstract repository contracts and concrete HTTP/mock implementations. `lib/data/dtos/` translates JSON and domain objects.
- **Composition:** `lib/main_dev.dart` selects implementations; `lib/main_common.dart` wraps the application in `MultiProvider` and configures theme/navigation.

Dependency direction is pragmatic: UI imports domain objects and data-layer repository contracts; domain services also import contracts from `data/repositories/`; concrete repositories and DTOs import domain models. This is not strict Clean Architecture with all abstractions in the domain layer. ViewModels also accept `BuildContext`, navigate, and sometimes show snackbars. Preserve these established boundaries during ordinary feature work instead of reorganizing the architecture.

## 4. Folder Structure and File Placement

```text
lib/
  main_dev.dart               # Executable entry point and implementation wiring
  main_common.dart            # Shared app startup, theme, bottom navigation
  domain/
    models/
      bikes/ booking/ slots/ stations/ subscriptions/ users/
    services/                 # Repository aggregation services
  data/
    dtos/                     # Static JSON conversion helpers
    repositories/
      bikes/ booking/ stations/ subscriptions/ users/
    example/
      mock_data/mock_data.dart # In-memory domain fixtures
      sample/data.json        # Example database-shaped JSON
  ui/
    screens/
      booking_bike/ booking_bike_success/ profile/ station/
      stations_map/ subscription/ subscription_detail/
    states/user_state.dart    # Shared current-user ChangeNotifier
    theme/theme.dart          # Theme and visual constants
    utils/                    # AsyncValue and date formatting
    widgets/                  # Widgets shared across features
test/                         # Currently empty
```

For a typical feature, follow `lib/ui/screens/station/`: place the entry widget in `<feature>_screen.dart`, its notifier in `view_model/`, and its rendering widgets in `widgets/`. These are the existing singular `view_model` directory names. The booking success screen is a smaller StatefulWidget without its own ViewModel or content directory; do not add layers solely for symmetry.

Place model additions beside related models, JSON conversion in `data/dtos/`, and repository methods/implementations in the corresponding entity directory. Existing `booking/` is singular while several other entity directories are plural. Preserve actual names. Promote widgets to `ui/widgets/` when shared; keep feature-specific cards and chips local. Do not place authored source in `build/`, `.dart_tool/`, or generated platform files.

## 5. Naming Conventions and Coding Style

- Files and directories use `snake_case`; classes and enums use `UpperCamelCase`; members, methods, parameters, enum values, and constants use `lowerCamelCase`.
- Common suffixes are `Screen`, `Content`, `ViewModel`, `Repository`, `FirebaseRepository`, `RepositoryMock`, `Dto`, and `Service`. Examples include `StationViewModel`, `StationFirebaseRepository`, and `StationRepositoryMock`.
- File and class names are not always identical: `booking_view_model.dart` defines `BookingBikeViewModel`; `subscription_detail_content.dart` defines `PassDetailContent`. Inspect symbols before assuming names.
- Use two-space Dart indentation, braces, named `required` constructor arguments, `@override`, trailing commas in multiline constructs, and `const` constructors/widgets where supported. Existing files have some uneven whitespace; format touched Dart files with the Dart formatter without formatting unrelated files.
- Models and injected dependencies generally use `final`; mutable notifier state is updated through methods. Private members use `_`, such as `_cachedStations`, `_isSubmitting`, and `_init`.
- DTO key constants are `static const String`, for example `BookingDto.bookingTimeKey`. Theme values use `static const`, while `veloTheme` is a top-level `final ThemeData`.
- Most files use single-quoted strings, with some double-quoted exceptions. Imports mix relative paths and `package:velo_project/...`; the package name is `velo_project`, despite the repository directory name. Follow nearby code; for new files, group Dart SDK imports, package imports, and project imports, separated by blank lines. Import grouping is not uniformly enforced today.
- Comments are sparse and usually explain a step or intent. `theme.dart` demonstrates `///` documentation for shared concepts. Use comments for non-obvious decisions rather than narrating straightforward assignments.

## 6. Component and Module Responsibilities

| Component | Existing responsibilities and guidance |
| --- | --- |
| Domain entities | Fields, constructors, selected `copyWith` methods, derived getters. `Station.availableBikes`, `Booking.expiryTime`, and `Subscription.endDate` are representative. Keep JSON and HTTP elsewhere. |
| Detail aggregates | `StationDetail` combines a station and bikes; `UserDetail` combines user, optional subscription, and optional booking. |
| DTO helpers | Static `fromJson`/`toJson` methods returning domain objects or maps; they are not separate instantiated transport models. Handle payload shape and primitive conversions here. |
| Repository contracts | Asynchronous entity reads and mutations returning domain models. Keep HTTP details in concrete implementations. |
| Firebase repositories | URI construction, HTTP status checks, JSON conversion, and in-memory cache maintenance. No separate API client or data-source layer exists. |
| Mock repositories | Implement the same interfaces using fixtures; they are alternate data implementations, not an automated test suite. |
| Detail services | Combine reads across repositories. `StationDetailService` fetches station and bikes, then filters by `bike.stationId`; `UserDetailService` follows nullable user references. |
| ViewModels | Extend `ChangeNotifier`, expose UI state/getters, perform actions, and coordinate dependencies. Existing booking and subscription flows also navigate from ViewModels. |
| UserState | Loads the fixed current user, exposes user/reference-presence getters, persists subscription/booking reference changes, and notifies listeners. It is not an authentication service. |
| Screens and widgets | Screens construct scoped notifiers; content watches them. Widgets own presentation details. Local map controller/marker state and success-screen timers live in StatefulWidgets. |

Reuse `SubscriptionStatusBadge` in `lib/ui/widgets/subscription_status_badge.dart`, `DateTimeUtils` in `lib/ui/utils/date_format.dart`, and the `VeloColors`, `VeloTextStyles`, `VeloSpacings`, and `VeloSize` constants in `lib/ui/theme/theme.dart`. Many current widgets override colors and dimensions directly; theme reuse is a recommendation for additions, not a claim of existing uniform adoption.

## 7. State Management and Data Flow

`devProviders` registers repositories by abstract type, then registers shared `UserState` and detail services. Services obtain dependencies with `context.read<T>()`. Screens create their own `ChangeNotifierProvider`, passing dependencies through constructors; content normally subscribes with `context.watch<FeatureViewModel>()`.

The shared state is `UserState`, initialized asynchronously for user ID `u1`. Most ViewModels that depend on it attach a listener and remove that listener in `dispose`. `ProfileViewModel` listens for user/reference changes and guards overlapping fetches. Preserve listener cleanup for new notifiers.

`lib/ui/utils/async_value.dart` defines this project's own `AsyncValue<T>`, with only `loading`, `success`, and `error` states. It is not Riverpod. Fetching ViewModels assign a loading state, perform an awaited operation, assign success/error, and call `notifyListeners`. Content switches on `AsyncValueState`; loading shows a spinner and errors typically show text. Empty collections are successful results: map content explicitly renders `No stations available`. Add empty presentation where the feature needs it; there is no distinct empty-state enum.

Submission handling varies: booking uses `_isSubmitting` and `canConfirm`; subscription detail uses `AsyncValue<void>` initialized with `AsyncValue.success(null)`. Follow the adjacent feature rather than introducing a competing state library. The root tab index, map markers/controller, and success-screen timer use local StatefulWidget state.

Important mutation flows:

1. **Subscription:** create a timestamp-ID subscription, persist it, update the user's subscription reference through `UserState`, notify, show a snackbar, and pop the detail route.
2. **Booking:** validate `canConfirm`, create a timestamp-ID booking, persist it, clear the station slot's bike reference, and update the user's current booking reference. Replace the booking route with `BookingSuccessScreen`; that screen pops with `true`, allowing `StationViewModel.openBooking` to clear selection and force-refresh station detail.
3. **Expired booking:** during profile detail loading, return the bike to a synthesized `slot_<number>` ID, clear the user's booking reference, and force-fetch user detail. There is no background expiry worker or periodic expiry timer.

## 8. API, Database, and Data Access Patterns

Concrete `*_firebase_repository.dart` files use `package:http/http.dart` as `http` and `dart:convert` against a hardcoded Firebase Realtime Database host. Collections are `/stations.json`, `/bikes.json`, `/users.json`, `/subscriptions.json`, and `/bookings.json`; individual records append `/<id>.json`. There is no project backend server, local SQL database, authentication integration, or realtime stream subscription in the inspected implementation.

- `fetch<EntityPlural>()` performs a collection request and fills a nullable list cache. `get<EntityPlural>({bool forceFetch = false})` uses that cache unless forced. Despite its name, `fetch<Entity>ById` also consults cache unless forced.
- Collection JSON is keyed by record ID. Most DTOs accept a `fallbackId` for records without an ID field. `StationDto` and `SlotDto` instead receive their IDs as positional parameters.
- Most null collection payloads become empty lists; missing individual records throw. Booking collection parsing also treats a non-map payload as empty; other implementations do not uniformly do so.
- Dates use `DateTime.parse` and `toIso8601String`; subscription types serialize via enum `.name`. DTOs normalize numeric values with `num.toInt()`/`toDouble()` where appropriate.
- Slots are nested under stations by slot ID, storing `slotNumber` and nullable `bikeId`. `SlotDto` also accepts a legacy nested `bike` object as a fallback.
- Booking/subscription creation uses `PUT` to the selected record ID. User reference changes and station slot changes use `PUT` to individual fields. Bike updates use `PATCH` for rating and location references.
- Existing HTTP code considers status `200` successful and throws generic exceptions otherwise. JSON headers are included in some writes but not all. There is no common timeout, retry, or HTTP-client abstraction.
- Most entity writes replace/add entries only if a collection cache already exists. User by-ID fetching initializes its cache even when no full collection has been loaded; do not assume that this cache contains all users. Station slot writes invalidate `_cachedStations` entirely. Cache refreshes do not broadcast changes to already-loaded ViewModels.

For new data operations, extend the existing repository interface and both implementations, keep serialization in the DTO, preserve backend field names, and explicitly choose the cache update/invalidation behavior. Pass `forceFetch` through services when exposing refresh behavior.

## 9. Dependency Management and Configuration

Use the existing Provider composition in `lib/main_dev.dart`; avoid creating concrete repositories inside UI widgets or ViewModels. The same `UserRepository` instance is supplied to both its Provider and `UserState`. Despite its development name, the current entry point uses HTTP Firebase repositories, not mocks. There is no `lib/main.dart` or production entry point.

Run the application with an explicit target:

```sh
flutter run -t lib/main_dev.dart
```

Review `pubspec.yaml` and `pubspec.lock` before adding a dependency. Reuse Provider, HTTP, intl, and existing widgets for needs they already cover. Add a package only when required functionality is missing and account for platform setup and lockfile changes. There is no code generation dependency, custom asset declaration, custom font declaration, or established `.env`/`--dart-define` configuration layer.

Database host strings are repeated in repositories. Google Maps setup is platform-specific: `ios/Runner/AppDelegate.swift` calls Maps initialization, `ios/Runner/Info.plist` contains a location-use description, and `web/index.html` loads the Maps script. Do not copy configured credential values into documentation, logs, or new code. Use the project's existing platform configuration locations when investigating setup; there is no established central secrets mechanism to assume.

## 10. Error Handling and Validation

Repositories throw `Exception` for failed requests and missing records. DTOs throw `ArgumentError` for missing IDs and invalid subscription types; casts/date parsing can also throw. ViewModels generally catch errors into `AsyncValue.error`; the map ViewModel stores `e.toString()` while others retain the error object. Existing content commonly prints the error in red text, without a standardized error mapper or retry component.

Booking checks for a subscription reference, no current booking reference, user agreement, a resolved bike, and no ongoing submission. It checks required user/bike/slot/station objects again before writing. Subscription detail rejects an unloaded user or an existing subscription reference. UserState guards duplicate references but silently returns if the user has not loaded.

Use those guards as the local integration pattern, and define new operation-specific validation explicitly. Do not interpret `UserState.hasSubscription` as proof of an unexpired subscription: it only checks reference presence. `Subscription.isActive` and `UserDetail.hasActiveSubscription` perform time-based checks.

After awaiting work, existing navigation paths use `context.mounted` before interacting with the UI. Preserve this protection for new asynchronous actions. `UserState._init()` currently has no catch/error state; `clearCurrentBooking()` catches and logs errors instead of propagating them. These are limitations to account for, rather than a consistent error-handling policy.

## 11. Testing and Code Quality

`test/` currently contains no Dart tests, there is no `integration_test/` directory, and no `.github/` CI configuration was found. `flutter_test` is declared, so future behavioral tests can use Flutter's built-in test tooling. No coverage target or established test fixture isolation scheme exists.

For future source changes, use the installed compatible Flutter SDK and existing dependencies:

```sh
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib/
flutter test --no-pub
```

The format command checks without writing; target touched files when existing formatting would obscure results. Run the test command once relevant tests exist; the current empty directory provides no automated behavioral coverage. These commands describe available checks, not a verified passing baseline. For this documentation-only task, application tests and builds were not run.

Useful future test boundaries are DTO round trips and fallback IDs, repository cache behavior, nullable `copyWith` clearing, ViewModel loading/error transitions, and booking/subscription guards. Use isolated repository fakes or reset fixtures: several mock repositories directly reference mutable global lists. Avoid tests that write to the configured remote database. Manual verification for affected flows should use the explicit development target and cover map-to-station navigation, selection, booking success/refresh, subscription activation, and profile refresh as relevant.

## 12. Existing Implementation Examples

| Task | Representative files |
| --- | --- |
| Register shared dependencies | `lib/main_dev.dart`, `lib/main_common.dart` |
| Wire a feature notifier and render async state | `lib/ui/screens/station/station_screen.dart`, `lib/ui/screens/station/view_model/station_view_model.dart`, `lib/ui/screens/station/widgets/station_content.dart` |
| Combine related reads | `lib/domain/services/station_detail_service.dart`, `lib/domain/services/user_detail_service.dart` |
| Implement REST, DTO conversion, and cache invalidation | `lib/data/repositories/stations/station_firebase_repository.dart`, `lib/data/dtos/station_dto.dart`, `lib/data/dtos/slot_dto.dart` |
| Coordinate a guarded mutation and navigation | `lib/ui/screens/booking_bike/view_model/booking_view_model.dart`, `lib/ui/screens/booking_bike_success/booking_success_screen.dart` |
| Follow shared user state and refresh details | `lib/ui/states/user_state.dart`, `lib/ui/screens/profile/view_model/profile_view_model.dart` |
| Show inline submission progress/errors | `lib/ui/screens/subscription_detail/view_model/subscription_detail_view_model.dart`, `lib/ui/screens/subscription_detail/widgets/subscription_detail_content.dart` |
| Manage platform widget resources | `lib/ui/screens/stations_map/widgets/station_map_content.dart`, `lib/ui/screens/stations_map/widgets/station_marker.dart` |

## 13. Rules for Implementing New Features

1. Read the nearest complete feature before editing: screen, ViewModel, content, service, repository interface/implementations, DTO, and model. Use the station feature for detail loading and subscription detail for submissions.
2. Keep file placement and dependency injection consistent with sections 3–6. Add providers to the existing composition root when needed; inject contracts through constructors.
3. Keep network/JSON operations in repositories/DTOs, aggregation in domain services, derived entity rules in models, and UI state/action coordination in ViewModels. Use local widget state for resources such as timers/controllers, following existing cleanup patterns.
4. Use the existing custom `AsyncValue` and ChangeNotifier lifecycle. Cover loading, successful data, empty collections when relevant, and errors. Register/remove shared-state listeners and dispose widget resources.
5. When changing a repository contract, update its Firebase and mock implementations together. Check cache behavior, service `forceFetch` forwarding, DTO schema, and affected callers.
6. Use explicit clear flags when clearing nullable model fields. For example, `user.copyWith(clearCurrentBookingId: true)` clears a reference; passing `currentBookingId: null` alone preserves it. Confirm each model's actual `copyWith` signature.
7. Reuse shared badges, date formatting, and theme constants; preserve nearby naming and import conventions. Avoid introducing a new routing, state, serialization, or dependency-injection system for a single feature.
8. Preserve navigation results used for refresh. In particular, the booking success pop result is consumed by `StationViewModel.openBooking`.
9. Inspect all records touched by a mutation and define failure/cache behavior. Existing booking and subscription sequences are multiple requests, so they do not provide transactional guarantees to build upon.
10. Keep changes within the requested scope. Preserve user edits and existing behavior; document a relevant inconsistency instead of silently refactoring unrelated code or changing business rules.
11. Validate touched behavior with available analysis, formatting checks, targeted tests where meaningful, and manual flows as needed. Report pre-existing failures separately from regressions. Do not claim a passing test suite when none exists.

## 14. Known Inconsistencies and Unclear Areas

- **Mock clearing differs from HTTP behavior:** `StationRepositoryMock.removeBikeFromSlot` passes `bikeId: null`, but `Slot.copyWith` requires `clearBikeId: true` to clear the value. `BikeRepositoryMock.removeBikeFromSlot` similarly passes nullable location arguments instead of clear flags. The HTTP bike repository uses the clear flags correctly. `Slot.copyWith` also has unused `bike`/`clearBike` arguments.
- **Related records can disagree:** booking clears the station slot and updates the user but does not call `BikeRepository.removeBikeFromSlot`; bike location references can remain attached. Station counts use slot occupancy, while `StationDetailService` filters bikes by `stationId`, and station detail only offers slots with a resolvable bike. Confirm which representation a new feature needs.
- **Mutations are not atomic:** booking and subscription creation can partially succeed across requests. There is no rollback, server transaction, concurrency reservation check, or idempotency strategy. `UserState.updateSubscription`/`updateBooking` changes its local user before awaiting persistence, without rollback on failure.
- **Presence and validity differ:** subscription/booking presence getters do not inspect expiry; profile detail does. Expired subscription references are not automatically cleared. Monthly UI copy describes 30 days, but `Subscription.endDate` constructs the next month's date and subtracts a day, dropping the original time of day; do not silently replace this rule.
- **Expiry cleanup depends on profile loading:** booking expiry is derived from the clock and handled when profile details load. Cleanup assumes slot IDs follow `slot_<slotNumber>` and `clearCurrentBooking` suppresses persistence errors, which may interfere with its subsequent recursive refresh. The success screen's pickup deadline text is static rather than a live countdown.
- **Caches and UI refresh are uneven:** list caches have no TTL or broadcast stream. User by-ID fetches can create a partial list cache; map data has no explicit refresh method. Station refresh after booking does not automatically refresh an already-held map list.
- **Async lifecycle protection is incomplete:** initial UserState loading has no exposed error state; several notifiers can finish asynchronous work after disposal. Existing `mounted` checks protect some UI calls, not all notifier completion paths.
- **Platform setup is uneven:** Android's main manifest lacks internet/location permissions and a Maps API-key metadata entry; debug/profile manifests declare internet permission. Map content enables location display, but the inspected Dart source has no geolocator permission-request flow. iOS/web Maps setup does not establish support for every scaffolded target.
- **Prototype UI/configuration remains:** current user is hardcoded to `u1`; payment card content is static with no payment-processing integration. Prices are duplicated in subscription widgets. Theme tokens coexist with hardcoded styles, imports/whitespace vary, and Android release uses debug signing with the default example application ID.
- **Tooling baseline needs confirmation:** SDK constraints differ between manifest and lockfile, automated tests/CI are absent, and the README does not explain the nonstandard entry point. No analyzer/build/test pass is asserted by this document.

Treat these as observed constraints or areas requiring a product/technical decision when relevant to a task. They are not authorization to rewrite the architecture or repair unrelated behavior.
