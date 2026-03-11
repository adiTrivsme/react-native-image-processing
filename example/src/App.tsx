import { Button, View, StyleSheet } from 'react-native';
import { launchImageLibrary } from 'react-native-image-picker';

import { getTensorObj } from 'react-native-image-processing';

export default function App() {
  async function handleOnPickPress() {
    const result = await launchImageLibrary({
      mediaType: 'photo',
      selectionLimit: 1,
    });

    const { uri: sourcePath } = result.assets?.[0] || {};

    if (sourcePath) {
      preprocessImage(sourcePath);
    }
  }

  const preprocessImage = (source: string) => {
    let start = new Date().getTime();

    const tensorObj = getTensorObj(source, {
      inputDimensions: {
        width: 224,
        height: 224,
      },
    });

    const { tensor } = tensorObj;

    let end = new Date().getTime();
    let time = end - start;

    console.log('time', time);

    console.log(tensor, tensor?.length);
  };

  return (
    <View style={styles.container}>
      <Button title="Pick Image" onPress={handleOnPickPress} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
