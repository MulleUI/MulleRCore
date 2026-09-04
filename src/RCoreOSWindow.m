//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "RCoreOSWindow.h"

#import "import-private.h"

#import "RCoreOSWindow+UIEvent.h"
#import "RCoreOSScreen.h"

#import <MulleUIApplication/UIOSWindow+DebugPrivate.h>

#include "raylib.h"


#pragma clang diagnostic ignored "-Wprotocol"


@interface RCoreOSWindow( UIEventFuture)

- (void) _windowFramebufferResizeCallback:(CGPixelSize) size;

@end


static UIWindowDisplayBits   defaultFrameCallback( id <UIOSWindow> window_in)
{
   mulleui_log( "The RCore window needs a frameCallback.\n");
   abort();
}


void   RCoreOSWindowEventDefaultCallback( RCoreOSWindow *window, UIWindowEvent *event)
{
   id <UIEventReceiver>   receiver;

   receiver = [window windowEventsReceiver];
   if( receiver)
      [receiver handleWindowEvent:event];
}


void   RCoreOSWindowRetainedEventDefaultCallback( RCoreOSWindow *window, UIEvent *retainedEvent)
{
   id <UIEventReceiver>   receiver;

   receiver = [window eventsReceiver];
   if( receiver)
      [receiver receiveRetainedEvent:retainedEvent];
   else
      [retainedEvent release];
}


@implementation RCoreOSWindow

static mulle_atomic_pointer_t   s_singleton;

static struct
{
   NSUInteger   _debuggingFlags;
} ClassStatic;


+ (void) initialize
{
   char   *s;

   if( MulleObjCClassGetID( self) != @selector( RCoreOSWindow))
      return;

   s = getenv( MULLE_C_STRINGIFY( RCoreOSWindow) "DebuggingFlags");
   if( ! s)
      s = getenv( "UIOSWindowDebuggingFlags");
   if( ! s)
      s = getenv( "UIDebuggingFlags");
   if( s)
      ClassStatic._debuggingFlags = strtol( s, NULL, 0);
}


+ (void) setDebuggingFlags:(NSUInteger) flag  MULLE_OBJC_THREADSAFE_METHOD
{
   ClassStatic._debuggingFlags = flag;
}


- (BOOL) __isUIOSWindow
{
   return( YES);
}


+ (instancetype) windowWithFrame:(CGRect) frame
                 titleUTF8String:(char *) title
                       styleMask:(NSUInteger) styleMask
{
   return( [[[self alloc] initWithFrame:frame
                        titleUTF8String:title
                              styleMask:styleMask] autorelease]);
}


+ (instancetype) windowWithFrame:(CGRect) frame
                 titleUTF8String:(char *) title
                       styleMask:(NSUInteger) styleMask
                   graphicsHints:(RCoreGraphicsHints) graphicsHints
{
   return( [[[self alloc] initWithFrame:frame
                        titleUTF8String:title
                              styleMask:styleMask
                          graphicsHints:graphicsHints] autorelease]);
}


- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
{
   return( [self initWithFrame:frame
               titleUTF8String:title
                     styleMask:styleMask
                 graphicsHints:RCoreGraphicsHintsDefault
                 sharingWindow:nil]);
}


- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
                 graphicsHints:(RCoreGraphicsHints) graphicsHints
{
   return( [self initWithFrame:frame
               titleUTF8String:title
                     styleMask:styleMask
                 graphicsHints:graphicsHints
                 sharingWindow:nil]);
}


