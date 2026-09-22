import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ppkdju_01/constant/app_color.dart';
import 'package:ppkdju_01/random_picker/picker_logic.dart';
import 'package:ppkdju_01/utils/button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RandomPickerScreen extends StatefulWidget {
  const RandomPickerScreen({super.key});

  @override
  State<RandomPickerScreen> createState() => _RandomPickerScreenState();
}

class _RandomPickerScreenState extends State<RandomPickerScreen> {
  List<String> allNames = [];
  List<String> availableNames = [];
  List<String> eliminatedNames = [];
  String selectedName = kPickerPlaceholder;
  bool isPicking = false;
  final Random random = Random();
  Timer? _timer;
  int _animationKey = 0;
  late ConfettiController confettiController;

  @override
  void initState() {
    super.initState();
    confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _initState();
  }

  Future<void> _initState() async {
    await _loadNamesFromAssets();
    await _loadSavedState();
  }

  Future<void> _loadNamesFromAssets() async {
    final String jsonString = await rootBundle.loadString('assets/names.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    allNames = List<String>.from(jsonData["names"]);
    // Jika tidak ada data yang disimpan, gunakan ini sebagai fallback awal
    if (availableNames.isEmpty && eliminatedNames.isEmpty) {
      setState(() {
        availableNames = List<String>.from(allNames);
      });
    }
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();

    // Bridge the separate SharedPreferences entries into a payload map so the
    // pure serialization/fallback logic in picker_logic.dart owns the parsing.
    final payload = <String, dynamic>{};
    final storedSelected = prefs.getString(kSelectedNameKey);
    final storedAvailable = prefs.getStringList(kAvailableNamesKey);
    final storedEliminated = prefs.getStringList(kEliminatedNamesKey);
    if (storedSelected != null) payload[kSelectedNameKey] = storedSelected;
    if (storedAvailable != null) payload[kAvailableNamesKey] = storedAvailable;
    if (storedEliminated != null) {
      payload[kEliminatedNamesKey] = storedEliminated;
    }

    final state = loadPickerState(payload.isEmpty ? null : payload, allNames);
    setState(() {
      selectedName = state.selectedName;
      availableNames = List<String>.from(state.availableNames);
      eliminatedNames = List<String>.from(state.eliminatedNames);
    });
  }

  /// Persists the current in-memory state to [SharedPreferences].
  ///
  /// The three keys are written together; on any failure the in-memory state
  /// (availableNames/eliminatedNames/selectedName) is left untouched and an
  /// error indication is shown to the user via a toast. This central handling
  /// satisfies the manual-pick (Req 5.3) and reset (Req 6.5) save-failure
  /// requirements for every call site without mutating state.
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = buildPersistencePayload(_currentPickerState());
      await prefs.setString(
        kSelectedNameKey,
        payload[kSelectedNameKey] as String,
      );
      await prefs.setStringList(
        kAvailableNamesKey,
        payload[kAvailableNamesKey] as List<String>,
      );
      await prefs.setStringList(
        kEliminatedNamesKey,
        payload[kEliminatedNamesKey] as List<String>,
      );
    } catch (_) {
      // Persistence failed: preserve the in-memory result as-is (do not mutate
      // any state fields) and surface an error indication to the user.
      Fluttertoast.showToast(msg: "Gagal menyimpan data");
    }
  }

  /// Builds an immutable [PickerState] snapshot from the current widget fields.
  PickerState _currentPickerState() {
    return PickerState(
      availableNames: availableNames,
      eliminatedNames: eliminatedNames,
      selectedName: selectedName,
      isPicking: isPicking,
    );
  }

  void pickRandomName() {
    if (availableNames.isEmpty || isPicking) return;

    setState(() {
      isPicking = true;
    });

    int count = 0;
    const int totalCycles = 20;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        selectedName = availableNames[random.nextInt(availableNames.length)];
        _animationKey++;
      });

      count++;
      if (count >= totalCycles) {
        timer.cancel();
        confettiController.play();
        _finalizePick();
      }
    });
  }

  void _finalizePick() {
    if (availableNames.isEmpty) return;

    setState(() {
      selectedName = availableNames.removeAt(
        random.nextInt(availableNames.length),
      );
      eliminatedNames.insert(0, selectedName);
      isPicking = false;
    });
    _saveState();
  }

  /// Validates a manual selection of [name] using the pure [manualPick] guard.
  ///
  /// Computes the next state via [manualPick]; if the guard rejects the request
  /// (picking in progress, no names available, or [name] not in
  /// `availableNames`) the state is unchanged and nothing is persisted. When a
  /// valid pick occurs, [finalizeManualPick] applies the result.
  void pickManualName(String name) {
    final current = _currentPickerState();
    final next = manualPick(current, name);
    if (next != current) {
      finalizeManualPick(name);
    }
  }

  /// Applies a valid manual pick of [name] to the widget state.
  ///
  /// Recomputes the result through [manualPick] (idempotent with the guard),
  /// commits it via [setState], plays the confetti effect, then persists state.
  void finalizeManualPick(String name) {
    final result = manualPick(_currentPickerState(), name);
    if (result == _currentPickerState()) return;

    setState(() {
      availableNames = List<String>.from(result.availableNames);
      eliminatedNames = List<String>.from(result.eliminatedNames);
      selectedName = result.selectedName;
    });
    confettiController.play();
    _saveState();
  }

  /// Opens the manual pick selector.
  ///
  /// Early-returns (no-op) when [isPicking] is true or [availableNames] is
  /// empty. Otherwise presents a modal bottom sheet containing a [ListView] of
  /// the current [availableNames] (preserving order, one tappable item per
  /// name). Tapping an item closes the sheet and processes the selection via
  /// [pickManualName].
  void showManualPickSelector() {
    if (isPicking || availableNames.isEmpty) return;

    // Snapshot the order/contents at open time for stable list rendering.
    final names = List<String>.from(availableNames);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          key: const Key('manualPickSelector'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Pilih nama secara manual",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.secondaryColor,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: names.length,
                  itemBuilder: (context, index) {
                    final name = names[index];
                    return ListTile(
                      leading: Icon(
                        Icons.person,
                        color: AppColor.secondaryColor,
                      ),
                      title: Text(name),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        pickManualName(name);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void resetPicker() {
    setState(() {
      availableNames = List<String>.from(allNames);
      eliminatedNames.clear();
      selectedName = kPickerPlaceholder;
    });
    _saveState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Random Picker",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColor.secondaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: Card(
                color: AppColor.secondaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            selectedName,
                            key: ValueKey('$selectedName-$_animationKey'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DefaultButton(
                color: AppColor.primaryColor,
                text: availableNames.isEmpty
                    ? "Semua nama sudah dipilih"
                    : isPicking
                    ? "Memilih..."
                    : "Pilih Nama",
                onPressed: isPicking || availableNames.isEmpty
                    ? null
                    : pickRandomName,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: DefaultButton(
                key: const Key('manualPickButton'),
                color: AppColor.secondaryColor,
                text: "Pilih Manual",
                onPressed: isPicking || availableNames.isEmpty
                    ? null
                    : showManualPickSelector,
              ),
            ),
            ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                AppColor.redColor,
                Colors.blue,
                AppColor.secondaryColor,
                AppColor.primaryColor,
              ],
            ),
            const SizedBox(height: 10),
            if (eliminatedNames.isNotEmpty)
              DefaultButton(
                color: AppColor.redColor,
                text: "Reset",
                onPressed: resetPicker,
              ),
            const SizedBox(height: 20),
            Expanded(
              child: eliminatedNames.isEmpty
                  ? Container()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nama yang sudah dipilih:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: eliminatedNames.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColor.secondaryColor,
                                  child: Text(
                                    "${eliminatedNames.length - index}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(eliminatedNames[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
