import { TurboModuleRegistry, type TurboModule } from 'react-native';
interface MetaObj {
  layout: 'NHWC' | 'NCHW';
  dType: 'float32' | 'uint8' | 'int8';
}

interface Meta {
  shape: Array<number>;
  meta: MetaObj;
}

interface RGB {
  r: number;
  g: number;
  b: number;
}

interface Options {
  inputDimensions: {
    width: number;
    height: number;
  };

  // varies frequently as per model
  colorFormat?: 'RGB' | 'BGR' | 'Grayscale';
  normalization?: 'zeroToOne' | 'none' | 'minusOneToOne' | 'meanStd';
  mean?: RGB;
  std?: RGB;
  outDType?: 'float32' | 'uint8' | 'int8';

  // rarely varies, but good to have it customizable
  resizeStrategy?: 'stretch' | 'aspectFit' | 'aspectFill';
  tensorLayout?: 'NHWC' | 'NCHW';
  orientationHandling?: 'respectExif' | 'ignoreExif';
  alphaHandling?: 'dropAlpha' | 'premultiply';
}

export interface Spec extends TurboModule {
  install: () => boolean;
  uninstall: () => boolean;
  processImage(filePath: string, options: Options): Meta;
}

export default TurboModuleRegistry.getEnforcing<Spec>('ImageProcessing');
