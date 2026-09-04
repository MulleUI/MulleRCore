# MulleRCore Library Documentation for AI
<!-- Keywords: raylib, rcore, window, input, opengl, gamepad, screen -->

## 1. Introduction & Purpose

MulleRCore is the raylib (rcore) backend for the MulleUI framework. It wraps
raylib's `rcore` platform layer into the MulleUIApplication `UIOSWindow`,
`UIScreen`, and `UIGamepad` protocols, enabling raylib to be used as a
rendering backend for MulleUI-based applications.

Key features:
- Single-window GL rendering via raylib's InitWindow/CloseWindow
- Poll-diff input model: reads raylib input state once per frame, diffs
  against previous frame, synthesizes `UIEvent` objects for delivery
- Monitor/screen enumeration via raylib's GetMonitor* API
- Gamepad support via raylib's IsGamepadAvailable/GetGamepad* API
- Fixed-framerate only (rcore has no event-driven wait, only polling and
  WaitTime-based sleep)

## 2. Key Concepts & Design Philosophy

### Single-Window Constraint

Raylib's rcore uses a global singleton (`CoreData CORE`) — only one window
can exist at a time. `RCoreOSWindow` enforces this at init time with a CAS
singleton check and rejects retained window styles.

### Poll-Diff Input Model

Rcore has no per-event callbacks. Instead, MulleRCore uses a poll-diff model:
1. `PollInputEvents()` reads current rcore input state
2. `synthesizeEventsFromInputState` diffs current vs. previous frame
3. Generates `UIMouseMotionEvent`, `UIMouseButtonEvent`, `UIMouseScrollEvent`,
   `UIKeyboardEvent`, `UIWindowFramebufferResizeEvent`, `UIWindowCloseEvent`
4. Delivers events via `windowEventsCallback` (window events) and
   `otherRetainedEventsCallback` (all other retained events)

### Frame-Based Rendering Loop

No `WaitEventsTimeout` equivalent exists. The main loop runs at a fixed
framerate using `WaitTime(timeout)` + `PollInputEvents()`. The `displayFrameIfNeeded:`
method manages frame pacing with `BeginDrawing`/`EndDrawing`/`SwapScreenBuffer`.

### Protocol Conformance

`RCoreOSWindow` conforms to `<UIWindow, UIOSWindow>`, `RCoreOSScreen` to
`<UIScreen>`, and `RCoreOSGamepad` to `<UIGamepad>`. These are the bridge
interfaces that MulleUIApplication uses to abstract over platform backends.

## 3. Core API & Data Structures

### 3.1. `RCoreOSWindow.h`

#### `RCoreOSWindow : NSObject <UIWindow, UIOSWindow>`

The main window class. Wraps raylib window creation, rendering, input
polling, and event synthesis.

**Graphics Hints Macros:**
```c
#define RCoreGraphicsHintsDefault   ((RCoreGraphicsHints){ 0 })
#define RCoreGraphicsHintsGL3_3     ((RCoreGraphicsHints){ .api = 3, .major = 3, .minor = 3 })
#define RCoreGraphicsHintsGLES2     ((RCoreGraphicsHints){ .api = 2, .major = 2, .minor = 0 })
#define RCoreGraphicsHintsGLES3     ((RCoreGraphicsHints){ .api = 2, .major = 3, .minor = 0 })
```

`RCoreGraphicsHints` is `typedef UIOSWindowGraphicsHints RCoreGraphicsHints`.

**Callback Types:**
```c
typedef void (*RCoreOSWindowEventCallback_t)( RCoreOSWindow *window, UIWindowEvent *event);
typedef void (*RCoreOSWindowRetainedEventCallback_t)( RCoreOSWindow *window, UIEvent *retainedEvent);
```

**Default Callback Functions:**
```c
void RCoreOSWindowEventDefaultCallback( RCoreOSWindow *window, UIWindowEvent *event);
void RCoreOSWindowRetainedEventDefaultCallback( RCoreOSWindow *window, UIEvent *retainedEvent);
```

