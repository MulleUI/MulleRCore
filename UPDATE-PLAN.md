# UPDATE-PLAN — Changes from MulleSDL/MulleGLFW to apply to MulleRCore

MulleRCore is the raylib rcore backend for MulleUI. It shares a common OS window/event
abstraction layer with MulleSDL and MulleGLFW. This document tracks changes made in the
sibling projects (commits up to 2026-07-21) that need consideration or application here.

RCore's unique characteristics: single-window (rcore CORE singleton), single-threaded
(all on main thread), poll-diff input model (no per-event callbacks, synthesize events
from `PollInputEvents()` state deltas).

---

## Category A — Project Infrastructure

- [ ] **A1.** `cola/` directory with `properties.plist`, `description.md.bud`, `mulle-sde.md.bud`, `wilted/you-are-here.md.bud`
  Both siblings have this. Most recent commit to MulleSDL (2026-07-21) was just this.
  Declares project metadata: domain=github, user=MulleUI, repo=MulleRCore, language=c,
  dialect=objc, deps=MulleUIApplication (and raylib).

- [ ] **A2.** `.mulle/share/sde/extension`: add styleguide extension entries
  ```
  mulle-sde/mulle-c-styleguide;extra
  mulle-c/styleguide;extra
  ```

- [ ] **A3.** `.mulle/share/sde/version/mulle-c/styleguide` (value: `0.1.0`)
  `.mulle/share/sde/version/mulle-sde/mulle-c-styleguide` (value: `0.29.2`)
  Version pin files present in both siblings, missing in RCore.

- [ ] **A4.** `.mulle/share/howto/` rich .md documentation (~13 files)
  Subdirs `coder/`, `debugger/`, `orchestrator/`, `verifier/` exist but are empty in RCore.
  Siblings have: build-system/index.md, c-styleguide.md, crosscompiling.md,
  dependencies/{advanced,examples,index,troubleshooting}.md, file-organization.md,
  mulle-c-syntax.md, debug-crashes.md, debug-hangs.md, multi-project.md, navigation.md,
  testing/{coverage,index,quirks}.md

- [ ] **A5.** `asset/` directory: `asset/dox/TOC.md` + `asset/howto/coder/`, `debugger/`, `verifier/`
  with project-specific howto guides. Both siblings have this.

- [ ] **A6.** `dox/` directory. Both siblings have this.

- [ ] **A7.** `test/` directory with basic test suite.
  MulleSDL: `test/15-sdl/{share.m,noshare.m}`
  MulleGLFW: `test/15-glfw/{share.m,noshare.m,activate.m}`
  RCore has no tests.

- [x] **A8.** RELEASENOTES.md + `environment-host-ci-prerelease.sh`
  Already present in RCore.

---

## Category B — CMake Infrastructure

- [ ] **B1.** `CMakeLists.txt`: add `MULLE_SDE_REFLECT_DIR` support
  ```cmake
  set( MULLE_SDE_REFLECT_DIR "reflect")
  if( MULLE_SOURCETREE_CONFIG_NAME)
     set( MULLE_SDE_REFLECT_DIR "reflect.${MULLE_SOURCETREE_CONFIG_NAME}")
  endif()
  list( INSERT CMAKE_MODULE_PATH 0 "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${MULLE_SDE_REFLECT_DIR}")
  ```
  Even though raylib abstracts the backend (no multi-backend needed yet), this is
  forward-compatible infrastructure.

- [ ] **B2.** `cmake/share/Files.cmake`: use `${MULLE_SDE_REFLECT_DIR}` instead of hardcoded
  `cmake/reflect/` for `_Dependencies.cmake` and `_Libraries.cmake` in INSTALL_CMAKE_INCLUDES.

- [ ] **B3.** `cmake/share/CreateDepsIncObjC.cmake`: use `${MULLE_SDE_REFLECT_DIR}` instead of
  hardcoded `src/reflect/` for OBJC_DEPS_INC path.

