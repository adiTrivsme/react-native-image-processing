interface Tensor {
  tensor: any;
  shape: Array<number>;
  meta: Record<string, string>;
}

type ImageProcessingModule = {
  sayHello: () => string;
  getTensorObj: (filePath: string, options: object) => Tensor;
};

type GlobalWithImageProcessing = typeof globalThis & {
  __imageProcessing__?: ImageProcessingModule;
};
