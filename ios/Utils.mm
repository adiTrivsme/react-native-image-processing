//
//  Utils.mm
//  Pods
//
//  Created by apple on 09/03/26.
//

#import "Utils.h"

#import <CoreGraphics/CoreGraphics.h>


CGRect ComputeDrawRect(size_t srcWidth,
                       size_t srcHeight,
                       size_t targetWidth,
                       size_t targetHeight,
                       NSString *strategy)
{
    CGFloat widthRatio  = (CGFloat)targetWidth / srcWidth;
    CGFloat heightRatio = (CGFloat)targetHeight / srcHeight;

    // stretch
    if ([strategy isEqualToString:@"stretch"]) {
        return CGRectMake(0, 0, targetWidth, targetHeight);
    }

    // aspectFit
    if ([strategy isEqualToString:@"aspectFit"]) {

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

    // aspectFill (also replaces centerCrop)
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
    NSString *layout
) {
    std::array<size_t, 3> indices;

    BOOL isNCHW = [layout isEqualToString:@"NCHW"];

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
    NSString *normalization,
    NSString *alphaHandling,
    const NSArray *mean,
    const NSArray *std
) {
    float rf = (float)pixel[0];
    float gf = (float)pixel[1];
    float bf = (float)pixel[2];
  
    uint8_t a = pixel[3];
  
    // ---------- Alpha Handling ----------
    if ([alphaHandling isEqualToString:@"premultiply"]) {
        float af = a / 255.0f;

        rf *= af;
        gf *= af;
        bf *= af;
    }

    if ([normalization isEqualToString:@"zeroToOne"]) {

        rf /= 255.0f;
        gf /= 255.0f;
        bf /= 255.0f;

    } else if ([normalization isEqualToString:@"minusOneToOne"]) {

        rf = (rf / 127.5f) - 1.0f;
        gf = (gf / 127.5f) - 1.0f;
        bf = (bf / 127.5f) - 1.0f;

    } else if ([normalization isEqualToString:@"meanStd"]) {

        float meanR = [mean[0] floatValue];
        float meanG = [mean[1] floatValue];
        float meanB = [mean[2] floatValue];

        float stdR = [std[0] floatValue];
        float stdG = [std[1] floatValue];
        float stdB = [std[2] floatValue];

        rf = ((rf / 255.0f) - meanR) / stdR;
        gf = ((gf / 255.0f) - meanG) / stdG;
        bf = ((bf / 255.0f) - meanB) / stdB;
    }

    return {rf, gf, bf};
}


std::array<float, 3> rgbOrderAsPerColorFormat(
    NSString *colorFormat,
    RGBValues rgb
)
{
  std::array<float, 3> rgbOrder;
  
  BOOL isRGB  = [colorFormat isEqualToString:@"RGB"];
  BOOL isBGR  = [colorFormat isEqualToString:@"BGR"];
  BOOL isGRAY = [colorFormat isEqualToString:@"Grayscale"];
  
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
   NSString *outDType,
   void *buffer,
   const size_t *pixelIndices,
   const float *rgbValues,
   int channelCount
)
{
  if ([outDType isEqualToString:@"float32"]) {
    float *buf = (float *)buffer;
    
    for (int c = 0; c < channelCount; c++) {
      buf[pixelIndices[c]] = (float)rgbValues[c];
    }
  }
  else if ([outDType isEqualToString:@"uint8"]) {
    uint8_t *buf = (uint8_t *)buffer;
    
    for (int c = 0; c < channelCount; c++) {
      buf[pixelIndices[c]] = (uint8_t)roundf(rgbValues[c]);
    }
  }
}


void ApplyExifOrientation(
    NSString *orientationHandling,
    CGContextRef context,
    UIImageOrientation orientation,
    CGSize targetSize
) {
  if ([orientationHandling isEqualToString:@"respectExif"]) {
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


BitmapContextConfig GetBitmapContextConfig(
    NSString *colorFormat,
    NSString *alphaHandling
) {
  BitmapContextConfig config;

  BOOL wantsAlpha = [alphaHandling isEqualToString:@"premultiply"];
  BOOL isGrayScaleFormat = [colorFormat isEqualToString:@"Grayscale"];

  if (isGrayScaleFormat) {
      if (wantsAlpha) {
          NSLog(@"Invalid config: grayscale cannot use premultiplied alpha");
      }

      config.colorSpace = CGColorSpaceCreateDeviceGray();
      config.bytesPerPixel = 1;
      config.bitmapInfo = kCGImageAlphaNone;

  } else {
      config.colorSpace = CGColorSpaceCreateDeviceRGB();
      config.bytesPerPixel = 4;

      if (wantsAlpha) {
          config.bitmapInfo = kCGImageAlphaPremultipliedLast;
      } else {
          config.bitmapInfo = kCGImageAlphaNoneSkipLast;
      }
  }

  return config;
}


size_t GetElementSize(
   NSString *outDType
) {
  size_t elementSize;

 if ([outDType isEqualToString:@"uint8"]) {
   elementSize = sizeof(uint8_t);
 } else {
   elementSize = sizeof(float);
 }
  
  return elementSize;
}
