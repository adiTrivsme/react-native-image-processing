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

#import <ReactCommon/CallInvoker.h>

#import "BitmapUtils.h"
#import "Utils.h"

using namespace facebook;


@implementation ImageProcessing

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeImageProcessingSpecJSI>(params);
}

- (instancetype)init {
  return self;
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
  
  // create bitmap context with configs ======
  ImageProcessingConfig config = BuildImageProcessingConfig(rt, options);
  
  CGContextRef context = CreateBitmapContext(config);
  
  void *data = CGBitmapContextGetData(context);

  if (data == NULL) {
    RCTLogInfo(@"[NativeImagePreprocessing] Failed to create bitmap context");
    throw jsi::JSError(rt, "Failed to create bitmap context");
  }

  DrawImageIntoContext(image, context, config);
  
  size_t width  = CGBitmapContextGetWidth(context);
  size_t height = CGBitmapContextGetHeight(context);
  
  void *outputBuffer = FillTensorFromBitmapContext(context, config);
  
  OutDType outDType = config.outDType;
  size_t channelCount = config.channelCount;
  
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
  metaObj.setProperty(rt, "layout", nsStringToJSI(rt, TensorLayoutToJS(config.tensorLayout)));
  metaObj.setProperty(rt, "dType", nsStringToJSI(rt, OutDTypeToJS(outDType)));
  
  jsi::Object result(rt);
  result.setProperty(rt, "shape", shapeArray);
  result.setProperty(rt, "meta", metaObj);
  result.setProperty(rt, "tensor", std::move(arrayBuffer));
  
  return jsi::Value(rt, result);
}


RCT_EXPORT_SYNCHRONOUS_TYPED_METHOD(NSNumber *, install)
{
  RCTCxxBridge* cxxBridge = (RCTCxxBridge *) _bridge.batchedBridge;
  
  if (cxxBridge == nil) return @NO;
  
  jsi::Runtime *jsiRuntime = (jsi::Runtime *) cxxBridge.runtime;

  if (jsiRuntime == nil) return @NO;
  
  imageProcessingModule::install(*jsiRuntime);
  
  return @YES;
}

RCT_EXPORT_SYNCHRONOUS_TYPED_METHOD(NSNumber *, uninstall)
{
  RCTCxxBridge* cxxBridge = (RCTCxxBridge *) _bridge.batchedBridge;
  
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
