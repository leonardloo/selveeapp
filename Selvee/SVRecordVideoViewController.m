//
//  SVRecordVideoViewController.m
//  Selvee
//
//  Created by Leonard Loo on 12/9/14.
//  Copyright (c) 2014 Selvee. All rights reserved.
//

#import "SVRecordVideoViewController.h"
#import "DetectFace.h"

@interface SVRecordVideoViewController () <DetectFaceDelegate>

@property (strong, nonatomic) NSTimer *timerTXDelay;
@property (nonatomic) BOOL allowTX;

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (strong, nonatomic) IBOutlet UIImageView *outImageView;
@property (strong, nonatomic) DetectFace *detectFaceController;

@property (nonatomic, strong) UIImageView *hatImgView;
@property (nonatomic, strong) UIImageView *beardImgView;
@property (nonatomic, strong) UIImageView *mustacheImgView;


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
    
    self.allowTX = YES;
    
    // Watch Bluetooth connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionChanged:) name:RWT_BLE_SERVICE_CHANGED_STATUS_NOTIFICATION object:nil];
    
    // Start the Bluetooth discovery process
    [BTDiscovery sharedInstance];
    
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

#pragma mark - Bluetooth

- (void)connectionChanged:(NSNotification *)notification {
    // Connection status changed. Indicate on GUI.
    BOOL isConnected = [(NSNumber *) (notification.userInfo)[@"isConnected"] boolValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Set image based on connection status
        if (isConnected) {
            NSLog(@"Bluetooth is connected");
        } else {
            NSLog(@"Bluetooth is disconnected");
        }
    });
}

- (void)sendPosition:(uint8_t)position {
    // Valid position range: 0 to 180
    static uint8_t lastPosition = 255;
    
    if (!self.allowTX) { // 1
        return;
    }
    
    // Validate value
    if (position == lastPosition) { // 2
        return;
    }
    else if ((position < 0) || (position > 180)) { // 3
        return;
    }
    
    if ([BTDiscovery sharedInstance].bleService) { // 4
        [[BTDiscovery sharedInstance].bleService writePosition:position];
        lastPosition = position;
    }
    // Start delay timer
    self.allowTX = NO;
    if (!self.timerTXDelay) { // 5
        self.timerTXDelay = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerTXDelayElapsed) userInfo:nil repeats:NO];
    }
}

- (void)timerTXDelayElapsed {
    self.allowTX = YES;
    [self stopTimerTXDelay];
    
    // TODO: Change this to send the right positions depending on our commands
    [self sendPosition:(uint8_t)255];
}

- (void)stopTimerTXDelay {
    if (!self.timerTXDelay) {
        return;
    }
    
    [self.timerTXDelay invalidate];
    self.timerTXDelay = nil;
}


#pragma mark - Record video

//-(IBAction)recordAndPlay:(id)sender {
//    [self startCameraControllerFromViewController:self usingDelegate:self];
//}

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
        // TODO: Change this to parse the output text into commands

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
            // TODO: Got to fix the disappearance of beard etc. upon turning on again
            [self.previewView setHidden:YES];
            [self.detectFaceController stopDetection];
        } else if ([voiceResult rangeOfString:@"Picture" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            CIImage *outImage = self.detectFaceController.outputImage;

            
            CIContext *context = [CIContext contextWithOptions:nil];
            CGImageRef ref = [context createCGImage:outImage fromRect:outImage.extent];
            self.outImageView.image = [UIImage imageWithCGImage:ref scale:1.0 orientation:UIImageOrientationLeftMirrored];
            CGImageRelease(ref);
            
//            self.outImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCIImage:outImage]];
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
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                    message:[error localizedDescription]
//                                                   delegate:nil
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
}

#pragma mark - Facial Recognition

- (void)detectedFaceController:(DetectFace *)controller features:(NSArray *)featuresArray forVideoBox:(CGRect)clap withPreviewBox:(CGRect)previewBox
{
//    NSLog(@"YOOO %@", self.detectFaceController.outputImage);
    
//        self.outImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCIImage:self.detectFaceController.outputImage]];

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
    
    for (CIFaceFeature *ff in featuresArray) {
        // find the correct position for the square layer within the previewLayer
        // the feature box originates in the bottom left of the video frame.
        // (Bottom right if mirroring is turned on)
        CGRect faceRect = [ff bounds];
        
        //isMirrored because we are using front camera
        faceRect = [DetectFace convertFrame:faceRect previewBox:previewBox forVideoBox:clap isMirrored:YES];
        
        // TODO: Might have to check relative to screen/previewView mid
        
//        NSLog(@"previewView mid: %f, %f", self.previewView.frame.origin.x, self.previewView.frame.origin.y);
//        NSLog(@"faceRect: %f, %f", faceRect.origin.x, faceRect.origin.y);
        
        if (faceRect.origin.x > 150) {
            // TODO: Turn left
        } else if (faceRect.origin.x < 30) {
            // TODO: Turn right
        }
        
        // TODO: Turn up and down
        
        
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
