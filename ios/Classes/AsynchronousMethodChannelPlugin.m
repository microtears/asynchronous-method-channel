#import "AsynchronousMethodChannelPlugin.h"
#import <asynchronous_method_channel/asynchronous_method_channel-Swift.h>

@implementation AsynchronousMethodChannelPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAsynchronousMethodChannelPlugin registerWithRegistrar:registrar];
}
@end
