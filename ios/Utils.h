//
//  Utils.h
//  Pods
//
//  Created by apple on 09/03/26.
//

#import <CoreGraphics/CoreGraphics.h>
#import <array>


typedef struct {
    float r;
    float g;
    float b;
} RGBValues;

typedef struct {
    CGColorSpaceRef colorSpace;
    CGBitmapInfo bitmapInfo;
    size_t bytesPerPixel;
} BitmapContextConfig;


CGRect ComputeDrawRect(size_t srcWidth,
                       size_t srcHeight,
                       size_t targetWidth,
                       size_t targetHeight,
                       NSString *strategy);


std::array<size_t, 3> GetOutIndicesAsPerTensorLayout(
    size_t x,
    size_t y,
    size_t width,
    size_t height,
    size_t channelCount,
    NSString *layout
);


RGBValues NormalizePixel(
    const uint8_t *pixel,
    NSString *normalization,
    NSString *alphaHandling,
    const NSArray *mean,
    const NSArray *std
);


std::array<float, 3> rgbOrderAsPerColorFormat(
    NSString *colorFormat,
    RGBValues rgb
);


void ApplyExifOrientation(
    NSString *orientationHandling,
    CGContextRef context,
    UIImageOrientation orientation,
    CGSize targetSize
);


BitmapContextConfig GetBitmapContextConfig(
    NSString *colorFormat,
    NSString *alphaHandling
);


void UpdateOutputBufferWithRGB(
   NSString *outDType,
   void *buffer,
   const size_t *pixelIndices,
   const float *rgbValues,
   int channelCount
);


size_t GetElementSize(
   NSString *outDType
);