`RCoreOSWindowEventDefaultCallback` forwards `UIWindowEvent` to the `windowEventsReceiver`.
`RCoreOSWindowRetainedEventDefaultCallback` forwards retained `UIEvent` to the `eventsReceiver`,
releasing the event if no receiver is set.

**Factory / Init Methods:**
```objc
+ (instancetype) windowWithFrame:(CGRect) frame
                 titleUTF8String:(char *) title
                       styleMask:(NSUInteger) styleMask;

+ (instancetype) windowWithFrame:(CGRect) frame
                 titleUTF8String:(char *) title
                       styleMask:(NSUInteger) styleMask
                   graphicsHints:(RCoreGraphicsHints) graphicsHints;

- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask;

- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
                 graphicsHints:(RCoreGraphicsHints) graphicsHints;

- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
                 graphicsHints:(RCoreGraphicsHints) graphicsHints
                 sharingWindow:(id <UIOSWindow>) sharingWindow;
```

Factory methods use `alloc/init/autorelease`. Init methods cascade to the
most specific designated initializer. `sharingWindow` is not supported
(rcore is single-window) — passing non-nil causes a no-op and nil return
(the handler prints an error and releases self).

**Style Mask Flags** (read/write on the `styleMask` property):
- `RCoreOSWindowStyleMaskDefault` (0) — bare window
- `UIWindowStyleResizable` — maps to `FLAG_WINDOW_RESIZABLE`
- `UIWindowStyleBare` — maps to `FLAG_WINDOW_UNDECORATED`
- `UIWindowStyleTransparent` — maps to `FLAG_WINDOW_TRANSPARENT`
- `UIWindowStyleHidden` — maps to `FLAG_WINDOW_HIDDEN`
- `UIWindowStyleAntiAlias` — maps to `FLAG_MSAA_4X_HINT`

**Properties:**
```objc
@property( assign) id <UIEventReceiver>   windowEventsReceiver;
@property( assign) id <UIEventReceiver>   eventsReceiver;
@property( assign) RCoreOSWindowEventCallback_t         windowEventsCallback;
@property( assign) RCoreOSWindowRetainedEventCallback_t otherRetainedEventsCallback;
@property( assign, readonly) UIGraphicsBackend   backend;
@property( assign) UIOSWindowFrameCallback_t     frameCallback;
@property( dynamic, assign) NSUInteger           discardEventsMask   MULLE_OBJC_THREADSAFE_PROPERTY;
@property( assign) CGFloat                       scrollWheelSensitivity;
@property( assign, readonly) NSUInteger          styleMask;
@property( assign, dynamic) mulle_relativetime_t frameRate;
@property( assign, readonly, dynamic) BOOL   haveGraphicsContext;
@property( assign, readonly) id <UIGraphicsContext>  renderGraphicsContext;
@property( assign) id <UIWindow>                 parentWindow;
@property( assign) NSUInteger                    debuggingFlags   MULLE_OBJC_THREADSAFE_PROPERTY;
@property( assign) BOOL                          uninitializedFramebuffer;
@property( readonly, getter=isAntiAliasing) BOOL antiAliasing;
@property( assign, readonly) struct UIInputState inputState   MULLE_OBJC_THREADSAFE_PROPERTY;
```

**Window Info:**
```objc
- (void) getOSWindowInfo:(struct UIOSWindowInfo *) info  MULLE_OBJC_THREADSAFE_METHOD;
- (id <UIScreen>) screen                              MULLE_OBJC_THREADSAFE_METHOD;
- (id <UIScreen>) screenOrPrimaryScreen:(BOOL) flag   MULLE_OBJC_THREADSAFE_METHOD;
- (NSInteger) shareID;
- (BOOL) shouldClose                                  MULLE_OBJC_THREADSAFE_METHOD;
```

**Window Management:**
```objc
- (void) os_destroyWindow;
- (void *) os_window                                  MULLE_OBJC_THREADSAFE_METHOD;
```

`os_window` always returns `NULL` — rcore has no exposed window handle.

**Window Geometry:**
```objc
- (CGPoint) os_windowPosition;
- (void) os_setWindowPosition:(CGPoint) position;
- (CGSize) os_windowSize;
- (void) os_setWindowSize:(CGSize) size;
- (CGRect) os_windowFrame;
- (void) os_setWindowFrame:(CGRect) rect;
```

