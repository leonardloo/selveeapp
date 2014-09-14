//
//  SVRecordVideoViewController.m
//  Selvee
//
//  Created by Leonard Loo on 12/9/14.
//  Copyright (c) 2014 Selvee. All rights reserved.
//

#import "SVRecordVideoViewController.h"
#import "DetectFace.h"

@interface SVRecordVideoViewController () <DetectFaceDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSTimer *timerTXDelay;
@property (nonatomic) BOOL allowTX;

@property (weak, nonatomic) IBOutlet UIImageView *previewView;
@property (strong, nonatomic) IBOutlet UIImageView *outImageView;
@property (strong, nonatomic) DetectFace *detectFaceController;

@property (nonatomic, strong) UIImageView *hatImgView;
@property (nonatomic, strong) UIImageView *beardImgView;
@property (nonatomic, strong) UIImageView *mustacheImgView;
@property (nonatomic, strong) UIImageView *bieberImgView;



@end

@implementation SVRecordVideoViewController

const unsigned char SpeechKitApplicationKey[] = {0x66, 0xe9, 0x5b, 0x9a, 0x2c, 0x8a, 0xb8, 0x4e, 0xb7, 0x79, 0x21, 0x30, 0x1d, 0x16, 0xa6, 0x2a, 0x05, 0x63, 0xb6, 0xcc, 0x6b, 0x30, 0x11, 0xf1, 0xbf, 0x49, 0xa3, 0x0b, 0x6e, 0xf4, 0xea, 0xd4, 0xdd, 0x45, 0x6e, 0x0a, 0xd0, 0x27, 0x58, 0x87, 0xa0, 0x79, 0xb7, 0xbe, 0x90, 0x5e, 0xe8, 0x95, 0xc1, 0x9e, 0x61, 0x2d, 0xce, 0x73, 0x1e, 0x8d, 0xbc, 0xc1, 0x98, 0x2a, 0xb5, 0x82, 0xff, 0x93};

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.activityIndicator.hidden = YES;
    self.messageLabel.text = @"Tap on the mic";
    
    self.appDelegate = (SVAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.appDelegate setupSpeechKitConnection];
    
    // Initiate facial recognition variables
    self.detectFaceController = [[DetectFace alloc] init];
    self.detectFaceController.delegate = self;
    self.detectFaceController.previewView = self.previewView;

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillUnload
{
    [self.detectFaceController stopDetection];
    [super viewWillUnload];
}

- (void)viewDidUnload {
    [self setPreviewView:nil];
    [super viewDidUnload];
}

#pragma mark - Record video

-(BOOL)startCameraControllerFromViewController:(UIViewController*)controller
                                 usingDelegate:(id )delegate {
    // 1 - Validattions
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil)) {
        return NO;
    }
    // 2 - Get image picker
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    // Displays a control that allows the user to choose movie capture
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = delegate;
    // 3 - Display image picker
    [controller presentViewController:cameraUI animated:YES completion:nil];
    return YES;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    [self dismissViewControllerAnimated:NO completion:nil];
    // Handle a movie capture
    if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSString *moviePath = [[info objectForKey:UIImagePickerControllerMediaURL] path];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath)) {
            UISaveVideoAtPathToSavedPhotosAlbum(moviePath, self,
                                                @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
    }
}