- [ ] **B4.** `cmake/share/Headers.cmake`: add multi-reflect header filtering
  `_mulle_filter_reflect_entries()` function. For single-backend this is a no-op
  but harmless infrastructure to include for consistency.

---

## Category C — Source: Thread-Safety Annotations

- [ ] **C1.** `shareID` — add `MULLE_OBJC_THREADSAFE_METHOD`     (RCoreOSWindow.h:124)
- [ ] **C2.** `shouldClose` — add `MULLE_OBJC_THREADSAFE_METHOD`  (RCoreOSWindow.h:125)
- [ ] **C3.** `os_window` — add `MULLE_OBJC_THREADSAFE_METHOD`    (RCoreOSWindow.h:128)
- [ ] **C4.** `os_setSwapInterval:` — add `MULLE_OBJC_THREADSAFE_METHOD` (RCoreOSWindow.h:136)
- [ ] **C5.** `os_swapBuffers` — add `MULLE_OBJC_THREADSAFE_METHOD` (RCoreOSWindow.h:144)
- [ ] **C6.** `os_requestClose` — add `MULLE_OBJC_THREADSAFE_METHOD` (RCoreOSWindow.h:146)
- [ ] **C7.** `os_windowShouldClose` — add `MULLE_OBJC_THREADSAFE_METHOD` (RCoreOSWindow.h:147)
- [ ] **C8.** `activeThread` — add `MULLE_OBJC_THREADSAFE_METHOD` (RCoreOSWindow.h:168)

---

## Category D — Source: Event Creation Pattern

- [ ] **D1.** Split alloc/init/autorelease into separate statements
  Both siblings refactored from:
  ```objc
  event = [[[FooEvent alloc] initWithX:y] autorelease];
  ```
  to:
  ```objc
  event = [FooEvent alloc];
  event = [event initWithX:y];
  event = [event autorelease];
  ```
  RCore's `RCoreOSWindow+UIEvent.m:207` and `:219` still use the one-liner.

---

## Category E — Source: Input State / Modifier Handling

- [ ] **E1.** Ctrl+left click → right click emulation
  Both siblings added `UIEventMouseButtonWithModifiers( button, &modifiers)` in mouse
  button handling. This is a platform convention (macOS), not event-model specific.
  RCore's `synthesizeEventsFromInputState` in `RCoreOSWindow+UIEvent.m` should add this.

- [ ] **E2.** Modifier-aware button states
  Both siblings call `UIEventButtonStatesWithModifiers()` on button states.
  Should apply to RCore for the same reason as E1.

---

## Category F — Source: Logging / Diagnostics

- [ ] **F1.** `fprintf(stderr, ...)` → `mulleui_log(...)` for error messages
  SDL changed error logging to use the project logging framework. RCore uses
  `mulle_fprintf( stderr, ...)` throughout. Should switch to `mulleui_log()`.

---

## Category G — Source: Protocol Stubs

- [ ] **G1.** `applicationDidChangeWindowCount:`, `firstResponder`, `handleWindowEvent:`,
  `receiveRetainedEvent:` protocol stubs
  SDL added no-op stubs to `SDLOSWindow.m`. Check if RCore needs these for
  `<UIWindow>` / `<UIEventReceiver>` protocol conformance.

---

## Category H — README.md

- [ ] **H1.** Restructure README.md to match new sibling format
  - Title duplication (`# MulleRCore` + tagline repeated)
  - Badges table: `Release Version | Release Notes | AI Documentation`
  - `## Add` section with mulle-sde command
  - `## Install` section
  - Memo boxes for project-specific notes

---

## Category I — Graphics Hints (minor)

- [ ] **I1.** Consider adding `RCoreGraphicsHintsNone` (`.api = 1`) and `RCoreGraphicsHintsGL3`
  (`.api = 3, .major = 3, .minor = 0`) if needed for parity with siblings.
  Currently RCore has: Default, GL3_3, GLES2, GLES3.

---

## Category J — N/A (Architecture-Specific)

