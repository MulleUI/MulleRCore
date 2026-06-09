//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "RCoreOSWindow.h")
#  import "RCoreOSWindow.h"
# endif
#endif

#import "import.h"


@interface RCoreOSWindow ( UIEvent)

- (void) os_initEvents;
- (void) os_finalizeEvents;

- (void) updateWindowInfo;

// Called once per frame after PollInputEvents(). Reads current rcore input
// state, diffs against previous frame, emits UIEvents via callbacks.
- (void) synthesizeEventsFromInputState;

@end