-(void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

# pragma mark - Voice recognizer

- (IBAction)recordButtonTapped:(id)sender {
    self.recordButton.selected = !self.recordButton.isSelected;
    
    // This will initialize a new speech recognizer instance
    if (self.recordButton.isSelected) {
        
        
        self.voiceSearch = [[SKRecognizer alloc] initWithType:SKSearchRecognizerType
                                                    detection:SKShortEndOfSpeechDetection
                                                     language:@"en_US"
                                                     delegate:self];
    }
    
    // This will stop existing speech recognizer processes
    else {
        if (self.voiceSearch) {
            [self.voiceSearch stopRecording];
            [self.voiceSearch cancel];
        }
    }
}

# pragma mark - SKRecognizer Delegate Methods

- (void)recognizerDidBeginRecording:(SKRecognizer *)recognizer {
    self.messageLabel.text = @"Listening..";
}

- (void)recognizerDidFinishRecording:(SKRecognizer *)recognizer {
    self.messageLabel.text = @"Done Listening..";
}


- (void)recognizer:(SKRecognizer *)recognizer didFinishWithResults:(SKRecognition *)results {
    long numOfResults = [results.results count];
    
    if (numOfResults > 0) {
        // Logs the best result from SpeechKit
        NSString *voiceResult = [results firstResult];
        
        if ([[voiceResult uppercaseString] isEqualToString:@"RECORD"]) {
            // Start recording video
            [self startCameraControllerFromViewController:self usingDelegate:self];
        } else if ([voiceResult rangeOfString:@"Face on" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            // Start recording video
            [self.previewView setHidden:NO];
            [self.detectFaceController startDetection];
        } else if ([voiceResult rangeOfString:@"Face off" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            // Stop recording video
            [self.previewView setHidden:YES];
            [self.detectFaceController stopDetection];
        } else if ([voiceResult rangeOfString:@"Snap" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            // Resets the image
            for (UIView *subView in [self.outImageView subviews]) {
                [subView removeFromSuperview];
            }
            
            CIImage *outImage = self.detectFaceController.outputImage;
            CIContext *context = [CIContext contextWithOptions:nil];
            CGImageRef ref = [context createCGImage:outImage fromRect:outImage.extent];
            self.outImageView.image = [UIImage imageWithCGImage:ref scale:1.0 orientation:UIImageOrientationLeftMirrored];
            CGImageRelease(ref);
            
            // TODO: Got to optimize the layering
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(305, 305), YES, 1);
            
            [self.previewView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            const CGFloat colorMasking[6] = {0.05, 1., 0.05, 1., 0.05, 1.0};
            CGImageRef imageRef = CGImageCreateWithMaskingColors(overlayImage.CGImage, colorMasking);
            UIImage *maskedImage = [UIImage imageWithCGImage:imageRef];
            UIImageView *maskedImageView = [[UIImageView alloc] initWithImage:maskedImage];
            maskedImageView.frame = CGRectMake(0, 0, self.outImageView.frame.size.width, self.outImageView.frame.size.height);
            
            for (UIView *subView in [self.previewView subviews]) {
                [subView removeFromSuperview];
            }
            
            [self.outImageView addSubview:maskedImageView];
            

            
            [self.previewView setAlpha:0.4f];
            
            //fade in
            [UIView animateWithDuration:1.5f animations:^{
                
                [self.previewView setAlpha:1.0f];
                
            } completion:^(BOOL finished) {
                
            }];
            
//            UIGraphicsBeginImageContextWithOptions(self.outImageView.bounds.size, YES, [[UIScreen mainScreen] scale]);
//            [self.outImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
//            UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
//            UIGraphicsEndImageContext();
//            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
            
            
        } else if ([voiceResult rangeOfString:@"Remove" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            for (UIView *subView in [self.previewView subviews]) {
                [subView removeFromSuperview];
            }
        } else if ([voiceResult rangeOfString:@"One" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                   [voiceResult rangeOfString:@"1" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            for (UIView *subView in [self.previewView subviews]) {
                [subView removeFromSuperview];
            }
            [self.previewView addSubview:self.mustacheImgView];
            [self.previewView addSubview:self.beardImgView];
            [self.previewView addSubview:self.hatImgView];
        } else if ([voiceResult rangeOfString:@"Two" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                   [voiceResult rangeOfString:@"2" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            for (UIView *subView in [self.previewView subviews]) {
                [subView removeFromSuperview];
            }
            [self.previewView addSubview:self.bieberImgView];
        } else if ([voiceResult rangeOfString:@"Save" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            UIGraphicsBeginImageContextWithOptions(self.outImageView.bounds.size, YES, [[UIScreen mainScreen] scale]);
            [self.outImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
            [[[UIAlertView alloc] initWithTitle:@"" message:@"Image successfully saved!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        } else if ([voiceResult rangeOfString:@"Share" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            // TODO: Facebook share
            UIGraphicsBeginImageContextWithOptions(self.outImageView.bounds.size, YES, [[UIScreen mainScreen] scale]);
            [self.outImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            FBPhotoParams *params = [[FBPhotoParams alloc] init];
            
            // Note that params.photos can be an array of images.  In this example
            // we only use a single image, wrapped in an array.
            params.photos = @[img];
            
            [FBDialogs presentShareDialogWithPhotoParams:params
                                             clientState:nil
                                                 handler:^(FBAppCall *call,
                                                           NSDictionary *results,
                                                           NSError *error) {
                                                     if (error) {
                                                         NSLog(@"Error: %@",
                                                               error.description);
                                                     } else {
                                                         NSLog(@"Success!");
                                                     }
                                                 }];
        }

        self.testLabel.text = voiceResult;
        self.testLabel.adjustsFontSizeToFitWidth = YES;
    }
    // Stops current voice search and init another one
    if (self.voiceSearch) {
        [self.voiceSearch stopRecording];
        [self.voiceSearch cancel];
    }
    self.voiceSearch = [[SKRecognizer alloc] initWithType:SKSearchRecognizerType
                                                detection:SKShortEndOfSpeechDetection
                                                 language:@"en_US"
                                                 delegate:self];

}


- (void)recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion {
    self.recordButton.selected = NO;
    self.messageLabel.text = @"Tap on the Mic";
    self.activityIndicator.hidden = YES;
}

#pragma mark - Facial Recognition

- (void)detectedFaceController:(DetectFace *)controller features:(NSArray *)featuresArray forVideoBox:(CGRect)clap withPreviewBox:(CGRect)previewBox
{

    if (!self.beardImgView) {
        self.beardImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"beard"]];
        self.beardImgView.contentMode = UIViewContentModeScaleToFill;
        [self.previewView addSubview:self.beardImgView];
    }
    
    if (!self.mustacheImgView) {
        self.mustacheImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mustache"]];
        self.mustacheImgView.contentMode = UIViewContentModeScaleToFill;
        [self.previewView addSubview:self.mustacheImgView];
    }
    
    if (!self.hatImgView) {
        self.hatImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"christmas_hat"]];
        self.hatImgView.contentMode = UIViewContentModeScaleToFill;
        [self.previewView addSubview:self.hatImgView];
    }
    
    if (!self.bieberImgView) {
        self.bieberImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"justin_bieber"]];
        self.bieberImgView.contentMode = UIViewContentModeScaleToFill;
//        [self.previewView addSubview:self.bieberImgView];
        
    }
    
    for (CIFaceFeature *ff in featuresArray) {
        // find the correct position for the square layer within the previewLayer
        // the feature box originates in the bottom left of the video frame.
        // (Bottom right if mirroring is turned on)
        CGRect faceRect = [ff bounds];
        
        //isMirrored because we are using front camera
        faceRect = [DetectFace convertFrame:faceRect previewBox:previewBox forVideoBox:clap isMirrored:YES];
        

        NSString *baseURLString = @"http://54.68.213.19/testapp/";
        
        // Assemble the string
        
        NSString *xString = @"0,";
        NSString *yString = @"0";
        
        if (faceRect.origin.x > 130) {
            NSLog(@"Turned left slow");
            xString = @"-1,";
        } else if (faceRect.origin.x > 160) {
            NSLog(@"Turned left fast");
            xString = @"-2,";
        } else if (faceRect.origin.x < 70) {
            NSLog(@"Turned right slow");
            xString = @"1,";
        } else if (faceRect.origin.x < 40) {
            NSLog(@"Turned right fast");
            xString = @"2,";
        }
        
        if (faceRect.origin.y > 140) {
            NSLog(@"Turned up");
            yString = @"1";
        } else if (faceRect.origin.y < 60) {
            NSLog(@"Turned down");
            yString = @"-1";
        }
        
        NSString *tupleString = [xString stringByAppendingString:yString];
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:[baseURLString stringByAppendingString:tupleString]]
                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval:60.0];
        NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        
        
        float hat_width = 290.0;
        float hat_height = 360.0;
        float head_start_y = 150.0; //part of hat image is transparent
        float head_start_x = 78.0;
        
        float width = faceRect.size.width * (hat_width / (hat_width - head_start_x));
        float height = width * hat_height/hat_width;
        float y = faceRect.origin.y - (height * head_start_y) / hat_height;
        float x = faceRect.origin.x - (head_start_x * width/hat_width);
        [self.hatImgView setFrame:CGRectMake(x, y, width, height)];
        
        float beard_width = 192.0;
        float beard_height = 171.0;
        width = faceRect.size.width * 0.6;
        height = width * beard_height/beard_width;
        y = faceRect.origin.y + faceRect.size.height - (80 * height/beard_height);
        x = faceRect.origin.x + (faceRect.size.width - width)/2;
        [self.beardImgView setFrame:CGRectMake(x, y, width, height)];
        
        
        width = faceRect.size.width;
        height = faceRect.size.height;
        y = faceRect.origin.y;
        x = faceRect.origin.x;
        [self.bieberImgView setFrame:CGRectMake(x, y, width, height)];
        
        float mustache_width = 212.0;
        float mustache_height = 58.0;
        width = faceRect.size.width * 0.9;
        height = width * mustache_height/mustache_width;
        y = y - height + 5;
        x = faceRect.origin.x + (faceRect.size.width - width)/2;
        [self.mustacheImgView setFrame:CGRectMake(x, y, width, height)];
    }
}

@end