**Framebuffer & Scale:**
```objc
- (CGPixelSize) os_framebufferSize;
- (CGVector) os_UIScale;
```

`os_UIScale` always returns `(1.0, 1.0)` — raylib has no HiDPI scale factor.

**Graphics Context:**
```objc
- (void) os_activateGraphicsContext       MULLE_OBJC_THREADSAFE_METHOD;
- (void) os_deactivateGraphicsContext     MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) os_tryActivateGraphicsContext    MULLE_OBJC_THREADSAFE_METHOD;
- (void) os_swapBuffers                   MULLE_OBJC_THREADSAFE_METHOD;
```

`os_activateGraphicsContext` and `os_deactivateGraphicsContext` are no-ops
(rcore context is always active on the main thread).
`os_tryActivateGraphicsContext` always returns `YES`.

`os_swapBuffers` calls `EndDrawing()` then `SwapScreenBuffer()` (requires
`SUPPORT_CUSTOM_FRAME_CONTROL=1` in raylib build).

**Swap Interval:**
```objc
- (void) os_setSwapInterval:(NSUInteger) value     MULLE_OBJC_THREADSAFE_METHOD;
```

No-op — raylib does not expose swap interval control directly.

**Close / Show / Hide:**
```objc
- (void) os_requestClose                           MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) os_windowShouldClose                      MULLE_OBJC_THREADSAFE_METHOD;
- (void) os_show;
- (void) os_hide;
```

**Title / Cursor / Input:**
```objc
- (void) os_setTitleUTF8String:(char *) s;
- (void) os_setCursor:(void *) cursor;
- (void) os_setCursorCaptured:(BOOL) captured;
- (void) os_pollInputState:(struct UIInputState *) state;
- (NSUInteger) os_pressedKeys:(NSUInteger *) keys count:(NSUInteger) count;
```

`os_setCursor:` receives raylib enum values cast to `void *` (from `os_createStandardCursor:`).
`os_setCursorCaptured:` calls `DisableCursor()` / `EnableCursor()`.

**Scroll Wheel:**
```objc
- (CGFloat) consumeScrollWheelDelta;
```
Returns accumulated scroll wheel delta since last call, then resets to 0.

**Pasteboard:**
```objc
- (char *) pasteboardCString;
- (void) setPasteboardCString:(char *) s;
```
Both are no-ops — raylib does not expose clipboard API.

**Frame Display:**
```objc
- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now;
```
If `needsRefresh` is set, calls `BeginDrawing()`, the `frameCallback`, and
`os_swapBuffers`. Returns the time remaining until the next frame is due (or
`frameRate` after drawing).

**Thread Affinity:**
```objc
- (NSThread *) activeThread                        MULLE_OBJC_THREADSAFE_METHOD;
```
Always returns `[NSThread mainThread]`.

**Input State Accessors** (thread-safe via `_inputStateLock`):
```objc
- (struct UIInputState) inputState;
- (CGPoint) mouseLocation;
- (NSUInteger) buttonStates;
- (NSUInteger) keyModifiers;
- (struct UIKeyStates) keyStates;
- (NSUInteger) pressedKeys:(NSUInteger *) keys count:(NSUInteger) count;
```

**Frame Rate:**
```objc
- (void) setFrameRateHz:(CGFloat) hz;
- (CGFloat) frameRateHz;
- (mulle_relativetime_t) frameRate;
- (void) setFrameRate:(mulle_relativetime_t) frameRate;
```

`setFrameRateHz:` converts to relative time: `hz <= 0 ? 0.0 : 1.0 / hz`.

---

### 3.2. `RCoreOSWindow+UIEvent.h`

Category on `RCoreOSWindow` for event lifecycle and synthesis.

```objc
@interface RCoreOSWindow (UIEvent)

- (void) os_initEvents;
- (void) os_finalizeEvents;

- (void) updateWindowInfo;

// Called once per frame after PollInputEvents(). Reads current rcore input
// state, diffs against previous frame, emits UIEvents via callbacks.
- (void) synthesizeEventsFromInputState;

@end
```

