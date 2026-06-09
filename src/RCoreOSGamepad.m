//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "RCoreOSGamepad.h"

#import "import-private.h"

#include "raylib.h"


@implementation RCoreOSGamepad

+ (NSUInteger) numberOfGamepads
{
   NSUInteger   n;
   int          i;

   n = 0;
   for( i = 0; i < 16; i++)
   {
      if( IsGamepadAvailable( i))
         n++;
   }
   return( n);
}


+ (id <UIGamepad>) gamepadAtOSIndex:(NSUInteger) i
{
   if( ! IsGamepadAvailable( (int) i))
      return( nil);
   return( [[[RCoreOSGamepad alloc] initWithOSGamepad:(void *) (uintptr_t) i] autorelease]);
}


+ (NSRange) osIndexRange
{
   return( NSMakeRange( 0, 16));
}


- (instancetype) initWithOSGamepad:(void *) handle
{
   _handle   = (int) (uintptr_t) handle;
   _infoLock = [NSLock new];
   return( self);
}


- (void) dealloc
{
   [_infoLock release];
   [super dealloc];
}


- (char *) nameUTF8String
{
   return( (char *) GetGamepadName( _handle));
}


- (char *) guidUTF8String
{
   return( "");  // raylib does not expose GUID
}


- (BOOL) isJoystick
{
   return( NO);  // raylib only exposes gamepad-mapped devices
}


- (NSInteger) osIndex
{
   return( _handle);
}


- (void) getGamepadInfo:(struct UIGamepadInfo *) info
{
   [_infoLock lock];
   *info = _info;
   [_infoLock unlock];
}


- (void) os_pollGamepadInfo
{
   int   i;

   assert( [NSThread mulleIsMainThread]);

   if( ! IsGamepadAvailable( _handle))
      return;

   [_infoLock lock];
   {
      _previousInfo = _info;
      memset( &_info, 0, sizeof( _info));

      _info.numberOfAxes    = 6;
      _info.numberOfButtons = 18;  // GAMEPAD_BUTTON_LEFT_TRIGGER_2 + 1
      _info.numberOfSticks  = 1;   // D-pad as digital stick

      for( i = 0; i < 6; i++)
         _info.axes[ i] = GetGamepadAxisMovement( _handle, i);

      for( i = 0; i < 18; i++)
         _info.buttons[ i] = IsGamepadButtonDown( _handle, i) ? 1 : 0;

      // D-pad as digital stick 0
      {
         CADirection   dir;

         dir = 0;
         if( IsGamepadButtonDown( _handle, GAMEPAD_BUTTON_LEFT_FACE_UP))
            dir = CADirectionUp;
         else if( IsGamepadButtonDown( _handle, GAMEPAD_BUTTON_LEFT_FACE_DOWN))
            dir = CADirectionDown;
         else if( IsGamepadButtonDown( _handle, GAMEPAD_BUTTON_LEFT_FACE_LEFT))
            dir = CADirectionLeft;
         else if( IsGamepadButtonDown( _handle, GAMEPAD_BUTTON_LEFT_FACE_RIGHT))
            dir = CADirectionRight;
         _info.sticks[ 0] = (unsigned char) dir;
      }
   }
   [_infoLock unlock];
}


- (char *) os_nameUTF8String
{
   return( (char *) GetGamepadName( _handle));
}


- (char *) os_guidUTF8String
{
   return( "");
}


- (CADirection) direction
{
   CADirection   dir;

   [_infoLock lock];
   dir = (CADirection) _info.sticks[ 0];
   [_infoLock unlock];
   return( dir);
}


- (BOOL) stateOfGamepadButton:(UIGamepadButton) button
{
   BOOL   state;

   [_infoLock lock];
   state = (button < UIGamepadInfoMaxButtons) ? _info.buttons[ button] : NO;
   [_infoLock unlock];
   return( state);
}


- (BOOL) getAnalogStickWithIndex:(NSUInteger) index
                            axes:(float [ 3]) axes
{
   if( index > 1)
      return( NO);

   [_infoLock lock];
   UIGamepadInfoGetAnalogStick( &_info, index, axes);
   [_infoLock unlock];
   return( YES);
}


- (BOOL) getDigitalStickWithIndex:(NSUInteger) index
                        direction:(CADirection *) direction
{
   if( index >= UIGamepadInfoMaxSticks)
      return( NO);

   [_infoLock lock];
   *direction = UIGamepadInfoGetDigitalStick( &_info, index);
   [_infoLock unlock];
   return( YES);
}

@end
