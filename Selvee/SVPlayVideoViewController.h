//
//  SVPlayVideoViewController.h
//  Selvee
//
//  Created by Leonard Loo on 12/9/14.
//  Copyright (c) 2014 Selvee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface SVPlayVideoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// Play video methods
-(BOOL)startMediaBrowserFromViewController:(UIViewController*)controller usingDelegate:(id )delegate;
- (IBAction)playVideo:(id)sender;



@end