`os_initEvents` and `os_finalizeEvents` are no-ops (rcore has no init/finalize
for the event subsystem beyond InitWindow/CloseWindow).

`updateWindowInfo` refreshes `_windowInfo` from current window geometry,
framebuffer size, and monitor refresh rate. Called during init and on each
frame in `synthesizeEventsFromInputState`.

`synthesizeEventsFromInputState` performs:
1. Calls `os_pollInputState:` to read current state
2. Applies ctrl+left-click → right-click remapping
3. Stores current as `_inputState` (with lock), keeping previous for diff
4. Emits `UIMouseMotionEvent` if mouse moved and not discarded
5. Emits `UIMouseButtonEvent` for each changed button (down/up)
6. Emits `UIMouseScrollEvent` if wheel delta changed
7. Emits `UIKeyboardEvent` for newly pressed and released keys
8. Emits `UIWindowFramebufferResizeEvent` if framebuffer size changed
9. Emits `UIWindowCloseEvent` if `WindowShouldClose()`
10. All events go through the appropriate callback

The static helper `shouldDiscardEvent()` checks `_discardEventsMask` atomically.

---

### 3.3. `RCoreOSScreen.h`

#### `RCoreOSScreen : NSObject <UIScreen>`

Wraps raylib monitor API. Each instance represents one physical monitor.

**Class Methods:**
```objc
+ (NSUInteger) numberOfScreens;
+ (id <UIScreen>) screenAtIndex:(NSUInteger) i;
```

`numberOfScreens` returns `GetMonitorCount()`.
`screenAtIndex:` returns nil if index is out of range; otherwise returns a
new autoreleased `RCoreOSScreen`.

**Init:**
```objc
- (instancetype) initWithMonitorIndex:(NSUInteger) index;
```

**Properties:**
```objc
@property( readonly, dynamic) char *nameUTF8String   MULLE_OBJC_THREADSAFE_METHOD;
```

**Screen Info:**
```objc
- (void) getScreenInfo:(struct UIScreenInfo *) info   MULLE_OBJC_THREADSAFE_METHOD;
- (CGRect) frame                                       MULLE_OBJC_THREADSAFE_METHOD;
- (CGRect) canvas                                      MULLE_OBJC_THREADSAFE_METHOD;
- (mulle_relativetime_t) refreshRate                   MULLE_OBJC_THREADSAFE_METHOD;
```

**OS-Level Accessors:**
```objc
- (char *) os_nameUTF8String;
- (CGVector) os_contentScale;
- (CGSize) os_physicalSize;
- (CGFloat) os_dpi;
- (CGPixelRect) os_canvas;
- (CGPixelPoint) os_position;
- (BOOL) os_isPrimaryScreen;
```

`os_contentScale` always returns `(1.0, 1.0)`. `os_isPrimaryScreen` checks
`_monitorIndex == 0`. DPI is computed as `width / (physicalWidth_mm / 25.4)`,
falling back to 72.0 if physical width is zero.

---

### 3.4. `RCoreOSGamepad.h`

#### `RCoreOSGamepad : NSObject <UIGamepad>`

Wraps raylib gamepad API. Polls gamepad state via `IsGamepadAvailable` and
`GetGamepadAxisMovement`/`IsGamepadButtonDown`.

**Class Methods:**
```objc
+ (NSUInteger) numberOfGamepads;
+ (id <UIGamepad>) gamepadAtOSIndex:(NSUInteger) i;
+ (NSRange) osIndexRange;
```

`osIndexRange` returns `NSMakeRange(0, 16)` (raylib supports up to 16 gamepads).
`numberOfGamepads` counts available gamepads in that range.

**Init:**
```objc
- (instancetype) initWithOSGamepad:(void *) handle;
```
`handle` is cast to internal `int _handle` via `(int)(uintptr_t)handle`.

**Properties:**
```objc
@property( readonly, dynamic) char   *nameUTF8String;
@property( readonly, dynamic) char   *guidUTF8String;
@property( readonly, dynamic) BOOL       isJoystick;
@property( readonly, dynamic) NSInteger  osIndex;
```

