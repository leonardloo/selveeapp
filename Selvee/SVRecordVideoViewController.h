//
//  SVRecordVideoViewController.h
//  Selvee
//
//  Created by Leonard Loo on 12/9/14.
//  Copyright (c) 2014 Selvee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <SpeechKit/SpeechKit.h>
#import "SVAppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <FacebookSDK/FacebookSDK.h>

@interface SVRecordVideoViewController : UIViewController <SpeechKitDelegate, SKRecognizerDelegate>

@property (strong, nonatomic) SVAppDelegate *appDelegate;

// Record video
-(BOOL)startCameraControllerFromViewController:(UIViewController*)controller
                                 usingDelegate:(id )delegate;
-(void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void*)contextInfo;

// Voice Recognizer
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) SKRecognizer* voiceSearch;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
- (IBAction)recordButtonTapped:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *testLabel;



@end
