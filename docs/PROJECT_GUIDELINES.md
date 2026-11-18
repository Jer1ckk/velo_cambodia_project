# Project Guidelines

## 1. Project Overview

Velo Cambo is a Flutter bike-sharing application. Its implemented flows include a station map, station and slot selection, bike booking, subscription activation, and a user profile showing subscription and booking details. The root navigation has Pass, Map, and Profile tabs; Map is initially selected.

These guidelines describe the inspected implementation. Recommendations for future changes are identified separately from existing behavior. Repository working rules are in [AGENTS.md](../AGENTS.md); design requirements are in [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md). The root `README.md` still contains the Flutter starter text.

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

- **UI:** `lib/ui/screens/` contains feature screens, ViewModels, and content widgets. Screens normally wire dependencies; content widgets render state and invoke actions. ViewModels manage loading, selection, filtering/search, eligibility, submission, and feature navigation. Map controllers, bitmap markers, text controllers, modal presentation, and responsive layout remain widget responsibilities.
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
test/                         # Map discovery behavior and widget tests
```

For a typical feature, follow `lib/ui/screens/station/`: place the entry widget in `<feature>_screen.dart`, its notifier in `view_model/`, and its rendering widgets in `widgets/`. These are the existing singular `view_model` directory names. The booking success screen follows the same Provider-based MVVM structure: `BookingSuccessScreen` creates `BookingSuccessViewModel`, and `BookingSuccessContent` renders its booking details and invokes its navigation action.

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
| DTO helpers | Static `fromJson`/`toJson` methods returning domain objects or maps; they are not separate instantiated tran`sport models. Handle payload shape and primitive conversions here. |
| Repository contracts | Asynchronous entity reads and mutations returning domain models. Keep HTTP details in concrete implementations. |
| Firebase repositories | URI construction, HTTP status checks, JSON conversion, and in-memory cache maintenance. No separate API client or data-source layer exists. |
| Mock repositories | Implement the same interfaces using fixtures; they are alternate data implementations, not an automated test suite. |
| Detail services | Combine reads across repositories. `StationDetailService` fetches station and bikes, then filters by `bike.stationId`; `UserDetailService` follows nullable user references. |
| ViewModels | Extend `ChangeNotifier`, expose UI state/getters, perform actions, and coordinate dependencies. Map, booking, and subscription feature navigation is handled here; modal list selection returns its result through `StationListViewModel`. |
| UserState | Loads the fixed current user, coordinates expiry checks/timers, serializes checks with reference mutations, exposes user/reference-presence getters and expiry errors, and notifies listeners after successful persistence. It is not an authentication service. |
| Screens and widgets | Screens construct scoped notifiers; content watches them. Widgets own presentation details. Local map controller/marker state lives in StatefulWidgets. |

Reuse `SubscriptionStatusBadge` in `lib/ui/widgets/subscription_status_badge.dart`, `DateTimeUtils` in `lib/ui/utils/date_format.dart`, and the `VeloColors`, `VeloTextStyles`, `VeloSpacings`, and `VeloSize` constants in `lib/ui/theme/theme.dart`. Many current widgets override colors and dimensions directly; theme reuse is a recommendation for additions, not a claim of existing uniform adoption.

## 7. State Management and Data Flow

`devProviders` registers repositories by abstract type, then `UserExpiryService`, shared `UserState`, and detail services. Services obtain dependencies with `context.read<T>()`. Screens create their own `ChangeNotifierProvider`, passing dependencies through constructors; content normally subscribes with `context.watch<FeatureViewModel>()`.

The shared state is `UserState`, initialized asynchronously for user ID `u1`. Most ViewModels that depend on it attach a listener and remove that listener in `dispose`. `ProfileViewModel` listens for user/reference changes, guards overlapping fetches and completion after disposal, and exposes force-fetch refresh/retry. Preserve listener cleanup for new notifiers.

`lib/ui/utils/async_value.dart` defines this project's own `AsyncValue<T>`, with only `loading`, `success`, and `error` states. It is not Riverpod. Fetching ViewModels assign a loading state, perform an awaited operation, assign success/error, and call `notifyListeners`. Content switches on `AsyncValueState`; loading shows a spinner and errors typically show text. Empty collections are successful results: map content explicitly renders `No stations available`. Add empty presentation where the feature needs it; there is no distinct empty-state enum.

Submission handling varies: booking uses `_isSubmitting` and `canConfirm`; subscription detail uses `AsyncValue<void>` initialized with `AsyncValue.success(null)` and guards repeated submissions. Follow the adjacent feature rather than introducing a competing state library. The root tab index and map markers/controller use local StatefulWidget state.

Important mutation flows:

