export function convertBufferToTensor(
  buffer: ArrayBuffer,
  length: number | undefined
) {
  if (!buffer) {
    throw new Error('Tensor buffer not available');
  }

  const floatArray = new Float32Array(buffer, 0, length);

  const tensor = Array.from(floatArray);

  return tensor;
}
