//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"


@interface RCoreOSGamepad : NSObject < UIGamepad>
{
   int                     _handle;
   struct UIGamepadInfo    _info;
   struct UIGamepadInfo    _previousInfo;
   NSLock                  *_infoLock;
}

+ (NSUInteger) numberOfGamepads;
+ (id <UIGamepad>) gamepadAtOSIndex:(NSUInteger) i;
+ (NSRange) osIndexRange;

- (instancetype) initWithOSGamepad:(void *) handle;

@property( readonly, dynamic) char   *nameUTF8String;
@property( readonly, dynamic) char   *guidUTF8String;
@property( readonly, dynamic) BOOL       isJoystick;
@property( readonly, dynamic) NSInteger  osIndex;

- (void) getGamepadInfo:(struct UIGamepadInfo *) info   MULLE_OBJC_THREADSAFE_METHOD;
- (void) os_pollGamepadInfo   MULLE_UI_MAIN_THREAD_ONLY;

- (char *) os_nameUTF8String  MULLE_UI_MAIN_THREAD_ONLY;
- (char *) os_guidUTF8String  MULLE_UI_MAIN_THREAD_ONLY;

@end
