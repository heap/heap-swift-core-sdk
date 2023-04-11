//
//  AppDelegate.m
//  SwiftCoreiOSExample-ObjC
//
//  Created by Brian Nickel on 3/1/23.
//

#import <UIKit/UIKit.h>
@import HeapSwiftCore;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, nullable) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    Heap.sharedInstance.logLevel = HeapLogLevelDebug;
    [Heap.sharedInstance startRecording:@"11"];
    return YES;
}

@end
