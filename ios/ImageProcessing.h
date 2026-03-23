#import <React/RCTBridgeModule.h>
#import <ReactCommon/RCTTurboModule.h>

#import <ImageProcessingSpec/ImageProcessingSpec.h>

@interface ImageProcessing : NSObject <NativeImageProcessingSpec, RCTTurboModule>

@property (nonatomic, weak) RCTBridge *bridge;
@end
