import { Platform } from 'react-native';

import ImageProcessing from './NativeImageProcessing';
import { convertBufferToTensor } from './utils';

const g = globalThis as GlobalWithImageProcessing;

if (!g.__imageProcessing__) {
  ImageProcessing.install();
}

const module = g.__imageProcessing__!;

export function sayHello(): string {
  return module.sayHello();
}

export function getTensorObj(filePath: string, options: Options): Tensor {
  if (Platform.OS === 'ios') {
    // in iOS image gets processed internally and directly response gets returned
    const {
      tensor: buffer,
      shape,
      meta,
    } = module.getTensorObj(filePath, options);

    const tensor = convertBufferToTensor(buffer, shape, meta.dType);

    return { tensor, shape, meta };
  }

  const { shape, meta } = ImageProcessing.processImage(filePath, options);
  const buffer = module.getTensorObj();

  const tensor = convertBufferToTensor(buffer, shape, meta.dType);

  return { tensor, shape, meta };
}