//
// rcore is single-window, sharing is not supported
//
- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
                 graphicsHints:(RCoreGraphicsHints) graphicsHints
                 sharingWindow:(id <UIOSWindow>) sharingWindow
{
   unsigned int   flags;

   assert( [NSThread mulleIsMainThread]);

   if( styleMask & (UIWindowStyleRetained|UIWindowStyleRetainedOnMainThread))
   {
      mulleui_log( "error: RCoreOSWindow only supports a single window, no retained window styles possible\n");
      [self release];
      return( nil);
   }

   if( ! _mulle_atomic_pointer_cas( &s_singleton, self, NULL))
   {
      mulleui_log( "error: RCoreOSWindow only supports a single window, one already exists\n");
      [self release];
      return( nil);
   }

   if( ! styleMask)
      styleMask = RCoreOSWindowStyleMaskDefault;

   _styleMask = styleMask;

   // map styleMask to raylib config flags
   flags = 0;
   if( styleMask & UIWindowStyleResizable)
      flags |= FLAG_WINDOW_RESIZABLE;
   if( styleMask & UIWindowStyleBare)
      flags |= FLAG_WINDOW_UNDECORATED;
   if( styleMask & UIWindowStyleTransparent)
      flags |= FLAG_WINDOW_TRANSPARENT;
   if( styleMask & UIWindowStyleHidden)
      flags |= FLAG_WINDOW_HIDDEN;
   if( styleMask & UIWindowStyleAntiAlias)
      flags |= FLAG_MSAA_4X_HINT;

   SetConfigFlags( flags);
   InitWindow( (int) frame.size.width, (int) frame.size.height,
               title ? title : "");

   if( ! IsWindowReady())
   {
      mulleui_log( "error: raylib InitWindow failed\n");
      [self release];
      return( nil);
   }

   // position window if non-zero origin
   if( frame.origin.x != 0.0 || frame.origin.y != 0.0)
      SetWindowPosition( (int) frame.origin.x, (int) frame.origin.y);

   _backend = UIGraphicsBackendGL3_2Forward;  // raylib default is GL 3.3 core

   if( graphicsHints.api == 2)
      _backend = graphicsHints.major >= 3 ? UIGraphicsBackendGLES3
                                          : UIGraphicsBackendGLES2;

   if( flags & FLAG_MSAA_4X_HINT)
      _antiAliasing = YES;

   _mulle_atomic_pointer_nonatomic_write( &_needsRefresh, (void *) 1);

#ifdef RCORE_OS_WINDOW_DEBUGGING_FLAGS
   _debuggingFlags = RCORE_OS_WINDOW_DEBUGGING_FLAGS;
#else
   _debuggingFlags = ClassStatic._debuggingFlags;
#endif

   _frameCallback               = defaultFrameCallback;
   _windowEventsCallback        = RCoreOSWindowEventDefaultCallback;
   _otherRetainedEventsCallback = RCoreOSWindowRetainedEventDefaultCallback;
   _scrollWheelSensitivity      = 20.0;
   _uninitializedFramebuffer    = YES;

   _windowInfo.frameRate = UIWindowFrameRateAsync;

   _windowInfoLock = [NSLock new];
   _inputStateLock = [NSLock new];

   [self updateWindowInfo];

   return( self);
}


// updateWindowInfo is implemented in RCoreOSWindow+UIEvent.m


- (void) finalize
{
   if( IsWindowReady())
      CloseWindow();
   _mulle_atomic_pointer_cas( &s_singleton, NULL, self);
   [super finalize];
}


- (void) dealloc
{
   [_windowInfoLock release];
   [_inputStateLock release];
   [super dealloc];
}


- (id <UIOSWindow>) OSWindow
{
   return( self);
}


- (NSInteger) shareID
{
   return( 1);  // single window, always ID 1
}


- (void) getOSWindowInfo:(struct UIOSWindowInfo *) info
{
   [_windowInfoLock lock];
   {
      *info = _windowInfo;
   }
   [_windowInfoLock unlock];
}


- (BOOL) frameRateLimiter
{
   BOOL   flag;

   [_windowInfoLock lock];
   flag = _windowInfo.frameRateLimiter;
   [_windowInfoLock unlock];
   return( flag);
}


