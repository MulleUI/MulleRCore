//
// main-rcore-input.m
//
// A raylib input demo running on MulleRCore.
// Draws a ball that follows the mouse, changes color on click.
//
#import "import-private.h"

#import "RCoreOSWindow.h"

#include "raylib.h"


static UIWindowDisplayBits  frameCallback( id <UIOSWindow> window)
{
   Vector2   mouse;
   Color     color;

   mouse = GetMousePosition();
   color = IsMouseButtonDown( MOUSE_BUTTON_LEFT) ? MAROON : DARKBLUE;

   ClearBackground( RAYWHITE);

   DrawCircleV( mouse, 40, color);
   DrawText( "Move the mouse - click to change color", 10, 10, 20, DARKGRAY);

   if( IsKeyDown( KEY_SPACE))
      DrawText( "SPACE held!", 10, 40, 20, RED);

   return( UIWindowDisplayNeedsAnimation);
}


int   main( int argc, char *argv[])
{
   RCoreOSWindow   *window;

   window = [RCoreOSWindow windowWithFrame:CGRectMake( 0, 0, 800, 450)
                           titleUTF8String:"MulleRCore - Input"
                                 styleMask:UIWindowStyleResizable];
   if( ! window)
      return( 1);

   [window setFrameCallback:frameCallback];
   [window setFrameRateHz:60.0];

   return( UIApplicationRunWindow( window));
}
