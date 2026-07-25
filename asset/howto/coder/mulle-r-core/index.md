<!-- Keywords: raylib, rcore, window, screen, gamepad, input, poll-diff, RCoreOSWindow, RCoreOSScreen, RCoreOSGamepad -->
# MulleRCore — raylib rcore backend for MulleUI

Use this topic when writing code that uses MulleRCore to create a window, render
with raylib, read input, enumerate screens, or poll gamepads. MulleRCore wraps
raylib's `rcore` platform layer into MulleUI protocol objects (`UIOSWindow`,
`UIScreen`, `UIGamepad`).

## Understand first

```bash
mulle-sde api cat class RCoreOSWindow
mulle-sde api cat class RCoreOSScreen
mulle-sde api cat class RCoreOSGamepad
mulle-sde api cat category RCoreOSWindow+UIEvent
mulle-sde code search "RCoreOSWindow"
```

## Local references

| Path | Description |
|------|-------------|
| `src/RCoreOSWindow.h` | Window creation, geometry, rendering, input state, callbacks |
| `src/RCoreOSWindow+UIEvent.h` | Event synthesis category (poll-diff input model) |
| `src/RCoreOSScreen.h` | Monitor enumeration via raylib `GetMonitor*` API |
| `src/RCoreOSGamepad.h` | Gamepad polling via raylib `GetGamepad*` API |
| `demo/src/main-rcore-shapes.m` | Minimal window + raylib drawing example |
| `demo/src/main-rcore-input.m` | Direct raylib input in frame callback |
| `demo/src/main-rcore-bone-socket.m` | Full input state API usage + 3D rendering |

## Dominant API families

| Family | Class / Header | Purpose |
|--------|----------------|---------|
| **Window** | `RCoreOSWindow` | Single-window GL creation, frame callback, geometry, rendering loop |
| **Input** | `RCoreOSWindow+UIEvent` | Poll-diff input model: diffs rcore state each frame, emits `UIEvent` objects |
| **Screen** | `RCoreOSScreen` | Physical monitor enumeration, DPI, position, refresh rate |
| **Gamepad** | `RCoreOSGamepad` | Gamepad availability, axis/button state, main-thread-only polling |

## Primary workflow

1. Create a window with `+[RCoreOSWindow windowWithFrame:titleUTF8String:styleMask:]`
2. Set a `frameCallback` to issue raylib draw commands each frame
3. Set frame rate with `[window setFrameRateHz:]`
4. Call `UIApplicationRunWindow(window)` to enter the run loop

For input, either call raylib functions directly (`GetMousePosition`, `IsKeyDown`)
inside the frame callback, or use the MulleRCore input state API
(`[window inputState]`, `[window pressedKeys:count:]`) for poll-diff access.

## Verify

```bash
mulle-sde craft --debug && mulle-sde run
```

For the demo project under `demo/`:

```bash
mulle-sde craft --debug
mulle-sde run main-rcore-shapes
mulle-sde run main-rcore-input
mulle-sde run main-rcore-bone-socket
```
