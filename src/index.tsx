import ImageProcessing from './NativeImageProcessing';

const g = globalThis as GlobalWithImageProcessing;

if (!g.__imageProcessing__) {
  ImageProcessing.install();
}

const module = g.__imageProcessing__!;

export function sayHello(): string {
  return module.sayHello();
}

export function getTensorObj(filePath: string, options: Object): Tensor {
  return module.getTensorObj(filePath, options);
}
