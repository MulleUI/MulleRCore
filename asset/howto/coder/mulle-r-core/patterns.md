<!-- Keywords: factory, frame-callback, poll-diff, input-state, screen-enumeration, gamepad-polling -->
# Patterns

## Window creation

Always prefer the factory method over `alloc`/`init`:

```objc
RCoreOSWindow *window;

window = [RCoreOSWindow windowWithFrame:CGRectMake(0, 0, 800, 450)
                        titleUTF8String:"My Window"
                              styleMask:UIWindowStyleResizable];
```

`windowWithFrame:titleUTF8String:styleMask:graphicsHints:` accepts
`RCoreGraphicsHints` to request a specific GL version:

```objc
window = [RCoreOSWindow windowWithFrame:CGRectMake(0, 0, 800, 450)
                        titleUTF8String:"GLES3"
                              styleMask:UIWindowStyleResizable
                          graphicsHints:RCoreGraphicsHintsGLES3];
```

Use `RCoreGraphicsHintsDefault` for system-default, `RCoreGraphicsHintsGL3_3`
for OpenGL 3.3, `RCoreGraphicsHintsGLES2`/`RCoreGraphicsHintsGLES3` for ES.

## Frame callback and rendering

Set a `frameCallback` that returns `UIWindowDisplayNeedsAnimation` for
continuous updates:

```objc
static UIWindowDisplayBits  frameCallback(id <UIOSWindow> window)
{
   ClearBackground(RAYWHITE);
   DrawText("Hello from MulleRCore!", 190, 200, 20, LIGHTGRAY);
   DrawFPS(10, 10);
   return(UIWindowDisplayNeedsAnimation);
}

[window setFrameCallback:frameCallback];
[window setFrameRateHz:60.0];
```

Inside the callback, call raylib draw functions directly. The context is always
active on the main thread.

## Reading input state

Use `[window inputState]` and `[window pressedKeys:count:]` for poll-diff input:

```objc
RCoreOSWindow      *window = (RCoreOSWindow *) osWindow;
struct UIInputState state;
NSUInteger          keys[UIKeyStatesMaxKeys];
NSUInteger          keyCount;

state    = [window inputState];
keyCount = [window pressedKeys:keys count:UIKeyStatesMaxKeys];

// Use state.locationInWindow, state.buttonStates, state.keyModifiers
// keys[] contains currently-pressed scancodes
```

From demos at `demo/src/main-rcore-bone-socket.m`, use `consumeScrollWheelDelta`
for accumulated scroll wheel since last read:

```objc
CGFloat wheel = [window consumeScrollWheelDelta];
if (wheel != 0.0f)
    CameraMoveToTarget(&camera, -wheel);
```

## Direct raylib input (simpler)

For quick demos, call raylib input functions directly inside the frame callback
without going through the MulleRCore input state. This is shown in
`demo/src/main-rcore-input.m`:

```objc
Vector2 mouse = GetMousePosition();
BOOL    down  = IsMouseButtonDown(MOUSE_BUTTON_LEFT);
```

## Screen enumeration

```objc
NSUInteger count = [RCoreOSScreen numberOfScreens];
for (NSUInteger i = 0; i < count; i++)
{
    id <UIScreen> screen = [RCoreOSScreen screenAtIndex:i];
    CGRect frame = [screen frame];
    CGFloat refresh = [screen refreshRate];
}
```

`[screen canvas]` returns the usable pixel area of the monitor. DPI is
computed from monitor physical size; falls back to 72 if unavailable.

## Gamepad polling

```objc
NSUInteger count = [RCoreOSGamepad numberOfGamepads];
for (NSUInteger i = 0; i < count; i++)
{
    id <UIGamepad> gp = [RCoreOSGamepad gamepadAtOSIndex:i];
    [gp os_pollGamepadInfo];  // main thread only
    struct UIGamepadInfo info;
    [gp getGamepadInfo:&info];
}
```

`osIndexRange` returns `NSMakeRange(0, 16)` — raylib supports up to 16 gamepads.
`os_pollGamepadInfo` must be called each frame on the main thread.

## Custom event callbacks

Replace default event forwarding with custom C function callbacks:

```objc
[window setWindowEventsCallback:myWindowEventHandler];
[window setOtherRetainedEventsCallback:myRetainedEventHandler];
```

Call the default implementations (`RCoreOSWindowEventDefaultCallback`,
`RCoreOSWindowRetainedEventDefaultCallback`) inside custom handlers to
forward to event receivers when appropriate.
