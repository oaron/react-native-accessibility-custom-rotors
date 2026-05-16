import { codegenNativeComponent, type ViewProps } from 'react-native';
import type { HostComponent } from 'react-native';

export type CustomRotorItem = Readonly<{
  // Match this against the `testID` prop you set on the target view.
  // (RN Fabric maps `testID` — not `nativeID` — to iOS `accessibilityIdentifier`.)
  testID: string;
  label: string;
}>;

export type CustomRotor = Readonly<{
  name: string;
  items: ReadonlyArray<CustomRotorItem>;
}>;

export interface NativeProps extends ViewProps {
  rotors?: ReadonlyArray<CustomRotor>;
}

export default codegenNativeComponent<NativeProps>(
  'AccessibilityCustomRotorsView'
) as HostComponent<NativeProps>;
