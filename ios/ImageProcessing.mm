#import "ImageProcessing.h"
#import "Bridge.h"
#import "react-native-image-processing.h"
#import "FloatBuffer.h"
#import "RawBuffer.h"

#import <jsi/jsi.h>
#import <React/RCTBridge+Private.h>
#import <React/RCTLog.h>
#import <UIKit/UIKit.h>
#import <React/RCTUtils.h>

#import "Utils.h"

using namespace facebook;

@interface ImageProcessing ()
@property (copy, nonatomic) NSString *defaultColorFormat;
@property (copy, nonatomic) NSString *defaultNormalization;
@property (copy, nonatomic) NSString *defaultOutDType;
@property (copy, nonatomic) NSString *defaultChannelOrder;
@property (copy, nonatomic) NSString *defaultResizeStrategy;
@property (copy, nonatomic) NSString *defaultTensorLayout;
@property (copy, nonatomic) NSString *defaultOrientationHandling;
@property (copy, nonatomic) NSString *defaultAlphaHandling;

@property (nonatomic) int channelCount;
@end

@implementation ImageProcessing

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeImageProcessingSpecJSI>(params);
}

+ (NSString *)moduleName
{
  return @"ImageProcessing";
}

- (instancetype)init {
  if (self = [super init]) {
    _defaultColorFormat = @"RGB";
    _defaultNormalization = @"zeroToOne";
    _defaultOutDType = @"float32";
    _defaultResizeStrategy = @"aspectFill";
    _defaultTensorLayout = @"NHWC";
    _defaultOrientationHandling = @"respectExif";
    _defaultAlphaHandling = @"dropAlpha";
    
    _channelCount = 3;
  }
  return self;
}

static NSString *JSIStringToNSString(jsi::Runtime &rt, const jsi::String &str) {
  return [NSString stringWithUTF8String:str.utf8(rt).c_str()];
}

static  jsi::String nsStringToJSI(jsi::Runtime &rt, NSString *str) {
  return jsi::String::createFromUtf8(rt, str.UTF8String);
}

static NSArray *convertRGBJSIObjectToNSArray(jsi::Runtime &rt, const jsi::Object &obj) {
  NSNumber *r = @(obj.getProperty(rt, "r").asNumber());
  NSNumber *g = @(obj.getProperty(rt, "g").asNumber());
  NSNumber *b = @(obj.getProperty(rt, "b").asNumber());
  return @[r, g, b];
}

- (NSDictionary *)getConfigs:(jsi::Runtime &)rt
                     options:(const jsi::Object &)options
{
  // ---- inputDimensions ----
  NSNumber *width = nil;
  NSNumber *height = nil;

  if (options.hasProperty(rt, "inputDimensions")) {
    auto dims = options.getProperty(rt, "inputDimensions").asObject(rt);

    if (dims.hasProperty(rt, "width")) {
      width = @(dims.getProperty(rt, "width").asNumber());
    }
    if (dims.hasProperty(rt, "height")) {
      height = @(dims.getProperty(rt, "height").asNumber());
    }
  }

  // ---- normalization ----
  NSString *normalization = self.defaultNormalization;
  if (options.hasProperty(rt, "normalization")) {
    normalization = JSIStringToNSString(
      rt,
      options.getProperty(rt, "normalization").asString(rt)
    );
  }

  NSArray *meanValue = nil;  NSArray *stdValue  = nil;

  if ([normalization isEqualToString:@"meanStd"]) {
    if (options.hasProperty(rt, "mean")) {
      auto mean = options.getProperty(rt, "mean").asObject(rt);
      meanValue = convertRGBJSIObjectToNSArray(rt, mean);
    }

    if (options.hasProperty(rt, "std")) {
      auto std = options.getProperty(rt, "std").asObject(rt);
      stdValue = convertRGBJSIObjectToNSArray(rt, std);
    }
  }

  // ---- simple string props helper ----
  auto getStringProp = ^NSString *(const char *key, NSString *fallback) {
    if (options.hasProperty(rt, key)) {
      return JSIStringToNSString(
        rt,
        options.getProperty(rt, key).asString(rt)
      );
    }
    return fallback;
  };
  
  NSString *colorFormat = getStringProp("colorFormat", self.defaultColorFormat);

  NSDictionary *config = @{
    @"inputWidth": width ?: [NSNull null],
    @"inputHeight": height ?: [NSNull null],
    @"colorFormat": colorFormat,
    @"normalization": normalization,
    @"mean": meanValue ?: [NSNull null],
    @"std": stdValue ?: [NSNull null],
    @"outDType": getStringProp("outDType", self.defaultOutDType),
    @"resizeStrategy": getStringProp("resizeStrategy", self.defaultResizeStrategy),
    @"tensorLayout": getStringProp("tensorLayout", self.defaultTensorLayout),
    @"orientationHandling": getStringProp("orientationHandling", self.defaultOrientationHandling),
    @"alphaHandling": getStringProp("alphaHandling", self.defaultAlphaHandling),
    @"channelCount": [colorFormat isEqualToString:@"Grayscale"] ? @1 : @3,
  };

  return config;
}