1. **Subscription:** validate fresh account/pass status, create a timestamp-ID subscription, persist it, update the user's subscription reference through `UserState`, notify, and show a persistent activation confirmation with the actual pass dates. “Back to passes” explicitly pops the detail route; no success snackbar or automatic dismissal is used. Failures show a dedicated result view with stage-specific headings, diagnostic messages, retry/finish actions, and a return-to-review action. Retry progress stays in the result view and disables repeat actions. Error messages distinguish account checking, pass saving, and account linking. Within the same detail screen, retries reuse the pending ID/start time; a successful save is not repeated when only linking failed. If a fresh read confirms that pending pass is already linked, “Finish activation” completes without another write. Pending activation state is not persisted across closing the screen or restarting the app.
2. **Booking:** station detail disables “Continue to booking” and shows an explanation while a current booking reference remains. `StationViewModel.canOpenBooking` and `openBooking` enforce this guard before navigation; expiry cleanup/reference changes update the action automatically. A selected, resolvable slot and loaded user are required. On the review screen, validate `canConfirm`, create a timestamp-ID booking, persist it, clear the station slot's bike reference, and update the user's current booking reference. Replace the booking route with `BookingSuccessScreen`; that screen shows the saved booking’s local pickup deadline and waits for explicit continuation. Its continuation and Back actions pop with `true`, allowing `StationViewModel.openBooking` to clear selection and force-refresh station detail.
3. **Expiry reconciliation:** `UserExpiryService.check` force-fetches the current user and linked pass/booking. `Booking.isExpiredAt` and `Subscription.isExpiredAt` treat the deadline itself as expired. Expired passes clear `/users/<id>/subscriptionId`; expired bookings find the station slot by its actual slot number, return the bike using the stored slot ID, then clear `/users/<id>/currentBookingId`. An occupied slot containing another bike or a missing slot fails without clearing the booking. Booking/pass records are retained as history. Existing repository REST methods perform these writes. Pass and booking cleanup run independently; `UserExpiryResult` retains successful changes and a `UserExpiryException` identifying pass and booking failures. UserState publishes successful changes before surfacing/retrying the remaining error. Pass activation uses `checkSubscriptionExpiry`: a booking-only failure continues retrying in the background without blocking a verified pass activation; account-read and pass-check failures still block it.
4. **Expiry scheduling:** `UserState.ready` includes the initial check. `MyApp` forwards lifecycle resume/pause events to UserState. One timer targets the earliest active deadline; reference changes recheck and reschedule. Failed background checks retry after 30 seconds while active and expose `expiryError`; explicit checks propagate errors. Booking/pass confirmation awaits a fresh check before creating records. Checks and local reference mutations are serialized, and overlapping checks share a pending request. Reference mutations update local state only after persistence succeeds. Timers/listeners are disposed with their owners.
5. **Screen refresh after expiry:** booking reference changes increment `UserState.bookingRevision`, causing station/map ViewModels to force-refresh availability. Map/profile refreshes queue another read if reconciliation finishes during a pending request; station requests use their existing request-version guard. Profile only renders the result and no longer performs expiry writes.

## 8. API, Database, and Data Access Patterns

Concrete `*_firebase_repository.dart` files use `package:http/http.dart` as `http` and `dart:convert` against a hardcoded Firebase Realtime Database host. Collections are `/stations.json`, `/bikes.json`, `/users.json`, `/subscriptions.json`, and `/bookings.json`; individual records append `/<id>.json`. There is no project backend server, local SQL database, authentication integration, or realtime stream subscription in the inspected implementation.

- `fetch<EntityPlural>()` performs a collection request and fills a nullable list cache. `get<EntityPlural>({bool forceFetch = false})` uses that cache unless forced. Despite its name, `fetch<Entity>ById` also consults cache unless forced.
- Collection JSON is keyed by record ID. Most DTOs accept a `fallbackId` for records without an ID field. `StationDto` and `SlotDto` instead receive their IDs as positional parameters.
- Most null collection payloads become empty lists; missing individual records throw. Booking collection parsing also treats a non-map payload as empty; other implementations do not uniformly do so.
- Dates use `DateTime.parse` and `toIso8601String`; subscription types serialize via enum `.name`. DTOs normalize numeric values with `num.toInt()`/`toDouble()` where appropriate.
- Slots are nested under stations by slot ID, storing `slotNumber` and nullable `bikeId`. `SlotDto` also accepts a legacy nested `bike` object as a fallback.
- Booking/subscription creation uses `PUT` to the selected record ID. User reference changes and station slot changes use `PUT` to individual fields. Bike updates use `PATCH` for rating and location references.
- Existing HTTP code considers status `200` successful and throws generic exceptions otherwise. JSON headers are included in some writes but not all. There is no common timeout, retry, or HTTP-client abstraction. Subscription creation sends an explicit JSON content type, uses a 20-second timeout, and throws `SubscriptionSaveException` with a response status or a connection/timeout failure type; its ViewModel displays the corresponding diagnostic rather than treating every failed save as a connection error.
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

