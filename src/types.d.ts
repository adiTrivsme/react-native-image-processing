interface Meta {
  shape: Array<number>;
  meta: Object;
}

interface Tensor {
  tensor: FloatArray;
  shape: Array<number>;
  meta: Object;
}

interface TensorObj extends Meta {
  tensor: ArrayBuffer;
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
  outDType?: 'float32' | 'uint8' | 'int8';

  // rarely varies, but good to have it customizable
  channelOrder?: 'interleaved' | 'planar';
  resizeStrategy?: 'centerCrop' | 'stretch' | 'aspectFit' | 'aspectFill'; // non
  tensorLayout?: 'NHWC' | 'NCHW';
  orientationHandling?: 'respectExif' | 'ignoreExif';
  alphaHandling?: 'dropAlpha' | 'premultiply' | 'keep';
}

type GetTensorObjMethod = {
  (): ArrayBuffer;
  (filePath: string, options: Options): TensorObj;
};

type ImageProcessingModule = {
  sayHello: () => string;
  getTensorObj: GetTensorObjMethod;
};

type GlobalWithImageProcessing = typeof globalThis & {
  __imageProcessing__?: ImageProcessingModule;
};