- (CGContextRef)createBitmapContext:(NSDictionary *)config {
    size_t width  = [config[@"inputWidth"] unsignedIntegerValue];
    size_t height = [config[@"inputHeight"] unsignedIntegerValue];

    NSString *colorFormat = config[@"colorFormat"];
    NSString *alphaHandling = config[@"alphaHandling"];
  
    BitmapContextConfig ctxConfig =
        GetBitmapContextConfig(colorFormat, alphaHandling);

    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width * ctxConfig.bytesPerPixel;;

    CGContextRef context = CGBitmapContextCreate(
        NULL, // let system allocate the buffer size
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

- (void)drawImage:(UIImage *)image
         inContext:(CGContextRef)context
            config:(NSDictionary *)config {

    if (!context || !image) {
        NSLog(@"[ImagePreprocess] ❌ Invalid context or image");
        return;
    }


    CGImageRef cgImage = image.CGImage;
    if (!cgImage) {
        NSLog(@"[ImagePreprocess] ❌ UIImage has no CGImage backing");
        return;
    }


    size_t targetWidth  = CGBitmapContextGetWidth(context);
    size_t targetHeight = CGBitmapContextGetHeight(context);
    CGSize targetSize = CGSizeMake(targetWidth, targetHeight);

    // save graphics state
    // orientation transforms should not leak outside this draw
    CGContextSaveGState(context);

    NSString *orientationHandling = config[@"orientationHandling"];
    ApplyExifOrientation(orientationHandling, context, image.imageOrientation, targetSize);
  
    size_t srcWidth  = CGImageGetWidth(cgImage);
    size_t srcHeight = CGImageGetHeight(cgImage);
  
    NSString *resizeStrategy = config[@"resizeStrategy"];
    CGRect drawRect = ComputeDrawRect(
                                      srcWidth,
                                      srcHeight,
                                      targetWidth,
                                      targetHeight,
                                      resizeStrategy
                                  );
  
    CGContextDrawImage(context, drawRect, cgImage);

    // Restore graphics state, cleans up orientation transforms
    CGContextRestoreGState(context);

   RCTLogInfo(@"[NativeImagePreprocessing] ✅ Image drawn into bitmap context");
}

- (void *)fillTensorFromBitmapContext:(CGContextRef)context
                             config: config
{
    // Get bitmap properties
    size_t width  = CGBitmapContextGetWidth(context);
    size_t height = CGBitmapContextGetHeight(context);
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    size_t bitsPerPixel = CGBitmapContextGetBitsPerPixel(context);
    size_t bytesPerPixel = bitsPerPixel / 8; // usually 4 (RGBA)

    uint8_t *pixelData = (uint8_t *)CGBitmapContextGetData(context);
  
    NSString *channelCountObject = config[@"channelCount"];
    int channelCount = [channelCountObject intValue];
  
    size_t elementCount = width * height * channelCount;
    float *output = (float *)malloc(elementCount * sizeof(float));
  
    if (!pixelData) {
        NSLog(@"No pixel data");
        return output;
    }
  
    NSString *colorFormat = config[@"colorFormat"];
    NSString *normalization = config[@"normalization"];
    NSString *outDType = config[@"outDType"];
    NSString *alphaHandling = config[@"alphaHandling"];
    NSArray *mean = config[@"mean"];
    NSArray *std = config[@"std"];
    NSString *layout = config[@"tensorLayout"];
    
    if ([outDType isEqualToString:@"uint8"] &&
      ![normalization isEqualToString:@"none"]) {

      NSLog(@"Invalid config: uint8 tensors cannot use normalization. Forcing 'none'.");
      normalization = @"none";
    }

    void *buffer = NULL;

    if ([outDType isEqualToString:@"float32"]) {
      buffer = malloc(elementCount * sizeof(float));
    }
    else if ([outDType isEqualToString:@"uint8"]) {
      buffer = malloc(elementCount * sizeof(uint8_t));
    }
  
    for (size_t y = 0; y < height; y++) {
        uint8_t *row = pixelData + y * bytesPerRow;

        for (size_t x = 0; x < width; x++) {
          uint8_t *pixel = row + x * bytesPerPixel;

          // normalized RGB values
          RGBValues rgb = NormalizePixel(
              pixel,
              normalization,
              alphaHandling,
              mean,
              std
          );
          
          auto pixelIndices = GetOutIndicesAsPerTensorLayout(
              x,
              y,
              width,
              height,
              channelCount,
              layout
          );
          
          auto rgbValues = rgbOrderAsPerColorFormat(colorFormat, rgb);
          
          UpdateOutputBufferWithRGB(outDType, buffer, pixelIndices.data(), rgbValues.data(), channelCount);
        }
    }
  
  return buffer;
}

- (jsi::Value)processImage:(jsi::Runtime &)rt
                    filePath: (NSString *)filePath
                     options:(const jsi::Object &)options
{
  RCTLogInfo(@"[NativeImagePreprocessing] image at path %@", filePath);
  
  // Load and check the image properties
  NSURL *url = [NSURL URLWithString:filePath];
  UIImage *image = [UIImage imageWithContentsOfFile:url.path];

  if (!image) {
    NSString *message = [NSString stringWithFormat:@"[NativeImagePreprocessing] no image present at path - %@", url.path];
    
    RCTLogInfo(@"%@", message);
    
    throw jsi::JSError(rt, jsi::String::createFromUtf8(rt, [message UTF8String]));
  }

  NSInteger imageWidth = image.size.width;
  NSInteger imageHeight = image.size.height;
  
  RCTLogInfo(@"[NativeImagePreprocessing] Original image dimensions: %ld x %ld", (long)imageWidth, (long)imageHeight);
  
  
  // create bitmap context with configs ======
  
  NSDictionary *config = [self  getConfigs:rt options:options];
  
  CGContextRef context = [self createBitmapContext:config];
  
  void *data = CGBitmapContextGetData(context);

  if (data == NULL) {
    RCTLogInfo(@"[NativeImagePreprocessing] ❌ Failed to create bitmap context");
    throw jsi::JSError(rt, "Failed to create bitmap context");
  }
  
  RCTLogInfo(@"[NativeImagePreprocessing] ✅ Bitmap context created");

  
  [self drawImage:image inContext:(CGContextRef) context config: config];
  
  size_t width  = CGBitmapContextGetWidth(context);
  size_t height = CGBitmapContextGetHeight(context);

  void *outputBuffer = [self fillTensorFromBitmapContext:context config: config];
  
  NSString *outDType = config[@"outDType"];
  NSString *channelCountObject = config[@"channelCount"];
  size_t channelCount = [channelCountObject intValue];
  
  size_t elementCount = width * height * channelCount;
  size_t elementSize = GetElementSize(outDType);
  size_t byteLength = elementCount * elementSize;
  
  auto dataBuffer = std::make_shared<RawBuffer>(outputBuffer, byteLength);
  jsi::ArrayBuffer arrayBuffer(rt, std::move(dataBuffer));
  
  
  jsi::Array shapeArray(rt, 4);
  shapeArray.setValueAtIndex(rt, 0, 1);
  shapeArray.setValueAtIndex(rt, 1, jsi::Value((double)height));
  shapeArray.setValueAtIndex(rt, 2, jsi::Value((double)width));
  shapeArray.setValueAtIndex(rt, 3, jsi::Value((double)channelCount));

  jsi::Object metaObj(rt);
  metaObj.setProperty(rt, "layout", nsStringToJSI(rt, (config[@"tensorLayout"])));
  metaObj.setProperty(rt, "dType", nsStringToJSI(rt, outDType));
  
  jsi::Object result(rt);
  result.setProperty(rt, "shape", shapeArray);
  result.setProperty(rt, "meta", metaObj);
  result.setProperty(rt, "tensor", std::move(arrayBuffer));
  
  return jsi::Value(rt, result);
}


RCT_EXPORT_SYNCHRONOUS_TYPED_METHOD(NSNumber *, install)
{
  RCTBridge *bridge = [RCTBridge currentBridge];
  RCTCxxBridge* cxxBridge = (RCTCxxBridge *) bridge;
  
  if (cxxBridge == nil) return @NO;
  
  jsi::Runtime *jsiRuntime = (jsi::Runtime *) cxxBridge.runtime;
  
  if (jsiRuntime == nil) return @NO;
  
  imageProcessingModule::install(*jsiRuntime);
  
  return @YES;
}

RCT_EXPORT_SYNCHRONOUS_TYPED_METHOD(NSNumber *, uninstall)
{
  RCTBridge *bridge = [RCTBridge currentBridge];
  RCTCxxBridge* cxxBridge = (RCTCxxBridge *) bridge;
  
  if (cxxBridge == nil) return @NO;
  
  jsi::Runtime *jsiRuntime = (jsi::Runtime *) cxxBridge.runtime;
  
  if (jsiRuntime == nil) return @NO;
  
  imageProcessingModule::uninstall(*jsiRuntime);
  
  return @YES;
}

@end

jsi::Value getTensor(jsi::Runtime &rt, const jsi::Value& thisVal, const jsi::Value* args, size_t count) {
  
  if (count != 2 || !args[0].isString() || !args[1].isObject()) {
    throw jsi::JSError(rt, "Expected (string filePath, object options)");
  }
  
  NSString *filePath = JSIStringToNSString(rt, args[0].asString(rt));
  
  const jsi::Object options = args[1].asObject(rt);
  
  ImageProcessing *processor = [[ImageProcessing alloc] init];
  
  jsi::Value result = [processor processImage:rt
                                     filePath:filePath
                                      options:options];
  
  return result;
}
