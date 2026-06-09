//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"


@interface RCoreOSScreen : NSObject < UIScreen>
{
   NSUInteger             _monitorIndex;
   struct UIScreenInfo    _info;
   NSLock                 *_infoLock;
}

+ (NSUInteger) numberOfScreens;
+ (id <UIScreen>) screenAtIndex:(NSUInteger) i;

- (instancetype) initWithMonitorIndex:(NSUInteger) index;

@property( readonly, dynamic) char   *nameUTF8String   MULLE_OBJC_THREADSAFE_METHOD;

- (void) getScreenInfo:(struct UIScreenInfo *) info   MULLE_OBJC_THREADSAFE_METHOD;

- (CGRect) frame                                MULLE_OBJC_THREADSAFE_METHOD;
- (CGRect) canvas                               MULLE_OBJC_THREADSAFE_METHOD;
- (mulle_relativetime_t) refreshRate            MULLE_OBJC_THREADSAFE_METHOD;

- (char *) os_nameUTF8String;
- (CGVector) os_contentScale;
- (CGSize) os_physicalSize;
- (CGFloat) os_dpi;
- (CGPixelRect) os_canvas;
- (CGPixelPoint) os_position;

- (BOOL) os_isPrimaryScreen;

@end
