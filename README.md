# react-native-accessibility-custom-rotors

iOS **VoiceOver Custom Rotors** support for React Native — exposes
[`UIAccessibilityCustomRotor`](https://developer.apple.com/documentation/uikit/uiaccessibilitycustomrotor)
through a wrapper component, so you can let VoiceOver users jump directly
between meaningful items (headings, errors, form fields, list rows, …)
without swiping through every element in between.

Addresses
[react-native-community/discussions-and-proposals#779](https://github.com/react-native-community/discussions-and-proposals/issues/779).

## Status

v1 — **iOS only**, static element lists.

Android is not supported (TalkBack has no equivalent of `UIAccessibilityCustomRotor`).
On Android / Web the component renders its children inside a plain `View`, so
shared JSX won't crash — but no rotor will be exposed.

## Requirements

- React Native **0.74+** with the **new architecture** (Fabric + Codegen) enabled.
- iOS 13+.

## Install

Not on npm yet — install directly from GitHub:

```sh
npm install github:oaron/react-native-accessibility-custom-rotors#v0.1.3
```

Then rebuild the iOS app so the native component is compiled in:

```sh
cd ios && pod install && cd ..
npx react-native run-ios
# or, with Expo dev client: eas build --profile development --platform ios
```

> Reloading the JS bundle is **not enough** — the rotor logic lives in a
> Fabric native component (`.mm`), so any version bump requires a fresh
> native build.

## Usage

Wrap any subtree that should expose custom rotors. Each rotor item references
a target view by **`testID`** — set the same `testID` on the descendant
element you want VoiceOver to focus when the user navigates to that rotor
entry. Mark each target with `accessible` and an `accessibilityLabel` so
VoiceOver treats it as a single focusable element with something to read out.

> **Why `testID`, not `nativeID`?** In RN's new architecture, the `testID`
> prop is what populates `UIView.accessibilityIdentifier` on iOS — `nativeID`
> is a separate, internal layout tag and is **not** visible to VoiceOver's
> identifier lookup. Always use `testID` on the target view.

### Minimal example

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

### Full demo: 5-day weather forecast

A complete working app that exposes two rotors:

- **Days** — jumps between every weekday heading (Mon, Tue, Wed, …).
- **Rainy days** — visits only days whose condition is Rain or Storm.

```tsx
import {
  Platform,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import {
  AccessibilityCustomRotorsView,
  type CustomRotor,
} from 'react-native-accessibility-custom-rotors';

type Forecast = {
  id: string;
  day: string;
  condition: 'Sunny' | 'Cloudy' | 'Rain' | 'Storm';
  high: number;
  low: number;
  wind: string;
  humidity: string;
};

const forecast: Forecast[] = [
  { id: 'mon', day: 'Monday',    condition: 'Sunny',  high: 24, low: 13, wind: '8 km/h NW',  humidity: '42%' },
  { id: 'tue', day: 'Tuesday',   condition: 'Cloudy', high: 21, low: 14, wind: '12 km/h W',  humidity: '58%' },
  { id: 'wed', day: 'Wednesday', condition: 'Rain',   high: 17, low: 12, wind: '18 km/h SW', humidity: '81%' },
  { id: 'thu', day: 'Thursday',  condition: 'Storm',  high: 16, low: 11, wind: '34 km/h S',  humidity: '88%' },
  { id: 'fri', day: 'Friday',    condition: 'Cloudy', high: 19, low: 12, wind: '10 km/h SE', humidity: '64%' },
];

const conditionEmoji: Record<Forecast['condition'], string> = {
  Sunny: '☀', Cloudy: '⛅', Rain: '🌧', Storm: '⛈',
};

export default function App() {
  const daysRotor: CustomRotor = {
    name: 'Days',
    items: forecast.map((f) => ({ testID: `day-${f.id}`, label: f.day })),
  };

  const rainyRotor: CustomRotor = {
    name: 'Rainy days',
    items: forecast
      .filter((f) => f.condition === 'Rain' || f.condition === 'Storm')
      .map((f) => ({ testID: `day-${f.id}`, label: `${f.day} — ${f.condition}` })),
  };

  return (
    <SafeAreaView style={styles.flex}>
      <AccessibilityCustomRotorsView
        style={styles.flex}
        rotors={[daysRotor, rainyRotor]}
      >
        <ScrollView contentContainerStyle={styles.container}>
          <Text accessibilityRole="header" style={styles.title}>
            Weekly forecast
          </Text>
          {Platform.OS !== 'ios' && (
            <Text style={styles.note}>
              Custom rotors are iOS-only. On Android / Web this renders without
              rotor support.
            </Text>
          )}
          {forecast.map((f) => (
            <View key={f.id} style={styles.card}>
              <View
                testID={`day-${f.id}`}
                accessible
                accessibilityLabel={`${f.day}, ${f.condition}, high ${f.high}, low ${f.low}`}
              >
                <Text style={styles.day}>
                  {conditionEmoji[f.condition]}  {f.day}
                </Text>
              </View>
              <Text style={styles.condition}>{f.condition}</Text>
              <Text style={styles.temp}>
                {f.high}° / <Text style={styles.tempLow}>{f.low}°</Text>
              </Text>
              <View style={styles.metaRow}>
                <Text style={styles.meta}>Wind {f.wind}</Text>
                <Text style={styles.meta}>Humidity {f.humidity}</Text>
              </View>
            </View>
          ))}
        </ScrollView>
      </AccessibilityCustomRotorsView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: '#f5f5f7' },
  container: { padding: 16, paddingBottom: 48, gap: 12 },
  title: { fontSize: 28, fontWeight: '700', marginBottom: 8 },
  note: {
    fontSize: 13, color: '#8a6d3b', backgroundColor: '#fcf8e3',
    padding: 10, borderRadius: 6, marginBottom: 8,
  },
  card: {
    backgroundColor: '#fff', borderRadius: 12, padding: 16,
    shadowColor: '#000', shadowOpacity: 0.05,
    shadowOffset: { width: 0, height: 1 }, shadowRadius: 3, elevation: 1,
  },
  day: { fontSize: 22, fontWeight: '600' },
  condition: { fontSize: 15, color: '#555', marginTop: 2 },
  temp: { fontSize: 32, fontWeight: '300', marginTop: 8 },
  tempLow: { color: '#888' },
  metaRow: { flexDirection: 'row', gap: 16, marginTop: 8 },
  meta: { fontSize: 13, color: '#666' },
});
```

### Trying it out with VoiceOver

1. Build and launch the app on a real iOS device.
2. Settings → Accessibility → VoiceOver → on (or use the triple-click side-button shortcut).
3. Focus anywhere inside the wrapper.
4. Rotate two fingers on the screen — the system rotor wheel appears.
5. Pick **Days** or **Rainy days**.
6. Swipe down (next) or up (previous) — focus jumps between the items in order.

## API

### `<AccessibilityCustomRotorsView>`

| prop | type | notes |
|---|---|---|
| `rotors` | `ReadonlyArray<CustomRotor>` | The rotors to expose while VoiceOver focus is inside this subtree. |
| `...ViewProps` | `ViewProps` | Standard `View` props (`style`, `children`, etc.). |

### `CustomRotor`

| field | type | notes |
|---|---|---|
| `name` | `string` | Shown in the VoiceOver rotor wheel. |
| `items` | `ReadonlyArray<CustomRotorItem>` | Ordered list — VoiceOver iterates in this order. |

### `CustomRotorItem`

| field | type | notes |
|---|---|---|
| `testID` | `string` | Must match the `testID` prop on the target view (which RN maps to iOS `accessibilityIdentifier`). |
| `label` | `string` | Used as the target's `accessibilityLabel` if it doesn't already have one. |

## How it maps to iOS

The wrapper view sets
[`accessibilityCustomRotors`](https://developer.apple.com/documentation/objectivec/nsobject/1615159-accessibilitycustomrotors)
on itself. iOS walks up the accessibility tree from the focused element to find
rotors, so the wrapper is active whenever VoiceOver focus is inside its subtree.

For each rotor entry, an
[`UIAccessibilityCustomRotorItemResult`](https://developer.apple.com/documentation/uikit/uiaccessibilitycustomrotoritemresult)
targets the descendant view whose `accessibilityIdentifier` matches the
`testID`. The descendant must be a focusable accessibility element
(`accessible={true}`) for VoiceOver to land on it and speak its label.

## v1 limitations

- **Static lists**: the rotor walks the elements in the order you specify.
  Updates flush through React state, so re-rendering with a new `rotors`
  array works, but the predicate is not a live JS callback.
- **Subtree only**: items must be descendants of the wrapper. Lookup is by
  `accessibilityIdentifier`, so anything outside the wrapper is invisible.
- **iOS only**: Android / Web fall back to a plain `<View/>` — no rotor.

## Example app

The `example/` workspace contains the weather-forecast demo above as a
runnable React Native project. The reference for this pattern is the SwiftUI
sample in
[cvs-health/ios-swiftui-accessibility-techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques)
— same idea, but realised through this RN wrapper instead of SwiftUI's
`.accessibilityRotor` modifier.

## Roadmap

- v2: JS-defined predicate (dynamic rotor, async JSI call).
- Consider upstreaming to React Native core as an `accessibilityCustomRotors`
  prop on `View` once the API has been validated in the wild.

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)

## License

MIT
