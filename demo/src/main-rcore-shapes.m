//
// main-rcore-shapes.m
//
// A raylib "basic shapes" demo running on top of MulleRCore.
// This is essentially raylib's core_basic_window example adapted to use
// RCoreOSWindow for window creation and event handling.
//
#import "import-private.h"

#import "RCoreOSWindow.h"

#include "raylib.h"


static UIWindowDisplayBits  frameCallback( id <UIOSWindow> window)
{
   ClearBackground( RAYWHITE);

   DrawText( "Congrats! You created your first window!", 190, 200, 20, LIGHTGRAY);

   DrawRectangle( 100, 300, 200, 80, RED);
   DrawRectangleLines( 100, 300, 200, 80, MAROON);

   DrawCircle( 500, 340, 50, BLUE);
   DrawCircleLines( 500, 340, 50, DARKBLUE);

   DrawLine( 100, 420, 700, 420, DARKGRAY);

   DrawTriangle( (Vector2){ 400, 100 },
                 (Vector2){ 350, 180 },
                 (Vector2){ 450, 180 },
                 GREEN);

   DrawFPS( 10, 10);

   return( UIWindowDisplayNeedsAnimation);
}


int   main( int argc, char *argv[])
{
   RCoreOSWindow   *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   window = [RCoreOSWindow windowWithFrame:CGRectMake( 0, 0, 800, 450)
                           titleUTF8String:"MulleRCore - Basic Shapes"
                                 styleMask:UIWindowStyleResizable];
   if( ! window)
      return( 1);

   [window setFrameCallback:frameCallback];
   [window setFrameRateHz:60.0];

   return( [app runWindow:window]);
}
