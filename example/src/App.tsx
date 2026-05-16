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

// Demo: a 5-day weather forecast.
//
// Each day card contains several lines (condition, high/low, wind, humidity).
// With VoiceOver you'd normally have to swipe through every line of every day
// just to get to "Friday". The custom rotor lets the user jump directly between
// day headings, and a second rotor lets them jump only to rainy days.
//
// Try it: enable VoiceOver, focus inside the scroll view, then rotate two
// fingers and pick "Days" or "Rainy days", then swipe down/up.

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
  {
    id: 'mon',
    day: 'Monday',
    condition: 'Sunny',
    high: 24,
    low: 13,
    wind: '8 km/h NW',
    humidity: '42%',
  },
  {
    id: 'tue',
    day: 'Tuesday',
    condition: 'Cloudy',
    high: 21,
    low: 14,
    wind: '12 km/h W',
    humidity: '58%',
  },
  {
    id: 'wed',
    day: 'Wednesday',
    condition: 'Rain',
    high: 17,
    low: 12,
    wind: '18 km/h SW',
    humidity: '81%',
  },
  {
    id: 'thu',
    day: 'Thursday',
    condition: 'Storm',
    high: 16,
    low: 11,
    wind: '34 km/h S',
    humidity: '88%',
  },
  {
    id: 'fri',
    day: 'Friday',
    condition: 'Cloudy',
    high: 19,
    low: 12,
    wind: '10 km/h SE',
    humidity: '64%',
  },
];

const conditionEmoji: Record<Forecast['condition'], string> = {
  Sunny: '☀',
  Cloudy: '⛅',
  Rain: '🌧',
  Storm: '⛈',
};

export default function App() {
  const daysRotor: CustomRotor = {
    name: 'Days',
    items: forecast.map((f) => ({
      testID: `day-${f.id}`,
      label: f.day,
    })),
  };

  const rainyRotor: CustomRotor = {
    name: 'Rainy days',
    items: forecast
      .filter((f) => f.condition === 'Rain' || f.condition === 'Storm')
      .map((f) => ({
        testID: `day-${f.id}`,
        label: `${f.day} — ${f.condition}`,
      })),
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
              Custom rotors are iOS-only. On Android this renders without rotor
              support.
            </Text>
          )}
          {forecast.map((f) => (
            <View key={f.id} style={styles.card}>
              <View
                testID={`day-${f.id}`}
                accessible
                accessibilityRole="header"
                accessibilityLabel={`${f.day}, ${f.condition}, high ${f.high}, low ${f.low}`}
              >
                <Text style={styles.day}>
                  {conditionEmoji[f.condition]}  {f.day}
                </Text>
              </View>
              <Text style={styles.condition}>{f.condition}</Text>
              <View style={styles.row}>
                <Text style={styles.temp}>
                  {f.high}° / <Text style={styles.tempLow}>{f.low}°</Text>
                </Text>
              </View>
              <View style={styles.metaRow}>
                <Text style={styles.meta}>Wind {f.wind}</Text>
                <Text style={styles.meta}>Humidity {f.humidity}</Text>
              </View>
            </View>
          ))}
          <Text style={styles.footer}>
            With VoiceOver on: rotate two fingers to open the rotor wheel, pick
            “Days” or “Rainy days”, then swipe down or up.
          </Text>
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
    fontSize: 13,
    color: '#8a6d3b',
    backgroundColor: '#fcf8e3',
    padding: 10,
    borderRadius: 6,
    marginBottom: 8,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowOffset: { width: 0, height: 1 },
    shadowRadius: 3,
    elevation: 1,
  },
  day: { fontSize: 22, fontWeight: '600' },
  condition: { fontSize: 15, color: '#555', marginTop: 2 },
  row: { flexDirection: 'row', alignItems: 'baseline', marginTop: 8 },
  temp: { fontSize: 32, fontWeight: '300' },
  tempLow: { color: '#888' },
  metaRow: { flexDirection: 'row', gap: 16, marginTop: 8 },
  meta: { fontSize: 13, color: '#666' },
  footer: {
    fontSize: 12,
    color: '#666',
    textAlign: 'center',
    marginTop: 16,
    paddingHorizontal: 8,
  },
});
