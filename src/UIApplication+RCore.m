//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "import-private.h"

#import "RCoreOSScreen.h"
#import "RCoreOSGamepad.h"
#import "RCoreOSWindow+UIEvent.h"

#include "raylib.h"


@interface UIApplication( UIScreenPrivate)

- (void) _addScreen:(id <UIScreen>) screen;
- (void) _removeScreen:(id <UIScreen>) screen;

@end


@interface UIApplication( UIGamepadPrivate)

- (void) _addGamepad:(id <UIGamepad>) gamepad;
- (void) _removeGamepad:(id <UIGamepad>) gamepad;

@end


@interface UIApplication ( RCore)
@end


@implementation UIApplication ( OS)

+ (void) os_initialize
{
   assert( [NSThread mulleIsMainThread]);

   // raylib InitWindow is done by RCoreOSWindow, not here.
   // rcore does not have a separate init/terminate for the platform
   // outside of InitWindow/CloseWindow.
}


+ (void) os_deinitialize
{
   // CloseWindow is called by RCoreOSWindow finalize
}


- (void) os_init
{
   NSUInteger       i, n;
   RCoreOSScreen    *screen;
   RCoreOSGamepad   *gamepad;
   NSRange          range;
   NSUInteger       max;

   n = [RCoreOSScreen numberOfScreens];
   for( i = 0; i < n; i++)
   {
      screen = (RCoreOSScreen *) [RCoreOSScreen screenAtIndex:i];
      [self _addScreen:screen];
   }

   range = [RCoreOSGamepad osIndexRange];
   max   = NSMaxRange( range);
   for( i = range.location; i < max; i++)
   {
      gamepad = (RCoreOSGamepad *) [RCoreOSGamepad gamepadAtOSIndex:i];
      if( gamepad)
         [self _addGamepad:gamepad];
   }
}


- (void) os_finalize
{
}


- (void *) os_createStandardCursor:(UICursorStandardShape) shape
{
   assert( [NSThread mulleIsMainThread]);

   int   raylibCursor;

   switch( shape)
   {
   default                       : raylibCursor = MOUSE_CURSOR_DEFAULT; break;
   case UICursorTextInput        : raylibCursor = MOUSE_CURSOR_IBEAM; break;
   case UICursorDrag             : raylibCursor = MOUSE_CURSOR_POINTING_HAND; break;
   case UICursorHorizontalResize : raylibCursor = MOUSE_CURSOR_RESIZE_EW; break;
   case UICursorVerticalResize   : raylibCursor = MOUSE_CURSOR_RESIZE_NS; break;
   case UICursorDiagonalResize   : raylibCursor = MOUSE_CURSOR_RESIZE_NWSE; break;
   }

   // raylib uses SetMouseCursor with int enum, not opaque pointers.
   // Return the enum value cast to pointer for API compatibility.
   return( (void *) (uintptr_t) raylibCursor);
}


- (void *) os_createCursorWithBitmap:(struct CGBitmap) bitmap
                             hotSpot:(struct CGPixelPoint) hotSpot
{
   assert( [NSThread mulleIsMainThread]);
   // raylib does not support custom bitmap cursors
   return( NULL);
}


- (void) os_destroyCursor:(void *) cursor
{
   assert( [NSThread mulleIsMainThread]);
   // nothing to free — cursor is just an enum value
}


//
// rcore has no blocking wait. We approximate with WaitTime + PollInputEvents.
//
- (void) os_waitEventsWithTimeout:(mulle_relativetime_t) timeout
{
   assert( [NSThread mulleIsMainThread]);

   if( timeout > 0.0 && ! isinf( timeout))
      WaitTime( timeout);
   PollInputEvents();

   // rcore poll-diff: synthesize UIEvents from input state changes
   {
      id <UIWindow>    window;

      mulle_array_for( &_windows, window)
      {
         RCoreOSWindow  *osWindow = (RCoreOSWindow *) [window OSWindow];
         if( ! ([osWindow styleMask] & UIWindowStyleInputPolling))
            [osWindow synthesizeEventsFromInputState];
      }
   }
}


- (void) os_pollEvents
{
   assert( [NSThread mulleIsMainThread]);
   PollInputEvents();

   // rcore poll-diff: synthesize UIEvents from input state changes
   {
      id <UIWindow>    window;

      mulle_array_for( &_windows, window)
      {
         RCoreOSWindow  *osWindow = (RCoreOSWindow *) [window OSWindow];
         if( ! ([osWindow styleMask] & UIWindowStyleInputPolling))
            [osWindow synthesizeEventsFromInputState];
      }
   }
}


- (void) os_sendEmptyEvent
{
   // rcore has no mechanism to wake a sleeping event loop from another thread.
   // This is a no-op; MulleRCore only supports fixed framerate anyway.
}


- (void) os_pollGamepads
{
   RCoreOSGamepad   *gamepad;
   NSUInteger       i;

   assert( [NSThread mulleIsMainThread]);

   for( i = 0; i < 16; i++)
   {
      if( ! IsGamepadAvailable( (int) i))
         continue;
      gamepad = (RCoreOSGamepad *) [RCoreOSGamepad gamepadAtOSIndex:i];
      [gamepad os_pollGamepadInfo];
   }
}

@end
