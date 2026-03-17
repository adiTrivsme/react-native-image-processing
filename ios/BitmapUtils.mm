//
//  BitmapUtils.mm
//  Pods
//
//  Created by apple on 16/03/26.
//

#import <React/RCTLog.h>
#import <jsi/jsi.h>

#import "BitmapUtils.h"
#import "Utils.h"
#import "Config.h"

using namespace facebook;

ImageProcessingConfig BuildImageProcessingConfig(
    jsi::Runtime &rt,
    const jsi::Object &options
){
  ImageProcessingConfig config = {0};

  // ---- inputDimensions ----
  if (options.hasProperty(rt, "inputDimensions")) {
    auto dims = options.getProperty(rt, "inputDimensions").asObject(rt);

    if (dims.hasProperty(rt, "width")) {
      config.inputWidth = (int)dims.getProperty(rt, "width").asNumber();
    }

    if (dims.hasProperty(rt, "height")) {
      config.inputHeight = (int)dims.getProperty(rt, "height").asNumber();
    }
  }

  // ---- string helper ----
  auto getStringProp = ^NSString *(const char *key) {
    if (options.hasProperty(rt, key)) {
      return JSIStringToNSString(
        rt,
        options.getProperty(rt, key).asString(rt)
      );
    }
    return nil;
  };

  config.colorFormat = ColorFormatFromJS(getStringProp("colorFormat"));
  config.normalization = NormalizationFromJS(getStringProp("normalization"));
  config.outDType = OutDTypeFromJS(getStringProp("outDType"));
  config.resizeStrategy = ResizeStrategyFromJS(getStringProp("resizeStrategy"));
  config.tensorLayout = TensorLayoutFromJS(getStringProp("tensorLayout"));
  config.orientationHandling = OrientationHandlingFromJS(getStringProp("orientationHandling"));
  config.alphaHandling = AlphaHandlingFromJS(getStringProp("alphaHandling"));

  config.channelCount =
      (config.colorFormat == ColorFormatGrayscale) ? 1 : 3;

  // ---- mean/std ----
  config.hasMeanStd = false;

  if (config.normalization == NormalizationMeanStd) {
    if (options.hasProperty(rt, "mean") &&
        options.hasProperty(rt, "std")) {

      auto mean = options.getProperty(rt, "mean").asObject(rt).asArray(rt);
      auto std  = options.getProperty(rt, "std").asObject(rt).asArray(rt);

      for (int i = 0; i < config.channelCount; i++) {
        config.mean[i] = mean.getValueAtIndex(rt, i).asNumber();
        config.std[i]  = std.getValueAtIndex(rt, i).asNumber();
      }

      config.hasMeanStd = true;
    }
  }

  return config;
}


BitmapContextConfig GetBitmapContextConfig(
    ColorFormat colorFormat,
    AlphaHandling alphaHandling
) {
  BitmapContextConfig config;

  BOOL wantsAlpha = alphaHandling == AlphaHandlingPremultiply;
  BOOL isGrayScaleFormat = colorFormat == ColorFormatGrayscale;

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

CGContextRef CreateBitmapContext(ImageProcessingConfig config) {
    size_t width  = config.inputWidth;
    size_t height = config.inputHeight;

    ColorFormat colorFormat = config.colorFormat;
    AlphaHandling alphaHandling = config.alphaHandling;

    BitmapContextConfig ctxConfig =
        GetBitmapContextConfig(colorFormat, alphaHandling);

    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width * ctxConfig.bytesPerPixel;

    CGContextRef context = CGBitmapContextCreate(
        NULL, // system allocates memory
        width,
        height,
        bitsPerComponent,
        bytesPerRow,
        ctxConfig.colorSpace,
        ctxConfig.bitmapInfo
    );

    CGColorSpaceRelease(ctxConfig.colorSpace);

    return context;
}

void DrawImageIntoContext(UIImage *image,
                          CGContextRef context,
                          ImageProcessingConfig config)
{
    if (!context || !image) {
        NSLog(@"[ImagePreprocess] Invalid context or image");
        return;
    }

    CGImageRef cgImage = image.CGImage;
    if (!cgImage) {
        NSLog(@"[ImagePreprocess] UIImage has no CGImage backing");
        return;
    }

    size_t targetWidth  = CGBitmapContextGetWidth(context);
    size_t targetHeight = CGBitmapContextGetHeight(context);
    CGSize targetSize = CGSizeMake(targetWidth, targetHeight);

    // Save state so transforms don't leak
    CGContextSaveGState(context);

    ApplyExifOrientation(
        config.orientationHandling,
        context,
        image.imageOrientation,
        targetSize
    );

    size_t srcWidth  = CGImageGetWidth(cgImage);
    size_t srcHeight = CGImageGetHeight(cgImage);

    CGRect drawRect = ComputeDrawRect(
        srcWidth,
        srcHeight,
        targetWidth,
        targetHeight,
        config.resizeStrategy
    );

    CGContextDrawImage(context, drawRect, cgImage);

    // Restore state (removes orientation transforms)
    CGContextRestoreGState(context);

    RCTLogInfo(@"[NativeImagePreprocessing] Image drawn into bitmap context");
}


void *FillTensorFromBitmapContext(CGContextRef context, ImageProcessingConfig config)
{
    if (!context) {
        NSLog(@"[ImagePreprocess] Invalid CGContext");
        return NULL;
    }

    size_t width  = CGBitmapContextGetWidth(context);
    size_t height = CGBitmapContextGetHeight(context);
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    size_t bitsPerPixel = CGBitmapContextGetBitsPerPixel(context);
    size_t bytesPerPixel = bitsPerPixel / 8;

    uint8_t *pixelData = (uint8_t *)CGBitmapContextGetData(context);

    if (!pixelData) {
        NSLog(@"[ImagePreprocess] No pixel data");
        return NULL;
    }

    int channelCount = config.channelCount;
    size_t elementCount = width * height * channelCount;

    Normalization normalization = config.normalization;
    const float *meanPtr = config.hasMeanStd ? config.mean : NULL;
    const float *stdPtr  = config.hasMeanStd ? config.std  : NULL;
  
    OutDType outDType = config.outDType;

    if (outDType == OutDTypeUint8 && normalization != NormalizationNone) {
        NSLog(@"Invalid config: uint8 tensors cannot use normalization. Forcing 'none'.");
        normalization = NormalizationNone;
    }

    void *buffer = NULL;

    if (outDType == OutDTypeFloat32) {
        buffer = malloc(elementCount * sizeof(float));
    }
    else if (outDType == OutDTypeUint8) {
        buffer = malloc(elementCount * sizeof(uint8_t));
    }

    if (!buffer) {
        NSLog(@"[ImagePreprocess] Failed to allocate output buffer");
        return NULL;
    }

    for (size_t y = 0; y < height; y++) {

        uint8_t *row = pixelData + y * bytesPerRow;

        for (size_t x = 0; x < width; x++) {

            uint8_t *pixel = row + x * bytesPerPixel;

            RGBValues rgb = NormalizePixel(
                pixel,
                normalization,
                config.alphaHandling,
                meanPtr,
                stdPtr
            );

            auto pixelIndices = GetOutIndicesAsPerTensorLayout(
                x,
                y,
                width,
                height,
                channelCount,
                config.tensorLayout
            );

            auto rgbValues = rgbOrderAsPerColorFormat(config.colorFormat, rgb);

            UpdateOutputBufferWithRGB(
                config.outDType,
                buffer,
                pixelIndices.data(),
                rgbValues.data(),
                channelCount
            );
        }
    }

    return buffer;
}
