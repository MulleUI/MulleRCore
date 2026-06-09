//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"


@class UIEvent;
@class UIWindowEvent;
@class RCoreOSWindow;


#define RCoreOSWindowStyleMaskDefault  (0)

typedef UIOSWindowGraphicsHints   RCoreGraphicsHints;


#define RCoreGraphicsHintsDefault   ((RCoreGraphicsHints){ 0 })
#define RCoreGraphicsHintsGL3_3     ((RCoreGraphicsHints){ .api = 3, .major = 3, .minor = 3 })
#define RCoreGraphicsHintsGLES2     ((RCoreGraphicsHints){ .api = 2, .major = 2, .minor = 0 })
#define RCoreGraphicsHintsGLES3     ((RCoreGraphicsHints){ .api = 2, .major = 3, .minor = 0 })


typedef void   (*RCoreOSWindowEventCallback_t)( RCoreOSWindow *window, UIWindowEvent *event);
typedef void   (*RCoreOSWindowRetainedEventCallback_t)( RCoreOSWindow *window, UIEvent *retainedEvent);


//
// RCoreOSWindow wraps raylib's rcore for window creation and event handling.
//
// Constraints from rcore:
//   - Single window only (CoreData CORE is a global singleton)
//   - Non-retained mode only (single-threaded GL context)
//   - Fixed framerate only (no WaitEventsTimeout equivalent)
//   - Poll-diff input model (no per-event callbacks)
//
@interface RCoreOSWindow : NSObject < UIWindow, UIOSWindow>
{
   mulle_absolutetime_t     _lastSwapBuffersTimestamp;
   mulle_atomic_pointer_t   _needsRefresh;
   mulle_atomic_pointer_t   _discardEventsMask;

   NSLock                   *_windowInfoLock;
   struct UIOSWindowInfo    _windowInfo;

   NSLock                   *_inputStateLock;
   struct UIInputState      _inputState;
   struct UIInputState      _previousInputState;

   NSUInteger               _styleMask;
   BOOL                     _windowShouldClose;
   BOOL                     _antiAliasing;
   UIGraphicsBackend        _backend;

   UIOSWindowFrameCallback_t              _frameCallback;
   RCoreOSWindowEventCallback_t           _windowEventsCallback;
   RCoreOSWindowRetainedEventCallback_t   _otherRetainedEventsCallback;

   CGFloat                  _scrollWheelSensitivity;
   CGFloat                  _scrollWheelDelta;
   BOOL                     _uninitializedFramebuffer;

   NSUInteger               _debuggingFlags;
}

@property( assign) id <UIEventReceiver>   windowEventsReceiver;
@property( assign) id <UIEventReceiver>   eventsReceiver;

@property( assign) RCoreOSWindowEventCallback_t           windowEventsCallback;
@property( assign) RCoreOSWindowRetainedEventCallback_t   otherRetainedEventsCallback;

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

- (void) getOSWindowInfo:(struct UIOSWindowInfo *) info  MULLE_OBJC_THREADSAFE_METHOD;

- (id <UIScreen>) screen                              MULLE_OBJC_THREADSAFE_METHOD;
- (id <UIScreen>) screenOrPrimaryScreen:(BOOL) flag   MULLE_OBJC_THREADSAFE_METHOD;

- (NSInteger) shareID;
- (BOOL) shouldClose;

- (void) os_destroyWindow;
- (void *) os_window;

- (CGPoint) os_windowPosition;
- (void) os_setWindowPosition:(CGPoint) position;
- (CGSize) os_windowSize;
- (void) os_setWindowSize:(CGSize) size;
- (CGRect) os_windowFrame;
- (void) os_setWindowFrame:(CGRect) rect;
- (void) os_setSwapInterval:(NSUInteger) value;

- (CGPixelSize) os_framebufferSize;
- (CGVector) os_UIScale;

- (void) os_activateGraphicsContext       MULLE_OBJC_THREADSAFE_METHOD;
- (void) os_deactivateGraphicsContext     MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) os_tryActivateGraphicsContext    MULLE_OBJC_THREADSAFE_METHOD;
- (void) os_swapBuffers;

- (void) os_requestClose;
- (BOOL) os_windowShouldClose;

- (void) os_show;
- (void) os_hide;

- (void) os_setTitleUTF8String:(char *) s;
- (void) os_setCursor:(void *) cursor;
- (void) os_setCursorCaptured:(BOOL) captured;

- (void) os_pollInputState:(struct UIInputState *) state;
- (NSUInteger) os_pressedKeys:(NSUInteger *) keys
                        count:(NSUInteger) count;

// Returns accumulated scroll wheel delta since last call (resets on read)
- (CGFloat) consumeScrollWheelDelta;

- (char *) pasteboardCString;
- (void) setPasteboardCString:(char *) s;

- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now;

- (NSThread *) activeThread;

@end


void   RCoreOSWindowEventDefaultCallback( RCoreOSWindow *window, UIWindowEvent *event);
void   RCoreOSWindowRetainedEventDefaultCallback( RCoreOSWindow *window, UIEvent *retainedEvent);