- (void) setFrameRateLimiter:(BOOL) flag
{
   [_windowInfoLock lock];
   _windowInfo.frameRateLimiter = flag;
   [_windowInfoLock unlock];
}


- (mulle_relativetime_t) frameRate
{
   mulle_relativetime_t   frameRate;

   [_windowInfoLock lock];
   frameRate = _windowInfo.frameRate;
   [_windowInfoLock unlock];
   return( frameRate);
}


- (void) setFrameRate:(mulle_relativetime_t) frameRate
{
   [_windowInfoLock lock];
   _windowInfo.frameRate = frameRate;
   [_windowInfoLock unlock];
}


- (void) setFrameRateHz:(CGFloat) hz
{
   [self setFrameRate:hz <= 0.0 ? 0.0 : 1.0 / hz];
}


- (CGFloat) frameRateHz
{
   double   frameRate;

   frameRate = [self frameRate];
   if( frameRate <= 0.0f)
      return( 0.0f);
   if( isinf( frameRate))
      return( INFINITY);
   return( (CGFloat) (1.0 / frameRate));
}


- (mulle_absolutetime_t) lastSwapBuffersTimestamp
{
   return( _lastSwapBuffersTimestamp);
}


- (NSUInteger) discardEventsMask
{
   return( (NSUInteger) _mulle_atomic_pointer_read( &_discardEventsMask));
}


- (void) setDiscardEventsMask:(NSUInteger) mask
{
   _mulle_atomic_pointer_write( &_discardEventsMask, (void *) mask);
}


- (id <UIScreen>) screenOrPrimaryScreen:(BOOL) flag
{
   struct UIOSWindowInfo   info;

   [self getOSWindowInfo:&info];
   return( [UIApp screenForFrame:info.base.frame
            primaryIfNoneMatches:flag]);
}


- (id <UIScreen>) screen
{
   return( [self screenOrPrimaryScreen:NO]);
}


- (void *) os_window
{
   return( NULL);  // rcore has no exposed window handle
}


#pragma mark - Graphics Context (no-ops for single-threaded rcore)

- (void) os_activateGraphicsContext
{
   // rcore context is always active on main thread — no-op
}


- (BOOL) os_tryActivateGraphicsContext
{
   return( YES);
}


- (void) os_deactivateGraphicsContext
{
   // no-op
}


- (BOOL) haveGraphicsContext
{
   return( IsWindowReady());
}


- (NSThread *) activeThread
{
   return( [NSThread mainThread]);
}


#pragma mark - Window Properties

- (void) os_setTitleUTF8String:(char *) s
{
   assert( [NSThread mulleIsMainThread]);
   SetWindowTitle( s ? s : "");
}


- (void) os_swapBuffers
{
   assert( [NSThread mulleIsMainThread]);

   if( ! IsWindowReady())
      return;

   UIOSWindowSwapLog( "swapped buffers");

   EndDrawing();         // flush render batch only (SUPPORT_CUSTOM_FRAME_CONTROL)
   SwapScreenBuffer();   // we manage swap ourselves
   _lastSwapBuffersTimestamp = mulle_absolutetime_now();
}


- (void) os_setSwapInterval:(NSUInteger) value
{
   // raylib does not expose swap interval control directly
   // SetTargetFPS is the closest equivalent
}


- (void) os_requestClose
{
   _windowShouldClose = YES;
}


- (BOOL) os_windowShouldClose
{
   return( _windowShouldClose || WindowShouldClose());
}


- (BOOL) shouldClose
{
   return( [self os_windowShouldClose]);
}


- (void) applicationDidAddWindow:(UIApplication *) app
{
   assert( [NSThread mulleIsMainThread]);
}


- (void) applicationDidRemoveWindow:(UIApplication *) app
{
   assert( [NSThread mulleIsMainThread]);
   [self mullePerformFinalize];
}


- (void) os_show
{
   assert( [NSThread mulleIsMainThread]);
   ClearWindowState( FLAG_WINDOW_HIDDEN);
}


