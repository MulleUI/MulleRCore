## 0.1.0




feature: add window style-mask helper and migrate demos to UIApplication run loop

* new +[RCoreOSWindow effectiveWindowStyleMask:graphicsHints:] class method for window style handling
* demo apps now run windows via [UIApplication sharedInstance] and [app runWindow:] instead of the UIApplicationRunWindow() function


### 0.0.1

Various small improvements
