//
//  DetectFace.h
//  Selvee
//
//  Created by Leonard Loo on 13/9/14.
//  Copyright (c) 2014 Selvee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class DetectFace;
@protocol DetectFaceDelegate <NSObject>
- (void)detectedFaceController:(DetectFace *)controller features:(NSArray *)featuresArray forVideoBox:(CGRect)clap withPreviewBox:(CGRect)previewBox;
@end

@interface DetectFace : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) CIImage *outputImage;
@property (nonatomic, strong) UIImageView *outputImageView;

- (void)startDetection;
- (void)stopDetection;

+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize;
+ (CGRect)convertFrame:(CGRect)originalFrame previewBox:(CGRect)previewBox forVideoBox:(CGRect)videoBox isMirrored:(BOOL)isMirrored;

@end