- (void) os_hide
{
   assert( [NSThread mulleIsMainThread]);
   SetWindowState( FLAG_WINDOW_HIDDEN);
}


- (void) os_destroyWindow
{
   if( IsWindowReady())
      CloseWindow();
}


#pragma mark - Geometry

- (CGPoint) os_windowPosition
{
   Vector2   pos;

   assert( [NSThread mulleIsMainThread]);
   pos = GetWindowPosition();
   return( CGPointMake( pos.x, pos.y));
}


- (CGSize) os_windowSize
{
   assert( [NSThread mulleIsMainThread]);
   return( CGSizeMake( GetScreenWidth(), GetScreenHeight()));
}


- (CGRect) os_windowFrame
{
   Vector2   pos;

   assert( [NSThread mulleIsMainThread]);
   pos = GetWindowPosition();
   return( CGRectMake( pos.x, pos.y, GetScreenWidth(), GetScreenHeight()));
}


- (void) os_setWindowPosition:(CGPoint) origin
{
   assert( [NSThread mulleIsMainThread]);
   SetWindowPosition( (int) origin.x, (int) origin.y);
}


- (void) os_setWindowSize:(CGSize) size
{
   assert( [NSThread mulleIsMainThread]);
   SetWindowSize( (int) size.width, (int) size.height);
}


- (void) os_setWindowFrame:(CGRect) rect
{
   assert( [NSThread mulleIsMainThread]);
   SetWindowPosition( (int) rect.origin.x, (int) rect.origin.y);
   SetWindowSize( (int) rect.size.width, (int) rect.size.height);
}


- (CGPixelSize) os_framebufferSize
{
   assert( [NSThread mulleIsMainThread]);
   return( CGPixelSizeMake( GetRenderWidth(), GetRenderHeight()));
}


- (CGVector) os_UIScale
{
   assert( [NSThread mulleIsMainThread]);
   return( CGVectorMake( 1.0, 1.0));
}


#pragma mark - Cursor

- (void) os_setCursor:(UICursor *) cursor
{
   assert( [NSThread mulleIsMainThread]);
   // raylib uses SetMouseCursor with enum values, not opaque handles
   // this would need a mapping layer
}


- (void) os_setCursorCaptured:(BOOL) captured
{
   assert( [NSThread mulleIsMainThread]);

   if( captured)
      DisableCursor();
   else
      EnableCursor();
}


#pragma mark - Pasteboard

- (char *) pasteboardCString
{
   // raylib does not expose clipboard API in rcore
   return( NULL);
}


- (void) setPasteboardCString:(char *) s
{
   // raylib does not expose clipboard API in rcore
}


#pragma mark - Refresh / Frame Display

- (void) setNeedsRefresh
{
   _mulle_atomic_pointer_write( &_needsRefresh, (void *) 1);
}


- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now
{
   mulle_relativetime_t   diff;
   mulle_relativetime_t   left;
   mulle_relativetime_t   frameRate;

   assert( [NSThread mulleIsMainThread]);

   frameRate = [self frameRate];

   if( _mulle_atomic_pointer_read( &_needsRefresh) == NULL)
   {
      diff = now - _lastSwapBuffersTimestamp;
      left = frameRate - diff;
      if( left > 0.0)
         return( left);
   }

   _mulle_atomic_pointer_cas( &_needsRefresh, (void *) 0, (void *) 1);

   BeginDrawing();
   (*_frameCallback)( self);
   [self os_swapBuffers];

   return( frameRate);
}


#pragma mark - Input (poll-diff model)

