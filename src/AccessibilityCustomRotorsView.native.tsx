import { Platform, View, type ViewProps } from 'react-native';
import type { PropsWithChildren } from 'react';
import NativeRotorsView, {
  type CustomRotor,
} from './AccessibilityCustomRotorsViewNativeComponent';

export type Props = PropsWithChildren<
  ViewProps & {
    rotors?: ReadonlyArray<CustomRotor>;
  }
>;

export function AccessibilityCustomRotorsView(props: Props) {
  if (Platform.OS !== 'ios') {
    const { rotors: _rotors, ...rest } = props;
    return <View {...rest} />;
  }
  return <NativeRotorsView {...props} />;
}
