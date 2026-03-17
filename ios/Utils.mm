//
//  Utils.mm
//  Pods
//
//  Created by apple on 09/03/26.
//

#import "Utils.h"
#import "Config.h"

#import <CoreGraphics/CoreGraphics.h>
#import <jsi/jsi.h>

using namespace facebook;

NSString *JSIStringToNSString(jsi::Runtime &rt, const jsi::String &str) {
  return [NSString stringWithUTF8String:str.utf8(rt).c_str()];
}

jsi::String nsStringToJSI(jsi::Runtime &rt, NSString *str) {
  return jsi::String::createFromUtf8(rt, str.UTF8String);
}

NSArray *convertRGBJSIObjectToNSArray(jsi::Runtime &rt, const jsi::Object &obj) {
  NSNumber *r = @(obj.getProperty(rt, "r").asNumber());
  NSNumber *g = @(obj.getProperty(rt, "g").asNumber());
  NSNumber *b = @(obj.getProperty(rt, "b").asNumber());
  return @[r, g, b];
}

CGRect ComputeDrawRect(size_t srcWidth,
                       size_t srcHeight,
                       size_t targetWidth,
                       size_t targetHeight,
                       ResizeStrategy strategy)
{
    CGFloat widthRatio  = (CGFloat)targetWidth / srcWidth;
    CGFloat heightRatio = (CGFloat)targetHeight / srcHeight;

    // stretch
    if (strategy == ResizeStrategyStretch) {
        return CGRectMake(0, 0, targetWidth, targetHeight);
    }

    // aspectFit
    if (strategy == ResizeStrategyAspectFit) {
        CGFloat scale = MIN(widthRatio, heightRatio);

        CGFloat drawWidth  = srcWidth * scale;
        CGFloat drawHeight = srcHeight * scale;

        return CGRectMake(
            (targetWidth  - drawWidth)  / 2.0,
            (targetHeight - drawHeight) / 2.0,
            drawWidth,
            drawHeight
        );
    }

    // aspectFill/centerCrop
    CGFloat scale = MAX(widthRatio, heightRatio);

    CGFloat drawWidth  = srcWidth * scale;
    CGFloat drawHeight = srcHeight * scale;

    return CGRectMake(
        (targetWidth  - drawWidth)  / 2.0,
        (targetHeight - drawHeight) / 2.0,
        drawWidth,
        drawHeight
    );
}


std::array<size_t, 3> GetOutIndicesAsPerTensorLayout(
    size_t x,
    size_t y,
    size_t width,
    size_t height,
    size_t channelCount,
    TensorLayout layout
) {
    std::array<size_t, 3> indices;

    BOOL isNCHW = layout == TensorLayoutNCHW;

    if (isNCHW) {

        size_t hwIndex = y * width + x;
        size_t planeSize = width * height;

        indices[0] = 0 * planeSize + hwIndex;
        indices[1] = 1 * planeSize + hwIndex;
        indices[2] = 2 * planeSize + hwIndex;

    } else {

        size_t baseIndex = (y * width * channelCount) + (x * channelCount);

        indices[0] = baseIndex + 0;
        indices[1] = baseIndex + 1;
        indices[2] = baseIndex + 2;
    }

    return indices;
}


RGBValues NormalizePixel(
    const uint8_t *pixel,
    Normalization normalization,
    AlphaHandling alphaHandling,
    const float *mean,
    const float *std
) {
    float rf = (float)pixel[0];
    float gf = (float)pixel[1];
    float bf = (float)pixel[2];
  
    uint8_t a = pixel[3];
  
    // ---------- Alpha Handling ----------
    if (alphaHandling == AlphaHandlingPremultiply) {
        float af = a / 255.0f;

        rf *= af;
        gf *= af;
        bf *= af;
    }

    if (normalization == NormalizationZeroToOne) {
        rf /= 255.0f;
        gf /= 255.0f;
        bf /= 255.0f;
    } else if (normalization == NormalizationMinusOneToOne) {
        rf = (rf / 127.5f) - 1.0f;
        gf = (gf / 127.5f) - 1.0f;
        bf = (bf / 127.5f) - 1.0f;
    } else if (normalization == NormalizationMeanStd && mean && std) {
        rf = ((rf / 255.0f) - mean[0]) / std[0];
        gf = ((gf / 255.0f) - mean[1]) / std[1];
        bf = ((bf / 255.0f) - mean[2]) / std[2];
    }

    return {rf, gf, bf};
}


std::array<float, 3> rgbOrderAsPerColorFormat(
    ColorFormat colorFormat,
    RGBValues rgb
)
{
  std::array<float, 3> rgbOrder;
  
  BOOL isRGB  = colorFormat == ColorFormatRGB;
  BOOL isBGR  = colorFormat == ColorFormatBGR;
  BOOL isGRAY = colorFormat == ColorFormatGrayscale;
  
  float r = rgb.r;
  float g = rgb.g;
  float b = rgb.b;

  if (isRGB) {
   rgbOrder[0] = rgb.r;
   rgbOrder[1] = rgb.g;
   rgbOrder[2] = rgb.b;
  }
  else if (isBGR) {
    rgbOrder[0] = rgb.b;
    rgbOrder[1] = rgb.g;
    rgbOrder[2] = rgb.r;
  }
  else if (isGRAY) {
    float gray = (0.299f * r) + (0.587f * g) + (0.114f * b);
    rgbOrder[0] = gray;
  }
  
  return rgbOrder;
}


void UpdateOutputBufferWithRGB(
   OutDType outDType,
   void *buffer,
   const size_t *pixelIndices,
   const float *rgbValues,
   int channelCount
)
{
  if (outDType == OutDTypeFloat32) {
    float *buf = (float *)buffer;
    
    for (int c = 0; c < channelCount; c++) {
      buf[pixelIndices[c]] = (float)rgbValues[c];
    }
  }
  else if (outDType == OutDTypeUint8) {
    uint8_t *buf = (uint8_t *)buffer;
    
    for (int c = 0; c < channelCount; c++) {
      buf[pixelIndices[c]] = (uint8_t)roundf(rgbValues[c]);
    }
  }
}


void ApplyExifOrientation(
    OrientationHandling orientationHandling,
    CGContextRef context,
    UIImageOrientation orientation,
    CGSize targetSize
) {
  if (orientationHandling == OrientationHandlingRespectExif) {
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (orientation) {

        case UIImageOrientationRight:
            transform = CGAffineTransformTranslate(transform, targetSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationLeft:
            transform = CGAffineTransformTranslate(transform, 0, targetSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;

        case UIImageOrientationDown:
            transform = CGAffineTransformTranslate(transform,
                                                    targetSize.width,
                                                    targetSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        default:
            break;
    }

    CGContextConcatCTM(context, transform);
  }
}

size_t GetElementSize(
   OutDType outDType
) {
  size_t elementSize;

 if (outDType == OutDTypeUint8) {
   elementSize = sizeof(uint8_t);
 } else {
   elementSize = sizeof(float);
 }
  
  return elementSize;
}