These sibling changes do NOT apply to RCore due to architectural differences:

| Change | Why N/A |
|--------|---------|
| `UIWindowMoveEvent` / `UIWindowResizeEvent` specific types | RCore has no per-event callbacks (poll-diff model) |
| `SDL_SetHint( SDL_HINT_NO_SIGNAL_HANDLERS, "1")` | SDL-specific, RCore uses raylib |
| `SDL_GetDisplays` / `SDL_GetDisplayBounds` return value fix | SDL-specific API |
| `SDLGraphicsHintsGetProfile` improvements | SDL-specific hints |
| `GLFWGraphicsHintsApplyDriverEnv` multi-backend driver selection | GLFW-specific |
| `os_pressedKeys:` in category header (style choice) | Already declared in main interface |

---

## Category K — Already Done

| Change | Status |
|--------|--------|
| Graphics hints new naming convention (`RCoreGraphicsHintsDefault` etc.) | Done |
| `UIOSWindowEventLog` replacing `#define CALLBACK_DEBUG` / `MulleUILog` | Done |
| RELEASENOTES.md + `environment-host-ci-prerelease.sh` | Done |
| `#pragma clang diagnostic ignored "-Wprotocol"` on `@implementation RCoreOSWindow` | Done |
| `#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"` on category | Done |

---

## Priority Summary

| Priority | Items | Effort | Notes |
|----------|-------|--------|-------|
| **High** | A1-A3 (cola/, sde extensions, version pins) | Medium | Project metadata, `mulle-sde` needs these |
| **High** | B1-B3 (cmake MULLE_SDE_REFLECT_DIR) | Medium | Forward-compatible infrastructure |
| **High** | C1-C8 (thread-safety annotations) | Low | Consistency with siblings |
| **Medium** | A4-A7 (howto, asset, dox, test) | Medium-High | Documentation and testing |
| **Medium** | D1, E1-E2 (event patterns, modifiers) | Low | Code style and platform conventions |
| **Medium** | H1 (README.md restructuring) | Low | Presentation consistency |
| **Medium** | F1, G1 (logging, protocol stubs) | Low | Diagnostics and protocol conformance |
| **Low** | B4 (Headers.cmake filtering) | Low | No-op for single backend, but consistent |
| **Low** | I1 (missing graphics hints) | Trivial | API parity with siblings |

---

## Applied Changes (2026-07-21)

| Category | Change | File |
|----------|--------|------|
| **A+B** | `mulle-sde upgrade` — cmake `MULLE_SDE_REFLECT_DIR` support, styleguide extensions, howto docs, version pins, Headers.cmake filtering | `.mulle/share/`, `cmake/share/` |
| **C** | 8 `MULLE_OBJC_THREADSAFE_METHOD` annotations (`shareID`, `shouldClose`, `os_window`, `os_setSwapInterval:`, `os_swapBuffers`, `os_requestClose`, `os_windowShouldClose`, `activeThread`) | `src/RCoreOSWindow.h` |
| **D** | Split alloc/init/autorelease into 3 separate statements + specific event types (`UIWindowFramebufferResizeEvent *`, `UIWindowCloseEvent *`) | `src/RCoreOSWindow+UIEvent.m` |
| **E** | Ctrl+left click → right click emulation via `UIEventButtonStatesWithModifiers` + `UIEventMouseButtonWithModifiers` | `src/RCoreOSWindow+UIEvent.m` |
| **F** | `mulle_fprintf(stderr, ...)` → `mulleui_log(...)` (4 sites) | `src/RCoreOSWindow.m` |
| **G** | Protocol stubs: `applicationDidChangeWindowCount:`, `firstResponder`, `handleWindowEvent:`, `receiveRetainedEvent:` | `src/RCoreOSWindow.m` |
| **fixup** | `UIMouseButtonEvent` init missing `clickCount:` parameter | `src/RCoreOSWindow+UIEvent.m` |

Build: clean, zero warnings.
