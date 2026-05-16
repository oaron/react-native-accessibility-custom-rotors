import type { PropsWithChildren } from 'react';
import type { ViewProps } from 'react-native';
import type { CustomRotor } from './AccessibilityCustomRotorsViewNativeComponent';

export type Props = PropsWithChildren<
  ViewProps & {
    rotors?: ReadonlyArray<CustomRotor>;
  }
>;

export function AccessibilityCustomRotorsView(_props: Props): never {
  throw new Error(
    "'react-native-accessibility-custom-rotors' is only supported on native platforms."
  );
}
