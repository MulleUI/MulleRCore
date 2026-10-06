## 0.2.0



feature: add robust `add_subdirectory` and `find_package` consumption support

* `add_subdirectory` consumers now inherit include directories, dependency targets and build ordering, so a plain `target_link_libraries(` app PRIVATE MulleRCore) suffices
* installed `find_package(MulleRCore)` config resolves and re-exports dependencies by name, so consumers no longer get undefined symbols from unresolved dependencies
* force-link whole-archive requirement is propagated to consumers via an exported interface wrapper (cmake 3.24+)
* add `USE_DEPENDENCY_DIR` option; automatically disabled for `add_subdirectory` builds so no SDK/dependency directory is searched
* stage-2 library sources now inherit dependency usage requirements and wait for staged headers
* Windows executables embed a UTF-8 activeCodePage manifest by default


## 0.1.0




feature: add window style-mask helper and migrate demos to UIApplication run loop

* new +[RCoreOSWindow effectiveWindowStyleMask:graphicsHints:] class method for window style handling
* demo apps now run windows via [UIApplication sharedInstance] and [app runWindow:] instead of the UIApplicationRunWindow() function


### 0.0.1

Various small improvements
