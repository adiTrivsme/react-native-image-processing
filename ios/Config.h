//
//  Config.h
//  Pods
//
//  Created by apple on 16/03/26.
//


typedef NS_ENUM(NSInteger, ColorFormat) {
    ColorFormatRGB,
    ColorFormatBGR,
    ColorFormatGrayscale
};

typedef NS_ENUM(NSInteger, Normalization) {
    NormalizationZeroToOne,
    NormalizationNone,
    NormalizationMinusOneToOne,
    NormalizationMeanStd
};

typedef NS_ENUM(NSInteger, OutDType) {
    OutDTypeFloat32,
    OutDTypeUint8
};

typedef NS_ENUM(NSInteger, ResizeStrategy) {
    ResizeStrategyStretch,
    ResizeStrategyAspectFit,
    ResizeStrategyAspectFill
};

typedef NS_ENUM(NSInteger, TensorLayout) {
    TensorLayoutNHWC,
    TensorLayoutNCHW
};

typedef NS_ENUM(NSInteger, OrientationHandling) {
    OrientationHandlingRespectExif,
    OrientationHandlingIgnoreExif
};

typedef NS_ENUM(NSInteger, AlphaHandling) {
    AlphaHandlingDropAlpha,
    AlphaHandlingPremultiply
};

ColorFormat ColorFormatFromJS(NSString *value);
NSString *ColorFormatToJS(ColorFormat value);

Normalization NormalizationFromJS(NSString *value);
NSString *NormalizationToJS(Normalization value);

OutDType OutDTypeFromJS(NSString *value);
NSString *OutDTypeToJS(OutDType value);

ResizeStrategy ResizeStrategyFromJS(NSString *value);
NSString *ResizeStrategyToJS(ResizeStrategy value);

TensorLayout TensorLayoutFromJS(NSString *value);
NSString *TensorLayoutToJS(TensorLayout value);

OrientationHandling OrientationHandlingFromJS(NSString *value);
NSString *OrientationHandlingToJS(OrientationHandling value);

AlphaHandling AlphaHandlingFromJS(NSString *value);
NSString *AlphaHandlingToJS(AlphaHandling value);
