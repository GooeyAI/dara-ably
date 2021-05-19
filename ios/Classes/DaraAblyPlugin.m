#import "DaraAblyPlugin.h"
#if __has_include(<dara_ably/dara_ably-Swift.h>)
#import <dara_ably/dara_ably-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "dara_ably-Swift.h"
#endif

@implementation DaraAblyPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDaraAblyPlugin registerWithRegistrar:registrar];
}
@end
