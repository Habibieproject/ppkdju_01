library;

const String kPickerPlaceholder = 'Tekan tombol untuk memilih';

class PickerState {
  final List<String> availableNames;
  final List<String> eliminatedNames;
  final String selectedName;
  final bool isPicking;

  PickerState({
    List<String>? availableNames,
    List<String>? eliminatedNames,
    this.selectedName = kPickerPlaceholder,
    this.isPicking = false,
  }) : availableNames = List<String>.unmodifiable(availableNames ?? const []),
       eliminatedNames = List<String>.unmodifiable(eliminatedNames ?? const []);

  PickerState copyWith({
    List<String>? availableNames,
    List<String>? eliminatedNames,
    String? selectedName,
    bool? isPicking,
  }) {
    return PickerState(
      availableNames: availableNames ?? this.availableNames,
      eliminatedNames: eliminatedNames ?? this.eliminatedNames,
      selectedName: selectedName ?? this.selectedName,
      isPicking: isPicking ?? this.isPicking,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PickerState &&
        _listEquals(other.availableNames, availableNames) &&
        _listEquals(other.eliminatedNames, eliminatedNames) &&
        other.selectedName == selectedName &&
        other.isPicking == isPicking;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(availableNames),
    Object.hashAll(eliminatedNames),
    selectedName,
    isPicking,
  );

  @override
  String toString() {
    return 'PickerState('
        'availableNames: $availableNames, '
        'eliminatedNames: $eliminatedNames, '
        'selectedName: $selectedName, '
        'isPicking: $isPicking)';
  }
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

PickerState manualPick(PickerState state, String name) {
  if (state.isPicking ||
      state.availableNames.isEmpty ||
      !state.availableNames.contains(name)) {
    return state;
  }

  final newAvailable = List<String>.from(state.availableNames);
  final newEliminated = List<String>.from(state.eliminatedNames);

  newAvailable.remove(name);

  newEliminated.insert(0, name);

  return state.copyWith(
    availableNames: newAvailable,
    eliminatedNames: newEliminated,
    selectedName: name,
  );
}

PickerState resetState(PickerState state, List<String> allNames) {
  return state.copyWith(
    availableNames: List<String>.from(allNames),
    eliminatedNames: const <String>[],
    selectedName: kPickerPlaceholder,
  );
}

/// Persistence keys used when serializing [PickerState] to/from storage.
/// These match the SharedPreferences keys used by the screen wiring.
const String kSelectedNameKey = 'selectedName';
const String kAvailableNamesKey = 'availableNames';
const String kEliminatedNamesKey = 'eliminatedNames';

/// Builds a JSON-friendly persistence payload from [state].
///
/// The payload contains:
/// - [kSelectedNameKey] as a `String`,
/// - [kAvailableNamesKey] as a `List<String>`,
/// - [kEliminatedNamesKey] as a `List<String>`.
///
/// This is a pure function: it performs no I/O and does not mutate [state].
Map<String, dynamic> buildPersistencePayload(PickerState state) {
  return <String, dynamic>{
    kSelectedNameKey: state.selectedName,
    kAvailableNamesKey: List<String>.from(state.availableNames),
    kEliminatedNamesKey: List<String>.from(state.eliminatedNames),
  };
}

/// Attempts to reconstruct a [PickerState] from a persistence [payload].
///
/// Returns a [PickerState] preserving the exact order and content of the
/// stored lists and selected name when [payload] is valid. Returns `null`
/// when [payload] is `null`, missing required keys, or contains values of
/// unexpected types (e.g. non-string list elements). This is a pure function.
PickerState? pickerStateFromPayload(Map<String, dynamic>? payload) {
  if (payload == null) return null;
  if (!payload.containsKey(kSelectedNameKey) ||
      !payload.containsKey(kAvailableNamesKey) ||
      !payload.containsKey(kEliminatedNamesKey)) {
    return null;
  }

  final dynamic rawSelected = payload[kSelectedNameKey];
  if (rawSelected is! String) return null;

  final List<String>? available = _asStringList(payload[kAvailableNamesKey]);
  final List<String>? eliminated = _asStringList(payload[kEliminatedNamesKey]);
  if (available == null || eliminated == null) return null;

  return PickerState(
    availableNames: available,
    eliminatedNames: eliminated,
    selectedName: rawSelected,
  );
}

/// Loads a [PickerState] from a persistence [payload], falling back safely.
///
/// When [payload] is `null`, empty, or invalid/malformed, returns a fresh
/// state with `availableNames` set to a copy of [allNames], an empty
/// `eliminatedNames`, and `selectedName` set to [kPickerPlaceholder].
/// Otherwise returns the reconstructed state. This is a pure function and
/// performs no storage I/O.
PickerState loadPickerState(
  Map<String, dynamic>? payload,
  List<String> allNames,
) {
  if (payload != null && payload.isNotEmpty) {
    final PickerState? restored = pickerStateFromPayload(payload);
    if (restored != null) {
      return restored;
    }
  }
  return PickerState(
    availableNames: List<String>.from(allNames),
    eliminatedNames: const <String>[],
    selectedName: kPickerPlaceholder,
  );
}

/// Coerces [value] into a `List<String>` when possible, otherwise `null`.
///
/// Accepts a `List` whose every element is a `String`. Any other shape
/// (non-list, or list containing a non-string element) is considered invalid.
List<String>? _asStringList(dynamic value) {
  if (value is! List) return null;
  final result = <String>[];
  for (final element in value) {
    if (element is! String) return null;
    result.add(element);
  }
  return result;
}