- (void) os_pollInputState:(struct UIInputState *) state
{
   assert( [NSThread mulleIsMainThread]);

   memset( state, 0, sizeof( struct UIInputState));

   state->locationInWindow.x = GetMouseX();
   state->locationInWindow.y = GetMouseY();

   if( IsMouseButtonDown( MOUSE_BUTTON_LEFT))
      state->buttonStates |= (1 << 0);
   if( IsMouseButtonDown( MOUSE_BUTTON_RIGHT))
      state->buttonStates |= (1 << 1);
   if( IsMouseButtonDown( MOUSE_BUTTON_MIDDLE))
      state->buttonStates |= (1 << 2);

   if( IsKeyDown( KEY_LEFT_SHIFT) || IsKeyDown( KEY_RIGHT_SHIFT))
      state->keyModifiers |= (1 << 0);
   if( IsKeyDown( KEY_LEFT_CONTROL) || IsKeyDown( KEY_RIGHT_CONTROL))
      state->keyModifiers |= (1 << 1);
   if( IsKeyDown( KEY_LEFT_ALT) || IsKeyDown( KEY_RIGHT_ALT))
      state->keyModifiers |= (1 << 2);
   if( IsKeyDown( KEY_LEFT_SUPER) || IsKeyDown( KEY_RIGHT_SUPER))
      state->keyModifiers |= (1 << 3);

   state->keyStates._count = [self os_pressedKeys:state->keyStates._keys
                                            count:UIKeyStatesMaxKeys];
}


- (NSUInteger) os_pressedKeys:(NSUInteger *) keys
                        count:(NSUInteger) count
{
   NSUInteger   n;
   int          key;

   n = 0;
   for( key = KEY_SPACE; key <= KEY_KP_EQUAL; key++)
   {
      if( n >= count)
         break;
      if( IsKeyDown( key))
         keys[ n++] = key;
   }
   return( n);
}


- (CGFloat) consumeScrollWheelDelta
{
   CGFloat   delta;

   delta             = _scrollWheelDelta;
   _scrollWheelDelta = 0.0;
   return( delta);
}


- (NSUInteger) pressedKeys:(NSUInteger *) keys
                     count:(NSUInteger) count
{
   NSUInteger   n;

   NSLockingDo( _inputStateLock)
   {
      n = UIKeyStatesGetPressedKeys( UIInputStateGetKeyStates( &_inputState),
                                     keys,
                                     count);
   }
   return( n);
}


- (struct UIInputState) inputState
{
   struct UIInputState   rval;

   NSLockingDo( _inputStateLock)
   {
      rval = _inputState;
   }
   return( rval);
}


- (CGPoint) mouseLocation
{
   CGPoint   rval;

   NSLockingDo( _inputStateLock)
   {
      rval = _inputState.locationInWindow;
   }
   return( rval);
}


- (NSUInteger) buttonStates
{
   NSUInteger   rval;

   NSLockingDo( _inputStateLock)
   {
      rval = _inputState.buttonStates;
   }
   return( rval);
}


- (NSUInteger) keyModifiers
{
   NSUInteger   rval;

   NSLockingDo( _inputStateLock)
   {
      rval = _inputState.keyModifiers;
   }
   return( rval);
}


- (struct UIKeyStates) keyStates
{
   struct UIKeyStates   rval;

   NSLockingDo( _inputStateLock)
   {
      rval = _inputState.keyStates;
   }
   return( rval);
}


// os_initEvents and os_finalizeEvents are in RCoreOSWindow+UIEvent.m


- (void) syncOSWindowPropertyChangesIfNeeded
{
}


#pragma mark - UIWindow / UIEventReceiver protocol stubs

- (void) applicationDidChangeWindowCount:(NSUInteger) count
{
}


+ (NSUInteger) effectiveWindowStyleMask:(NSUInteger) styleMask
                          graphicsHints:(UIOSWindowGraphicsHints) hints
{
   return( styleMask);
}


- (id) firstResponder
{
   return( nil);
}


- (UIWindowEvent *) handleWindowEvent:(UIWindowEvent *) event
{
   return( event);
}


- (void) receiveRetainedEvent:(UIEvent *) event
{
   [event release];
}

@end
