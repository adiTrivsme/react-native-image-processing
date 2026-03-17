## react-native-image-processing

**Native image‑to‑tensor preprocessing for React Native ML pipelines.**

This library loads an image on the native side (iOS/Android), applies common ML‑style preprocessing, and returns a JavaScript‑friendly tensor (plain `number[]`) plus metadata that you can feed directly into your model.

### Features

- **Native performance**: resize, crop and convert to a tensor on the native side.
- **Configurable preprocessing**: input size, color format, normalization, layout, and more.
- **Simple API**: call `getTensorObj(filePath, options)` from JS and receive `{ tensor, shape, meta }`.

---

## Installation

Using **npm**:

```sh
npm install react-native-image-processing
```

Using **yarn**:

```sh
yarn add react-native-image-processing
```

### iOS

From the `ios` directory of your app:

```sh
cd ios
pod install
```

Then rebuild your app:

```sh
cd ..
npx react-native run-ios
```

### Android

No extra manual steps should be required for autolinking. Just rebuild:

```sh
npx react-native run-android
```

---

## API

### `getTensorObj(filePath, options)`

Synchronously preprocesses an image and returns a tensor plus metadata.

```ts
import { getTensorObj } from 'react-native-image-processing';

const result = getTensorObj(filePath, {
  inputDimensions: { width: 224, height: 224 },
  // optional:
  // colorFormat: 'RGB' | 'BGR' | 'Grayscale'
  // normalization: 'zeroToOne' | 'none' | 'minusOneToOne' | 'meanStd'
  // mean: { r: number; g: number; b: number }
  // std: { r: number; g: number; b: number }
  // outDType: 'float32' | 'uint8' | 'int8'
  // resizeStrategy: 'aspectFill' | 'stretch' | 'aspectFit'
  // tensorLayout: 'NHWC' | 'NCHW'
  // orientationHandling: 'respectExif' | 'ignoreExif'
  // alphaHandling: 'dropAlpha' | 'premultiply'
});

const { tensor, shape, meta } = result;
```

- **`filePath`**: string URI/path to the image (e.g. from `react-native-image-picker`).
- **`tensor`**: `number[]` created from a native `Float32Array` buffer.
- **`shape`**: numeric array describing the tensor dimensions, typically `[N, H, W, C]` or `[N, C, H, W]` depending on `tensorLayout`.
- **`meta`**: implementation‑specific metadata (original size, orientation, etc.).

---

## Example

Basic usage with `react-native-image-picker` to load a photo and inspect the tensor:

```ts
import { Button, View } from 'react-native';
import { launchImageLibrary } from 'react-native-image-picker';
import { getTensorObj } from 'react-native-image-processing';

function App() {
  const handlePick = async () => {
    const result = await launchImageLibrary({
      mediaType: 'photo',
      selectionLimit: 1,
    });

    const { uri: sourcePath } = result.assets?.[0] || {};
    if (!sourcePath) {
      return;
    }

    const { tensor, shape, meta } = getTensorObj(sourcePath, {
      inputDimensions: { width: 224, height: 224 },
    });

    console.log('Shape:', shape);
    console.log('First 10 values:', tensor.slice(0, 10));
    console.log('Meta:', meta);
  };

  return (
    <View>
      <Button title="Pick image" onPress={handlePick} />
    </View>
  );
}
```

Use the returned `tensor` directly as model input.

---

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

---

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
