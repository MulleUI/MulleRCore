//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "RCoreOSWindow+UIEvent.h"

#import "import-private.h"

#import <MulleUIApplication/UIOSWindow+DebugPrivate.h>

#include "raylib.h"


#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"


@implementation RCoreOSWindow ( UIEvent)

- (void) os_initEvents
{
}


- (void) os_finalizeEvents
{
}


- (void) updateWindowInfo
{
   struct CGWindowInfo   info;

   info = CGWindowInfoSFMakeVector( [self os_windowFrame],
                                    [self os_framebufferSize],
                                    [self os_UIScale]);
   [_windowInfoLock lock];
   {
      _windowInfo.base        = info;
      _windowInfo.refreshRate = 1.0 / GetMonitorRefreshRate( GetCurrentMonitor());
      if( _windowInfo.refreshRate == 0.0)
         _windowInfo.refreshRate = UIScreenAssumedRefreshRate;
   }
   [_windowInfoLock unlock];
}


//
// Poll-diff: read current rcore input state, compare to previous frame,
// emit UIEvents for detected changes. Called once per frame after
// PollInputEvents().
//
- (void) synthesizeEventsFromInputState
{
   struct UIInputState   current;
   struct UIInputState   previous;
   NSUInteger            changedButtons;
   NSUInteger            bit;
   float                 wheel;

   assert( [NSThread mulleIsMainThread]);

   [self os_pollInputState:&current];

   NSLockingDo( _inputStateLock)
   {
      previous    = _inputState;
      _inputState = current;
   }

   // --- Mouse movement ---
   if( current.locationInWindow.x != previous.locationInWindow.x ||
       current.locationInWindow.y != previous.locationInWindow.y)
   {
      UIOSWindowMouseMotionEventLog( "%.1f, %.1f",
         current.locationInWindow.x, current.locationInWindow.y);
      if( ! shouldDiscardEvent( self, UIEventTypeMotion))
      {
         UIEvent   *event;

         event = [[UIMouseMotionEvent alloc] initWithInputState:&current];
         _otherRetainedEventsCallback( self, event);
      }
   }

   // --- Mouse buttons ---
   changedButtons = current.buttonStates ^ previous.buttonStates;
   if( changedButtons)
   {
      if( ! shouldDiscardEvent( self, UIEventTypeTouches))
      {
         for( bit = 1; bit <= (1 << 4); bit <<= 1)
         {
            if( changedButtons & bit)
            {
               UIEvent      *event;
               NSUInteger   action;

               action = (current.buttonStates & bit)
                           ? UIEventButtonActionDown
                           : UIEventButtonActionUp;
               event = [[UIMouseButtonEvent alloc] initWithInputState:&current
                                                              button:bit
                                                              action:action];
               _otherRetainedEventsCallback( self, event);
            }
         }
      }
   }

   // --- Scroll wheel ---
   wheel = GetMouseWheelMove();
   if( wheel != 0.0f)
   {
      _scrollWheelDelta += wheel;

      if( ! shouldDiscardEvent( self, UIEventTypeScroll))
      {
         UIEvent   *event;
         CGPoint   scrollOffset;
         CGFloat   sensitivity;

         sensitivity = _scrollWheelSensitivity;
         scrollOffset = CGPointMake( 0.0, wheel * sensitivity);

         event = [[UIMouseScrollEvent alloc] initWithInputState:&current
                                                  scrollOffset:scrollOffset];
         _otherRetainedEventsCallback( self, event);
      }
   }

   // --- Keyboard (poll-diff) ---
   if( ! shouldDiscardEvent( self, UIEventTypePresses))
   {
      NSUInteger   i;

      // Check for newly pressed keys
      for( i = 0; i < current.keyStates._count; i++)
      {
         NSUInteger   key;
         NSUInteger   j;
         BOOL         wasDown;

         key     = current.keyStates._keys[ i];
         wasDown = NO;
         for( j = 0; j < previous.keyStates._count; j++)
         {
            if( previous.keyStates._keys[ j] == key)
            {
               wasDown = YES;
               break;
            }
         }
         if( ! wasDown)
         {
            UIEvent  *event;

            UIOSWindowEventLog( "key down: %ld", (long) key);
            event = [[UIKeyboardEvent alloc] initWithInputState:&current
                                                           key:key
                                                      scanCode:key
                                                        action:UIEventButtonActionDown
                                                     isARepeat:NO];
            _otherRetainedEventsCallback( self, event);
         }
      }

      // Check for newly released keys
      for( i = 0; i < previous.keyStates._count; i++)
      {
         NSUInteger   key;
         NSUInteger   j;
         BOOL         isStillDown;

         key         = previous.keyStates._keys[ i];
         isStillDown = NO;
         for( j = 0; j < current.keyStates._count; j++)
         {
            if( current.keyStates._keys[ j] == key)
            {
               isStillDown = YES;
               break;
            }
         }
         if( ! isStillDown)
         {
            UIEvent  *event;

            event = [[UIKeyboardEvent alloc] initWithInputState:&current
                                                           key:key
                                                      scanCode:key
                                                        action:UIEventButtonActionUp
                                                     isARepeat:NO];
            _otherRetainedEventsCallback( self, event);
         }
      }
   }

   // --- Window events (check for resize/close) ---
   {
      CGPixelSize   fbSize;

      fbSize = [self os_framebufferSize];
      if( fbSize.width != _windowInfo.base.framebufferSize.width ||
          fbSize.height != _windowInfo.base.framebufferSize.height)
      {
         UIWindowEvent   *event;

         event = [[[UIWindowFramebufferResizeEvent alloc] initWithSize:fbSize] autorelease];
         _uninitializedFramebuffer = YES;
         _windowEventsCallback( self, event);
      }

      [self updateWindowInfo];
   }

   if( WindowShouldClose())
   {
      UIWindowEvent   *event;

      event = [[[UIWindowCloseEvent alloc] init] autorelease];
      _windowEventsCallback( self, event);
   }
}


static inline int   shouldDiscardEvent( RCoreOSWindow *self, NSUInteger eventType)
{
   NSUInteger   mask;

   mask = (NSUInteger) _mulle_atomic_pointer_read( &self->_discardEventsMask);
   return( mask & eventType);
}

@end