`guidUTF8String` always returns `""` (raylib does not expose GUID).
`isJoystick` always returns `NO` (raylib only exposes gamepad-mapped devices).

**Info Access:**
```objc
- (void) getGamepadInfo:(struct UIGamepadInfo *) info   MULLE_OBJC_THREADSAFE_METHOD;
```

**Polling:**
```objc
- (void) os_pollGamepadInfo   MULLE_UI_MAIN_THREAD_ONLY;
```

`os_pollGamepadInfo` must be called on the main thread each frame. It reads:
- 6 axes via `GetGamepadAxisMovement`
- 18 buttons via `IsGamepadButtonDown`
- D-pad as digital stick via `GAMEPAD_BUTTON_LEFT_FACE_*` buttons

**OS Accessors:**
```objc
- (char *) os_nameUTF8String  MULLE_UI_MAIN_THREAD_ONLY;
- (char *) os_guidUTF8String  MULLE_UI_MAIN_THREAD_ONLY;
```

**Additional Gamepad Input:**
```objc
- (CADirection) direction;
- (BOOL) stateOfGamepadButton:(UIGamepadButton) button;
- (BOOL) getAnalogStickWithIndex:(NSUInteger) index axes:(float [3]) axes;
- (BOOL) getDigitalStickWithIndex:(NSUInteger) index direction:(CADirection *) direction;
```

---

### 3.5. `UIApplication+RCore` (category, not a public header)

The `UIApplication (OS)` category bridges raylib into MulleUIApplication lifecycle.
Not declared in any public header — used internally.

**Class Methods:**
```objc
+ (void) os_initialize;     // no-op (raylib init is done by RCoreOSWindow)
+ (void) os_deinitialize;   // no-op (CloseWindow is called by RCoreOSWindow finalize)
```

**Instance Methods:**
```objc
- (void) os_init;           // enumerates screens and gamepads, adds to UIApplication
- (void) os_finalize;       // no-op
```

**Event Loop:**
```objc
- (void) os_waitEventsWithTimeout:(mulle_relativetime_t) timeout;
- (void) os_pollEvents;
- (void) os_sendEmptyEvent;    // no-op (no cross-thread wake mechanism in rcore)
```

`os_waitEventsWithTimeout` calls `WaitTime(timeout)` then `PollInputEvents()`,
then synthesizes events on each window via `synthesizeEventsFromInputState`.

**Cursor:**
```objc
- (void *) os_createStandardCursor:(UICursorStandardShape) shape;
- (void *) os_createCursorWithBitmap:(struct CGBitmap) bitmap hotSpot:(struct CGPixelPoint) hotSpot;
- (void) os_destroyCursor:(void *) cursor;
```

`os_createCursorWithBitmap:` always returns `NULL` (raylib does not support
custom bitmap cursors). `os_destroyCursor:` is a no-op (cursors are enum values).

**Gamepad Polling:**
```objc
- (void) os_pollGamepads;
```

Iterates all 16 gamepad slots, calls `os_pollGamepadInfo` on available gamepads.

## 4. Performance Characteristics

- **Window creation:** O(1) — raylib `InitWindow` is platform-dependent but
  typically instant. Single-window only.
- **Input polling:** O(k + b + e) per frame where k is scancode range
  (KEY_SPACE..KEY_KP_EQUAL ≈ 300 keys), b is button/mouse bits (constant),
  e is event count for diff synthesis.
- **Event synthesis:** O(p + c) where p = previous key count, c = current key
  count. Linear scan over key arrays for press/release detection.
- **Frame display:** `displayFrameIfNeeded:` uses atomic CAS for the
  `needsRefresh` flag. The frame callback runs synchronously on the main thread.
- **Screen info:** O(1) per query. Info is cached in `_info` struct, refreshed
  on demand via raylib monitor API.
- **Gamepad polling:** O(a + b + s) per gamepad per frame where a=6 axes,
  b=18 buttons, s=1 stick. All gamepads are polled once per frame in
  `os_pollGamepads`.
