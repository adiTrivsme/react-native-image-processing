//
//  Utils.h
//  Pods
//
//  Created by apple on 09/03/26.
//

#import <CoreGraphics/CoreGraphics.h>
#import <array>
#import <jsi/jsi.h>

#import "Config.h"

using namespace facebook;

typedef struct {
    float r;
    float g;
    float b;
} RGBValues;


NSString *JSIStringToNSString(jsi::Runtime &rt, const jsi::String &str);

jsi::String nsStringToJSI(jsi::Runtime &rt, NSString *str);

NSArray *convertRGBJSIObjectToNSArray(jsi::Runtime &rt, const jsi::Object &obj);

CGRect ComputeDrawRect(size_t srcWidth,
                       size_t srcHeight,
                       size_t targetWidth,
                       size_t targetHeight,
                       ResizeStrategy strategy);


std::array<size_t, 3> GetOutIndicesAsPerTensorLayout(
    size_t x,
    size_t y,
    size_t width,
    size_t height,
    size_t channelCount,
    TensorLayout layout
);


RGBValues NormalizePixel(
    const uint8_t *pixel,
    Normalization normalization,
    AlphaHandling alphaHandling,
    const float *mean,
    const float *std
);


std::array<float, 3> rgbOrderAsPerColorFormat(
    ColorFormat colorFormat,
    RGBValues rgb
);


void ApplyExifOrientation(
    OrientationHandling orientationHandling,
    CGContextRef context,
    UIImageOrientation orientation,
    CGSize targetSize
);

void UpdateOutputBufferWithRGB(
   OutDType outDType,
   void *buffer,
   const size_t *pixelIndices,
   const float *rgbValues,
   int channelCount
);


size_t GetElementSize(
  OutDType outDType
);
