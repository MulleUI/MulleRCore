<!-- Keywords: singleton, no-retained, main-thread, no-op, no-HiDPI, NULL-handle -->
# Quirks

## Single-window constraint

Raylib's rcore uses a global singleton (`CoreData CORE`). Only one
`RCoreOSWindow` can exist at a time. Creating a second returns `nil`.

## Retained windows rejected

`UIWindowStyleRetained` and `UIWindowStyleRetainedOnMainThread` are
rejected at init time. Only non-retained (single-thread GL) mode is
supported.

Drawing context on `RCoreOSWindow` also returns `UIGraphicsBackendNonRetained`.

## Main-thread only

All `os_*` methods, rendering, and gamepad polling must run on the main
thread. Assertions enforce this.

- `os_activateGraphicsContext` / `os_deactivateGraphicsContext` are no-ops
  (context always active on main thread).
- `os_tryActivateGraphicsContext` always returns `YES`.
- `activeThread` always returns `[NSThread mainThread]`.

## No exposed window handle

`os_window` always returns `NULL`. Raylib does not expose a native window
handle. Do not depend on it.

## No HiDPI support

`os_UIScale` always returns `(1.0, 1.0)`. Raylib does not expose a scale
factor.

## Pasteboard is unavailable

`pasteboardCString` and `setPasteboardCString:` are no-ops. Raylib does
not expose clipboard API. Use platform-specific clipboard access if needed.

## Swap interval is fixed

`os_setSwapInterval:` is a no-op. Raylib does not expose swap interval
control directly. Frame rate is controlled solely by `SetTargetFPS`
(via `setFrameRateHz:`).

## Framebuffer swap requires custom frame control

`os_swapBuffers` calls `EndDrawing()` then `SwapScreenBuffer()`. This
requires raylib to be built with `SUPPORT_CUSTOM_FRAME_CONTROL=1`.

## Gamepad GUID always empty

`guidUTF8String` always returns `""`. Raylib does not expose a gamepad
GUID. Do not use it as a unique device identifier.

## Gamepad isJoystick always NO

`isJoystick` always returns `NO`. Raylib only exposes gamepad-mapped
devices, not raw joysticks.

## Screen content scale is always 1.0

`os_contentScale` always returns `(1.0, 1.0)`. Raylib does not expose
per-monitor content scaling.

## Primary screen is index 0

`os_isPrimaryScreen` checks `monitorIndex == 0`. This matches raylib's
`GetMonitorCount`/`GetCurrentMonitor` semantics.

## No event-driven wait

`os_waitEventsWithTimeout` uses `WaitTime(timeout)` then `PollInputEvents()`.
There is no `WaitEventsTimeout` equivalent. The main loop runs at a fixed
framerate using `displayFrameIfNeeded:` for frame pacing.

## No cross-thread wake

`os_sendEmptyEvent` is a no-op. There is no cross-thread wake mechanism
in rcore.

## Scroll wheel is accumulated

`consumeScrollWheelDelta` returns the accumulated delta since the last
call and resets to 0. Call it once per frame to avoid missing motion.

## sharingWindow is unsupported

Passing a non-nil `sharingWindow` to any init method causes a no-op: the
handler prints an error, releases self, and returns `nil`.