- **Thread safety:** All screen/window/gamepad info accessors use `NSLock`
  for read/write protection. `discardEventsMask` uses `mulle_atomic_pointer`
  (lock-free). Input state accessors use `NSLock` (`_inputStateLock`).
- **Not thread-safe for rendering:** All `os_*` methods must be called from
  the main thread. Assertions enforce this.

## 5. AI Usage Recommendations & Patterns

**Best Practices:**
- Always use `+ windowWithFrame:titleUTF8String:styleMask:` factory method
  rather than `alloc/init` directly. Factory methods call `autorelease`.
- Set `frameCallback` to control rendering. The callback signature is
  `UIWindowDisplayBits (*)(id <UIOSWindow>)`; return `UIWindowDisplayNeedsAnimation`
  to request continuous frame updates.
- Set `frameRateHz:` to control frame timing. Use `displayFrameIfNeeded:`
  to pace frames.
- Use `[self inputState]`, `[self pressedKeys:count:]`, `[self mouseLocation]`,
  `[self buttonStates]` etc. for input queries from within the frame callback
  or UI event handlers.
- Use `[self consumeScrollWheelDelta]` to get accumulated scroll wheel movement.

**Common Pitfalls:**
- Do not create more than one `RCoreOSWindow` — it will fail (return nil).
- Do not use retained window styles (`UIWindowStyleRetained` /
  `UIWindowStyleRetainedOnMainThread`) — they are rejected.
- Do not call `os_*` methods from any thread other than the main thread.
- `os_window` always returns `NULL` — do not depend on it for anything.
- `pasteboardCString` and `setPasteboardCString:` are no-ops. Use platform-
  specific clipboard access if needed.
- `os_setSwapInterval:` is a no-op. Frame rate is controlled solely by
  `SetTargetFPS` (via `setFrameRateHz:`).
- `guidUTF8String` always returns `""` for gamepads — do not use it as a
  unique device identifier.

**Idiomatic Usage:**
- The canonical mulle-sde pattern for a MulleRCore application:
  1. Create a window with `+ windowWithFrame:titleUTF8String:styleMask:`
  2. Set the frame callback with `[window setFrameCallback:...]`
  3. Set frame rate with `[window setFrameRateHz:60.0]`
  4. Initialize `UIApplication` before creating the window and call `[app runWindow:window]` to enter the run loop
- For input, either use direct raylib calls (`IsKeyDown`, `GetMousePosition`)
  in the frame callback, or use the MulleRCore input state API
  (`[window inputState]`, `[window pressedKeys:count:]`).
- Event callbacks are initialized to the default implementations that forward
  to event receivers. Customize by setting `windowEventsCallback` and/or
  `otherRetainedEventsCallback` to your own functions.

## 6. Integration Examples

### Example 1: Minimal Window with Frame Callback

```c
#import "RCoreOSWindow.h"
#include "raylib.h"

static UIWindowDisplayBits   frameCallback( id <UIOSWindow> window)
{
   ClearBackground( RAYWHITE);
   DrawText( "Hello from MulleRCore!", 190, 200, 20, LIGHTGRAY);
   DrawFPS( 10, 10);
   return( UIWindowDisplayNeedsAnimation);
}

int   main( int argc, char *argv[])
{
   RCoreOSWindow   *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   window = [RCoreOSWindow windowWithFrame:CGRectMake( 0, 0, 800, 450)
                           titleUTF8String:"MulleRCore Demo"
                                 styleMask:UIWindowStyleResizable];
   if( ! window)
      return( 1);

   [window setFrameCallback:frameCallback];
   [window setFrameRateHz:60.0];

   return( [app runWindow:window]);
}
```

### Example 2: Using MulleRCore Input State API

