import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  install: () => boolean;
  uninstall: () => boolean;
}

export default TurboModuleRegistry.getEnforcing<Spec>('ImageProcessing');
