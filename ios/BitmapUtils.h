//
//  BitmapUtils.h
//  Pods
//
//  Created by apple on 16/03/26.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <jsi/jsi.h>

#import "Config.h"

using namespace facebook;

typedef struct {
    int inputWidth;
    int inputHeight;

    ColorFormat colorFormat;
    Normalization normalization;
    OutDType outDType;
    ResizeStrategy resizeStrategy;
    TensorLayout tensorLayout;
    OrientationHandling orientationHandling;
    AlphaHandling alphaHandling;

    int channelCount;

    float mean[3];
    float std[3];
    bool hasMeanStd;

} ImageProcessingConfig;

typedef struct {
    CGColorSpaceRef colorSpace;
    CGBitmapInfo bitmapInfo;
    size_t bytesPerPixel;
} BitmapContextConfig;


ImageProcessingConfig BuildImageProcessingConfig(
    jsi::Runtime &rt,
    const jsi::Object &options
);

BitmapContextConfig GetBitmapContextConfig(
    NSString *colorFormat,
    NSString *alphaHandling
);

CGContextRef CreateBitmapContext(ImageProcessingConfig config);

void DrawImageIntoContext(UIImage *image, CGContextRef context, ImageProcessingConfig config);

void *FillTensorFromBitmapContext(CGContextRef context, ImageProcessingConfig config);
