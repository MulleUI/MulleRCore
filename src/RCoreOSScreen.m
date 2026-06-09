//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "RCoreOSScreen.h"

#import "import-private.h"

#include "raylib.h"


@implementation RCoreOSScreen

+ (NSUInteger) numberOfScreens
{
   return( GetMonitorCount());
}


+ (id <UIScreen>) screenAtIndex:(NSUInteger) i
{
   if( (int) i >= GetMonitorCount())
      return( nil);
   return( [[[RCoreOSScreen alloc] initWithMonitorIndex:i] autorelease]);
}


- (instancetype) initWithMonitorIndex:(NSUInteger) index
{
   _monitorIndex = index;
   _infoLock     = [NSLock new];

   [self _updateInfo];
   return( self);
}


- (void) dealloc
{
   [_infoLock release];
   [super dealloc];
}


- (void) _updateInfo
{
   int   monitor;
   int   w, h;

   monitor = (int) _monitorIndex;

   w = GetMonitorWidth( monitor);
   h = GetMonitorHeight( monitor);

   _info.frame       = CGRectMake( GetMonitorPosition( monitor).x,
                                   GetMonitorPosition( monitor).y,
                                   w, h);
   _info.canvas      = _info.frame;
   _info.contentScale = CGVectorMake( 1.0, 1.0);
   _info.physicalSize = CGSizeMake( GetMonitorPhysicalWidth( monitor),
                                    GetMonitorPhysicalHeight( monitor));

   if( _info.physicalSize.width > 0.0)
      _info.dpi = (CGFloat) w / (_info.physicalSize.width / 25.4);
   else
      _info.dpi = 72.0;

   _info.refreshRate = 1.0 / GetMonitorRefreshRate( monitor);
}


- (char *) nameUTF8String
{
   return( (char *) GetMonitorName( (int) _monitorIndex));
}


- (void) getScreenInfo:(struct UIScreenInfo *) info
{
   [_infoLock lock];
   *info = _info;
   [_infoLock unlock];
}


- (CGRect) frame
{
   CGRect   rval;

   [_infoLock lock];
   rval = _info.frame;
   [_infoLock unlock];
   return( rval);
}


- (CGRect) canvas
{
   CGRect   rval;

   [_infoLock lock];
   rval = _info.canvas;
   [_infoLock unlock];
   return( rval);
}


- (mulle_relativetime_t) refreshRate
{
   mulle_relativetime_t   rval;

   [_infoLock lock];
   rval = _info.refreshRate;
   [_infoLock unlock];
   return( rval);
}


- (char *) os_nameUTF8String
{
   return( (char *) GetMonitorName( (int) _monitorIndex));
}


- (CGVector) os_contentScale
{
   return( CGVectorMake( 1.0, 1.0));
}


- (CGSize) os_physicalSize
{
   return( CGSizeMake( GetMonitorPhysicalWidth( (int) _monitorIndex),
                       GetMonitorPhysicalHeight( (int) _monitorIndex)));
}


- (CGFloat) os_dpi
{
   int   w;
   int   pw;

   w  = GetMonitorWidth( (int) _monitorIndex);
   pw = GetMonitorPhysicalWidth( (int) _monitorIndex);
   if( pw > 0)
      return( (CGFloat) w / ((CGFloat) pw / 25.4));
   return( 72.0);
}


- (CGPixelRect) os_canvas
{
   int   w, h;

   w = GetMonitorWidth( (int) _monitorIndex);
   h = GetMonitorHeight( (int) _monitorIndex);
   return( CGPixelRectMake( 0, 0, w, h));
}


- (CGPixelPoint) os_position
{
   Vector2   pos;

   pos = GetMonitorPosition( (int) _monitorIndex);
   return( CGPixelPointMake( (int) pos.x, (int) pos.y));
}


- (BOOL) os_isPrimaryScreen
{
   return( _monitorIndex == 0);
}

@end
