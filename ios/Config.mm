//
//  Config.mm
//  Pods
//
//  Created by apple on 16/03/26.
//


#import "Config.h"

ColorFormat ColorFormatFromJS(NSString *value) {
    if ([value isEqualToString:@"BGR"]) return ColorFormatBGR;
    if ([value isEqualToString:@"Grayscale"]) return ColorFormatGrayscale;
    return ColorFormatRGB;
}

NSString *ColorFormatToJS(ColorFormat value) {
    switch (value) {
        case ColorFormatBGR: return @"BGR";
        case ColorFormatGrayscale: return @"Grayscale";
        default: return @"RGB";
    }
}


Normalization NormalizationFromJS(NSString *value) {
    if ([value isEqualToString:@"none"]) return NormalizationNone;
    if ([value isEqualToString:@"minusOneToOne"]) return NormalizationMinusOneToOne;
    if ([value isEqualToString:@"meanStd"]) return NormalizationMeanStd;
    return NormalizationZeroToOne;
}

NSString *NormalizationToJS(Normalization value) {
    switch (value) {
        case NormalizationNone: return @"none";
        case NormalizationMinusOneToOne: return @"minusOneToOne";
        case NormalizationMeanStd: return @"meanStd";
        default: return @"zeroToOne";
    }
}


OutDType OutDTypeFromJS(NSString *value) {
    if ([value isEqualToString:@"uint8"]) return OutDTypeUint8;
    return OutDTypeFloat32;
}

NSString *OutDTypeToJS(OutDType value) {
    switch (value) {
        case OutDTypeUint8: return @"uint8";
        default: return @"float32";
    }
}


ResizeStrategy ResizeStrategyFromJS(NSString *value) {
    if ([value isEqualToString:@"stretch"]) return ResizeStrategyStretch;
    if ([value isEqualToString:@"aspectFit"]) return ResizeStrategyAspectFit;
    return ResizeStrategyAspectFill;
}

NSString *ResizeStrategyToJS(ResizeStrategy value) {
    switch (value) {
        case ResizeStrategyStretch: return @"stretch";
        case ResizeStrategyAspectFit: return @"aspectFit";
        default: return @"aspectFill";
    }
}


TensorLayout TensorLayoutFromJS(NSString *value) {
    if ([value isEqualToString:@"NCHW"]) return TensorLayoutNCHW;
    return TensorLayoutNHWC;
}

NSString *TensorLayoutToJS(TensorLayout value) {
    switch (value) {
        case TensorLayoutNCHW: return @"NCHW";
        default: return @"NHWC";
    }
}


OrientationHandling OrientationHandlingFromJS(NSString *value) {
    if ([value isEqualToString:@"ignoreExif"]) return OrientationHandlingIgnoreExif;
    return OrientationHandlingRespectExif;
}

NSString *OrientationHandlingToJS(OrientationHandling value) {
    switch (value) {
        case OrientationHandlingIgnoreExif: return @"ignoreExif";
        default: return @"respectExif";
    }
}


AlphaHandling AlphaHandlingFromJS(NSString *value) {
    if ([value isEqualToString:@"premultiply"]) return AlphaHandlingPremultiply;
    return AlphaHandlingDropAlpha;
}

NSString *AlphaHandlingToJS(AlphaHandling value) {
    switch (value) {
        case AlphaHandlingPremultiply: return @"premultiply";
        default: return @"dropAlpha";
    }
}
