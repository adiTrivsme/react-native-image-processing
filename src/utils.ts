export function convertBufferToTensor(
  buffer: ArrayBuffer,
  shape: number[],
  outDType: 'float32' | 'uint8' | 'int8'
) {
  if (!buffer) {
    throw new Error('Tensor buffer not available');
  }

  const elementCount = shape.reduce((a, b) => a * b, 1);

  let typedArray;

  switch (outDType) {
    case 'uint8':
      typedArray = new Uint8Array(buffer, 0, elementCount);
      break;
    case 'int8':
      typedArray = new Int8Array(buffer, 0, elementCount);
      break;
    default:
      typedArray = new Float32Array(buffer, 0, elementCount);
      break;
  }

  // const typedArray = new Float32Array(buffer, 0, elementCount);

  const tensor = Array.from(typedArray);

  return tensor;
}