Repositories throw `Exception` for failed requests and missing records. DTOs throw `ArgumentError` for missing IDs and invalid subscription types; casts/date parsing can also throw. ViewModels generally catch errors into `AsyncValue.error`; the map, station, and booking ViewModels retain error objects and expose forced read refresh/retry. Booking write failures preserve the review details and agreement, disable the confirmation action, and direct users to check their profile instead of automatically retrying a potentially partial write. Map, station, booking, and profile content widgets show product-facing loading and error messages; profile, map, and station also provide empty states. Subscription detail uses product-facing activation feedback. There is no shared error mapper or retry component.

Booking checks for a subscription reference, no current booking reference, user agreement, a resolved bike, no ongoing submission, and no retained confirmation error. These guards are enforced by the ViewModel as well as reflected in the controls. It checks required user/bike/slot/station objects again before writing. Pass selection stays disabled while the user loads or a subscription reference is linked. `SubscriptionViewModel` fetches the linked subscription through its injected repository and marks only the verified, unexpired pass type as active. Its card uses a green surface/border, a checkmark, and an “Active pass” label; other linked-state cards remain neutral without unavailable labels. Loading/failure states do not guess the active option and support read retry. Reference changes invalidate outstanding reads, and disposal prevents late notifications. Subscription detail rejects an unloaded user or an existing subscription reference. UserState awaits initialization and rejects duplicate references or an unloaded user. Booking/pass confirmation checks expiry again before creating a record.

Use those guards as the local integration pattern, and define new operation-specific validation explicitly. Do not interpret `UserState.hasSubscription` as proof of an unexpired subscription: it only checks reference presence. `Subscription.isActive` and `UserDetail.hasActiveSubscription` perform time-based checks.

After awaiting work, existing navigation paths use `context.mounted` before interacting with the UI. Preserve this protection for new asynchronous actions. `UserState` retains initialization/expiry errors in `expiryError`, retries background checks, and propagates explicit check/mutation failures. `clearCurrentBooking()` delegates to the same persistence-first reference update path.

## 11. Testing and Code Quality

`test/ui/screens/stations_map/` contains Flutter tests for station loading/retry, disposal during an outstanding request, repeated marker selection, station-list selection, and summary layout at phone viewport sizes with normal and enlarged text. `test/ui/screens/station/` covers selectable versus empty/unavailable slots, loading/retry, overlapping requests, disposal, booking navigation and success refresh, and phone layouts at normal and enlarged text. `test/ui/screens/booking_bike/` covers review layouts, pass/booking/bike guards, agreement, read retry, duplicate submission prevention, success navigation and writes, retained details after write failure, and disposal during loading. `test/ui/screens/subscription/` checks pass comparison layouts at phone and wider sizes with enlarged text, account loading, linked-pass restrictions, active-pass styling for each type, expired-pass exclusion, read retry, stale/disposed read handling, accessible actions, and selection navigation. `test/ui/screens/subscription_detail/` checks all pass detail layouts at phone and wider sizes with enlarged text, loading/linked account states, duplicate activation prevention, retained details after failure, disposal during activation, and linking the created pass. `activation_feedback_test.dart` checks success/save-failure/link-failure layouts at phone and wider sizes with enlarged text, persistent success/explicit continuation, reviewing without discarding a saved pass, and progress during retry. `test/ui/screens/booking_bike_success/` checks responsive layouts, explicit continuation, and Back results. `test/ui/screens/profile/` checks active, expired, and empty profile layouts at phone and wider sizes with enlarged text, loading/retry/refresh, disposal during loading, profile image fallback, and refresh during expiry reconciliation. `test/domain/services/user_expiry_service_test.dart` exercises real Firebase repositories through mocked HTTP, checking expiry boundaries, request paths, retained history, occupied/missing slots, failed writes, and retry behavior. `test/ui/states/user_expiry_state_test.dart` covers startup/resume/deadline scheduling, pause/disposal, retry, coalescing, and reference-write serialization. `test/data/repositories/subscriptions/subscription_save_test.dart` covers the JSON save payload/cache update, retained HTTP error status, connection failures, and timeout behavior with mocked HTTP. Tests use isolated repository/service fakes and do not call the remote database. There is no `integration_test/` directory or `.github/` CI configuration. No coverage target exists; native map rendering and assistive technology still require device verification.

For future source changes, use the installed compatible Flutter SDK and existing dependencies:

```sh
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib/
flutter test --no-pub
```

The format command checks without writing; target touched files when existing formatting would obscure results. Run the test command for the available tests; passing these checks does not establish coverage for other features or native platform integrations. These commands describe available checks, not a permanent passing baseline. For documentation-only changes, check local links, referenced paths, and consistency with source; application tests and builds are only needed if executable behavior is affected.

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

## 13. Integration Checks for New Features

Use the general implementation workflow in [AGENTS.md](../AGENTS.md). The following checks address contracts specific to this project; sections 3–10 describe their implementation.

1. When changing a repository contract, update its Firebase and mock implementations together. Check cache behavior, service `forceFetch` forwarding, DTO schema, and affected callers.
2. Use explicit clear flags when clearing nullable model fields. For example, `user.copyWith(clearCurrentBookingId: true)` clears a reference; passing `currentBookingId: null` alone preserves it. Confirm each model's actual `copyWith` signature.
3. Preserve navigation results used for refresh unless the requested behavior replaces that contract. In particular, the booking success pop result is consumed by `StationViewModel.openBooking`.
4. Inspect all records touched by a mutation and define failure/cache behavior. Existing booking and subscription sequences are multiple requests, so they do not provide transactional guarantees to build upon.

## 14. Known Inconsistencies and Unclear Areas

- **Mock clearing differs from HTTP behavior:** `StationRepositoryMock.removeBikeFromSlot` passes `bikeId: null`, but `Slot.copyWith` requires `clearBikeId: true` to clear the value. `BikeRepositoryMock.removeBikeFromSlot` similarly passes nullable location arguments instead of clear flags. The HTTP bike repository uses the clear flags correctly. `Slot.copyWith` also has unused `bike`/`clearBike` arguments.
- **Related records can disagree:** booking clears the station slot and updates the user but does not call `BikeRepository.removeBikeFromSlot`; bike location references can remain attached. Station counts use slot occupancy, while `StationDetailService` filters bikes by `stationId`, and station detail only offers slots with a resolvable bike. Confirm which representation a new feature needs.
- **Mutations are not atomic across Firebase paths:** booking, subscription creation, and expiry cleanup can partially succeed across requests. There is no server transaction or cross-device reservation guard. UserState serializes operations within this app and changes local references only after successful persistence. Expiry retries skip a slot already holding the same bike and retain a booking reference when cleanup fails; this is not a multi-device transaction guarantee.
- **Presence and validity differ:** subscription/booking presence getters do not inspect expiry; profile detail does. The shared expiry service clears expired references after fresh reads; presence getters still describe references rather than independently fetching validity. Monthly expiry is calendar-based: `Subscription.endDate` constructs the next month's date and subtracts a day, dropping the original time of day; do not silently replace this rule.
- **Expiry checks are app-side:** startup, resume, a foreground deadline timer, and pre-confirmation checks drive reconciliation using the device clock. There is no deployed server scheduler or authoritative server-side expiry enforcement; cleanup waits until the app runs again after it is closed. A backend worker/transaction would be needed for closed-app cleanup and cross-device guarantees. The success screen displays the saved booking’s expiry time as a local date and time; it does not run a live countdown.
- **Caches and UI refresh are uneven:** list caches have no TTL or broadcast stream. User by-ID fetches can create a partial list cache. The map now supports explicit refresh/retry and force-fetches when returning from station detail; it still has no live update subscription while held open.
- **Lifecycle boundaries:** UserState timers and completion notifications are guarded after disposal. Already-started repository writes may still finish after a screen is closed; no HTTP cancellation layer exists.
- **Platform setup is uneven:** Android's main manifest lacks internet/location permissions and a Maps API-key metadata entry; debug/profile manifests declare internet permission. Map content enables location display, but the inspected Dart source has no geolocator permission-request flow. iOS/web Maps setup does not establish support for every scaffolded target.
- **Prototype UI/configuration remains:** current user is hardcoded to `u1`; subscription details explicitly explains that activation collects no payment; no payment-processing integration exists. Pass option titles, prices, totals, and features are shared through `SubscriptionOption`, exposed by the subscription ViewModels. Theme tokens coexist with hardcoded styles, imports/whitespace vary, and Android release uses debug signing with the default example application ID.
- **Tooling baseline needs confirmation:** SDK constraints differ between manifest and lockfile, automated coverage includes map discovery, station detail, booking review/success, pass selection/activation, and profile states; CI is absent, and the README does not explain the nonstandard entry point. No analyzer/build/test pass is asserted by this document.

Treat these as observed constraints or areas requiring a product/technical decision when relevant to a task. They are not authorization to rewrite the architecture or repair unrelated behavior.