```c
#import "RCoreOSWindow.h"
#include "raylib.h"

static UIWindowDisplayBits   frameCallback( id <UIOSWindow> osWindow)
{
   RCoreOSWindow      *window = (RCoreOSWindow *) osWindow;
   struct UIInputState state;
   NSUInteger          keys[UIKeyStatesMaxKeys];
   NSUInteger          keyCount;
   NSUInteger          i;

   state    = [window inputState];
   keyCount = [window pressedKeys:keys count:UIKeyStatesMaxKeys];

   ClearBackground( RAYWHITE);

   {
      char   buf[ 128];
      sprintf( buf, "Mouse: %.0f, %.0f",
               state.locationInWindow.x, state.locationInWindow.y);
      DrawText( buf, 10, 10, 20, DARKGRAY);
   }

   for( i = 0; i < keyCount; i++)
   {
      if( keys[ i] == KEY_SPACE)
         DrawText( "SPACE pressed!", 10, 40, 20, RED);
   }

   {
      CGFloat   wheel;

      wheel = [window consumeScrollWheelDelta];
      if( wheel != 0.0f)
      {
         char   buf[ 64];
         sprintf( buf, "Scroll: %.1f", wheel);
         DrawText( buf, 10, 70, 20, DARKGRAY);
      }
   }

   return( UIWindowDisplayNeedsAnimation);
}

int   main( int argc, char *argv[])
{
   RCoreOSWindow   *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   window = [RCoreOSWindow windowWithFrame:CGRectMake( 0, 0, 800, 450)
                           titleUTF8String:"Input State Demo"
                                 styleMask:UIWindowStyleResizable];
   if( ! window)
      return( 1);

   [window setFrameCallback:frameCallback];
   [window setFrameRateHz:60.0];

   return( [app runWindow:window]);
}
```

### Example 3: Custom Event Callbacks

```c
#import "RCoreOSWindow.h"

static void   myWindowEventHandler( RCoreOSWindow *window, UIWindowEvent *event)
{
   // handle resize, close, etc.
   // or forward to a receiver:
   RCoreOSWindowEventDefaultCallback( window, event);
}

static void   myRetainedEventHandler( RCoreOSWindow *window, UIEvent *event)
{
   // handle mouse/keyboard events
   RCoreOSWindowRetainedEventDefaultCallback( window, event);
}

int   main( int argc, char *argv[])
{
   RCoreOSWindow   *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   window = [RCoreOSWindow windowWithFrame:CGRectMake( 0, 0, 800, 450)
                           titleUTF8String:"Events Demo"
                                 styleMask:UIWindowStyleResizable];
   if( ! window)
      return( 1);

   [window setWindowEventsCallback:myWindowEventHandler];
   [window setOtherRetainedEventsCallback:myRetainedEventHandler];
   [window setFrameRateHz:60.0];

   return( [app runWindow:window]);
}
```

### Example 4: Custom Graphics Backend

```c
#import "RCoreOSWindow.h"
#include "raylib.h"

static UIWindowDisplayBits   frameCallback( id <UIOSWindow> osWindow)
{
   ClearBackground( (Color){ 14, 14, 14, 255 });
   DrawFPS( 10, 10);
   return( UIWindowDisplayNeedsAnimation);
}

int   main( int argc, char *argv[])
{
   RCoreOSWindow   *window;

   // Request OpenGL ES 3.0 backend
   window = [RCoreOSWindow windowWithFrame:CGRectMake( 0, 0, 800, 450)
                           titleUTF8String:"GLES3 Demo"
                                 styleMask:UIWindowStyleResizable
                             graphicsHints:RCoreGraphicsHintsGLES3];
   if( ! window)
      return( 1);

   [window setFrameCallback:frameCallback];
   [window setFrameRateHz:60.0];

   return( [app runWindow:window]);
}
```

## 7. Dependencies

- `MulleObjC` — mulle-objc runtime, NSObject base class, threading primitives
- `MulleUIApplication` — defines `UIWindow`, `UIOSWindow`, `UIScreen`,
  `UIGamepad` protocols and event types
- `mulle-objc-list` — list/array type used internally by UIApplication
- `raylib` — raylib C library providing `InitWindow`, `CloseWindow`, OpenGL
  context, input polling, monitor/gamepad enumeration, rendering API
- `mulle-gfx` — `CGRect`, `CGPoint`, `CGSize`, `CGPixelSize`, `CGVector`,
  and related geometry types (dependency of MulleUIApplication, inherited)
