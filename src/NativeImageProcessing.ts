import { TurboModuleRegistry, type TurboModule } from 'react-native';

interface Meta {
  shape: Array<number>;
  meta: Object;
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
  colorFormat?: 'RGB' | 'RGBA' | 'BGR' | 'Grayscale';
  normalization?: 'zeroToOne' | 'none' | 'minusOneToOne' | 'meanStd';
  mean?: RGB;
  std?: RGB;
  outDType?: 'float32' | 'uint8' | 'int8'; // non

  // rarely varies, but good to have it customizable
  channelOrder?: 'interleaved' | 'planar'; // non
  resizeStrategy?: 'centerCrop' | 'stretch' | 'aspectFit' | 'aspectFill'; // non
  tensorLayout?: 'NHWC' | 'NCHW'; // non
  orientationHandling?: 'respectExif' | 'ignoreExif';
  alphaHandling?: 'dropAlpha' | 'premultiply' | 'keep';
}

export interface Spec extends TurboModule {
  install: () => boolean;
  uninstall: () => boolean;
  processImage(filePath: string, options: Options): Meta;
}

export default TurboModuleRegistry.getEnforcing<Spec>('ImageProcessing');
