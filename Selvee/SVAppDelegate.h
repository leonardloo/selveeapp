//
//  SVAppDelegate.h
//  Selvee
//
//  Created by Leonard Loo on 12/9/14.
//  Copyright (c) 2014 Selvee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpeechKit/SpeechKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface SVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
- (void)setupSpeechKitConnection;


@end
