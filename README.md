# react-native-accessibility-custom-rotors

iOS **VoiceOver Custom Rotors** support for React Native — exposes
[`UIAccessibilityCustomRotor`](https://developer.apple.com/documentation/uikit/uiaccessibilitycustomrotor)
through a wrapper component.

Addresses
[react-native-community/discussions-and-proposals#779](https://github.com/react-native-community/discussions-and-proposals/issues/779).

## Status

v1 — **iOS only**, static element lists.

Android is not supported (TalkBack has no equivalent of `UIAccessibilityCustomRotor`).
On Android / Web the component renders its children inside a plain `View`, so
shared JSX won't crash — but no rotor will be exposed.

## Install

```sh
npm install react-native-accessibility-custom-rotors
cd ios && pod install
```

Requires React Native with the **new architecture** (Fabric + Codegen) enabled.

## Usage

Wrap any subtree that should expose custom rotors. Rotor items reference target
views by **`testID`** — set the same `testID` on the descendant element you
want VoiceOver to focus when the user navigates to that rotor entry. Also mark
the target with `accessible` (and an `accessibilityLabel`) so VoiceOver
recognises it as a single focusable element.

> **Why `testID`, not `nativeID`?** In RN's new architecture, the `testID`
> prop is what populates `UIView.accessibilityIdentifier` on iOS — `nativeID`
> is a separate, internal layout tag and is **not** visible to VoiceOver's
> identifier lookup. Use `testID` on the target view.

```tsx
import {
  AccessibilityCustomRotorsView,
  type CustomRotor,
} from 'react-native-accessibility-custom-rotors';

const rotors: CustomRotor[] = [
  {
    name: 'Headings',
    items: [
      { testID: 'heading-1', label: 'Introduction' },
      { testID: 'heading-2', label: 'Features' },
    ],
  },
  {
    name: 'Errors',
    items: [{ testID: 'field-email', label: 'Email is invalid' }],
  },
];

<AccessibilityCustomRotorsView style={{ flex: 1 }} rotors={rotors}>
  <ScrollView>
    <View testID="heading-1" accessible accessibilityRole="header"
          accessibilityLabel="Introduction">
      <Text>Introduction</Text>
    </View>
    {/* ... */}
    <TextInput testID="field-email" accessibilityLabel="Email" />
  </ScrollView>
</AccessibilityCustomRotorsView>
```

### `CustomRotor`

| field | type | notes |
|---|---|---|
| `name` | `string` | Shown in the VoiceOver rotor wheel |
| `items` | `CustomRotorItem[]` | Ordered list — VoiceOver iterates in this order |

### `CustomRotorItem`

| field | type | notes |
|---|---|---|
| `testID` | `string` | Must match the `testID` prop you set on the target view (maps to iOS `accessibilityIdentifier`) |
| `label` | `string` | Spoken if the target view has no `accessibilityLabel` of its own |

## How it maps to iOS

The wrapper view sets
[`accessibilityCustomRotors`](https://developer.apple.com/documentation/objectivec/nsobject/1615159-accessibilitycustomrotors)
on itself. iOS walks up the accessibility tree from the focused element to find
rotors, so the wrapper is active whenever VoiceOver focus is inside its subtree.

For each rotor entry, an
[`UIAccessibilityCustomRotorItemResult`](https://developer.apple.com/documentation/uikit/uiaccessibilitycustomrotoritemresult)
targets the descendant view whose `accessibilityIdentifier` matches the
`testID`.

## Testing with VoiceOver

1. Build the example app on an iOS device.
2. Settings → Accessibility → VoiceOver → on (or triple-click side button shortcut).
3. Open the app.
4. Rotate two fingers on the screen — the system rotor wheel appears.
5. Pick **Headings** or **Errors**.
6. Swipe down/up — focus jumps between the items in order.

## v1 limitations

- **Static lists**: the rotor walks the elements in the order you specify.
  Updates flush through React state, so re-rendering with a new `rotors`
  array works, but the predicate is not a live JS callback.
- **Subtree only**: items must be descendants of the wrapper. The lookup is
  by `accessibilityIdentifier`, so anything outside the wrapper is invisible.
- **iOS only**: Android / Web fall back to a plain `<View/>` — no rotor.

## Example app

`example/` contains a 5-day weather forecast with two rotors:

- **Days** — jumps between weekday headings (Mon, Tue, Wed…).
- **Rainy days** — jumps only to days whose condition is Rain or Storm.

The reference for this pattern is the SwiftUI sample in
[cvs-health/ios-swiftui-accessibility-techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques)
— same idea, but realised through this React Native wrapper instead of native
SwiftUI `.accessibilityRotor`.

## Roadmap

- v2: JS-defined predicate (dynamic rotor, async JSI call).
- Consider upstreaming to React Native core as `accessibilityCustomRotors`
  prop on `View` once API is validated.

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)

## License

MIT
