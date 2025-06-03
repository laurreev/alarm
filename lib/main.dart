import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initialIntent;
  try {
    initialIntent = await MethodChannel('alarm_channel')
        .invokeMethod<String>('getInitialIntent')
        .timeout(const Duration(seconds: 2), onTimeout: () => null);
  } catch (e) {
    initialIntent = null;
  }
  runApp(AlarmClockApp(initialIntent: initialIntent));
}

enum AppTheme { dark, light, pink }

extension AppThemeExtension on AppTheme {
  String get name => toString().split('.').last;
  static AppTheme fromName(String name) {
    switch (name) {
      case 'light':
        return AppTheme.light;
      case 'pink':
        return AppTheme.pink;
      default:
        return AppTheme.dark;
    }
  }
}

class ThemeNotifier extends ValueNotifier<AppTheme> {
  ThemeNotifier(AppTheme value) : super(value);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme') ?? 'dark';
    value = AppThemeExtension.fromName(themeName);
  }

  Future<void> saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.name);
  }

  void setTheme(AppTheme theme) {
    value = theme;
    saveTheme(theme);
  }
}

class AlarmClockApp extends StatefulWidget {
  final String? initialIntent;
  const AlarmClockApp({super.key, this.initialIntent});
  static final ThemeNotifier themeNotifier = ThemeNotifier(AppTheme.dark);

  @override
  State<AlarmClockApp> createState() => _AlarmClockAppState();
}

class _AlarmClockAppState extends State<AlarmClockApp> {
  bool showAlarmScreen = false;
  String? alarmLabel;

  @override
  void initState() {
    super.initState();
    AlarmClockApp.themeNotifier.loadTheme();
    if (widget.initialIntent == 'alarm_triggered') {
      setState(() {
        showAlarmScreen = true;
        alarmLabel = null; // TODO: parse label if available
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybePromptBackgroundActivity();
      });
    }
  }

  Future<void> _maybePromptBackgroundActivity() async {
    if (!Platform.isAndroid) return;
    // Only prompt on Android
    // Optionally, store a flag in SharedPreferences to only show once
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('background_prompt_shown') ?? false;
    if (shown) return;
    await Future.delayed(const Duration(seconds: 1)); // Wait for UI
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow Background Activity'),
        content: const Text(
          'To ensure alarms work reliably, please allow background activity for this app in system settings. This prevents the system from stopping alarms when the app is not in use.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openBackgroundSettings();
              await prefs.setBool('background_prompt_shown', true);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _openBackgroundSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.ACTION_APPLICATION_DETAILS_SETTINGS',
      data: 'package:com.example.alarm',
    );
    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: AlarmClockApp.themeNotifier,
      builder: (context, appTheme, _) {
        ThemeMode mode;
        ThemeData currentTheme;
        ThemeData darkTheme = ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D1117),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF161B22),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          cardColor: const Color(0xFF1E293B),
          iconTheme: const IconThemeData(color: Colors.blue),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.all(Colors.blue),
            trackColor: MaterialStateProperty.all(Colors.blue[200]),
          ),
          popupMenuTheme: const PopupMenuThemeData(
            color: Color(0xFF1E293B),
            textStyle: TextStyle(color: Colors.white),
          ),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
            secondary: Colors.blueAccent,
            background: const Color(0xFF0D1117),
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        );
        switch (appTheme) {
          case AppTheme.light:
            mode = ThemeMode.light;
            currentTheme = ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF3B82F6),
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              cardColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.blue),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black87),
                titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.all(Colors.blue),
                trackColor: MaterialStateProperty.all(Colors.blue[200]),
              ),
              popupMenuTheme: const PopupMenuThemeData(
                color: Colors.white,
                textStyle: TextStyle(color: Colors.black),
              ),
              colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
                secondary: Colors.blueAccent,
                background: const Color(0xFFF8FAFC),
                surface: Colors.white,
                onSurface: Colors.black,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            );
            break;
          case AppTheme.pink:
            mode = ThemeMode.light;
            currentTheme = ThemeData(
              primarySwatch: Colors.pink,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFFFF1F3),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF472B6),
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              cardColor: const Color(0xFFFFE4EC),
              iconTheme: const IconThemeData(color: Colors.pink),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFFAD1457)),
                bodyMedium: TextStyle(color: Color(0xFFD81B60)),
                titleLarge: TextStyle(color: Color(0xFFAD1457), fontWeight: FontWeight.bold),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.all(Colors.pink),
                trackColor: MaterialStateProperty.all(Colors.pink[200]),
              ),
              popupMenuTheme: const PopupMenuThemeData(
                color: Color(0xFFFFE4EC),
                textStyle: TextStyle(color: Color(0xFFAD1457)),
              ),
              colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.pink).copyWith(
                secondary: Colors.pinkAccent,
                background: const Color(0xFFFFF1F3),
                surface: Color(0xFFFFE4EC),
                onSurface: Color(0xFFAD1457),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            );
            break;
          default:
            mode = ThemeMode.dark;
            currentTheme = darkTheme;
        }
        return MaterialApp(
          title: 'Alarm Clock',
          theme: currentTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          home: showAlarmScreen
              ? AlarmRingScreen(label: alarmLabel)
              : const AlarmClockScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class Alarm {
  String id;
  TimeOfDay time;
  String label;
  bool isEnabled;
  List<bool> weekdays; // Mon-Sun

  Alarm({
    required this.id,
    required this.time,
    required this.label,
    this.isEnabled = true,
    List<bool>? weekdays,
  }) : weekdays = weekdays ?? List.filled(7, true);

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': time.hour,
    'minute': time.minute,
    'label': label,
    'isEnabled': isEnabled,
    'weekdays': weekdays,
  };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
    id: json['id'],
    time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    label: json['label'],
    isEnabled: json['isEnabled'],
    weekdays: List<bool>.from(json['weekdays']),
  );
}

class AlarmClockScreen extends StatefulWidget {
  const AlarmClockScreen({super.key});

  @override
  State<AlarmClockScreen> createState() => _AlarmClockScreenState();
}

class _AlarmClockScreenState extends State<AlarmClockScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  List<Alarm> _alarms = [];

  // Notification plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestNotificationPermission();
    _startTimer();
    _loadAlarms();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    // Check for exact alarm permission (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exact Alarms Required'),
            content: const Text('To ensure alarms work reliably, please allow exact alarms in system settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final intent = const AndroidIntent(
                    action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
                  );
                  await intent.launch();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  // Schedules a notification for the alarm
  Future<void> _scheduleAlarmNotification(Alarm alarm) async {
    if (!alarm.isEnabled) return;
    final now = DateTime.now();
    // Find the next occurrence based on selected weekdays
    DateTime? nextAlarm;
    for (int addDays = 0; addDays < 7; addDays++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.time.hour,
        alarm.time.minute,
      ).add(Duration(days: addDays));
      final weekdayIndex = (candidate.weekday + 5) % 7; // Mon=0, Sun=6
      if (alarm.weekdays[weekdayIndex] && candidate.isAfter(now)) {
        nextAlarm = candidate;
        break;
      }
    }
    if (nextAlarm == null) return;
    // Use flutterLocalNotificationsPlugin.show as a fallback (immediate notification, for demo/testing only)
    // For real scheduling, use only native alarm logic as implemented
    // Optionally, you can comment out or remove this block if only native alarms are desired
    // await flutterLocalNotificationsPlugin.show(
    //   alarm.id.hashCode,
    //   'Alarm',
    //   alarm.label,
    //   const NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       'alarm_channel',
    //       'Alarms',
    //       channelDescription: 'Alarm notifications',
    //       importance: Importance.max,
    //       priority: Priority.high,
    //       playSound: true,
    //       enableVibration: true,
    //       icon: '@mipmap/ic_launcher',
    //     ),
    //   ),
    //   payload: alarm.id,
    // );
    // Instead, rely on native alarm logic for actual alarm firing
    return;
  }

  // Cancels a scheduled notification for the alarm
  Future<void> _cancelAlarmNotification(Alarm alarm) async {
    await flutterLocalNotificationsPlugin.cancel(alarm.id.hashCode);
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    setState(() {
      _alarms = alarmsJson
          .map((json) => Alarm.fromJson(jsonDecode(json)))
          .toList();
    });
    // Reschedule all enabled alarms
    for (final alarm in _alarms) {
      if (alarm.isEnabled) {
        _scheduleAlarmNotification(alarm);
      }
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms
        .map((alarm) => jsonEncode(alarm.toJson()))
        .toList();
    await prefs.setStringList('alarms', alarmsJson);
    // Reschedule all alarms
    for (final alarm in _alarms) {
      await _cancelAlarmNotification(alarm);
      if (alarm.isEnabled) {
        // Find the next occurrence based on selected weekdays
        final now = DateTime.now();
        DateTime? nextAlarm;
        for (int addDays = 0; addDays < 7; addDays++) {
          final candidate = DateTime(
            now.year,
            now.month,
            now.day,
            alarm.time.hour,
            alarm.time.minute,
          ).add(Duration(days: addDays));
          final weekdayIndex = (candidate.weekday + 5) % 7; // Mon=0, Sun=6
          if (alarm.weekdays[weekdayIndex] && candidate.isAfter(now)) {
            nextAlarm = candidate;
            break;
          }
        }
        if (nextAlarm != null) {
          await setNativeAlarm(nextAlarm, alarm.label, alarm.id);
        }
        await _scheduleAlarmNotification(alarm);
      }
    }
  }

  void _addAlarm() {
    showDialog(
      context: context,
      builder: (context) => AlarmDialog(
        onSave: (alarm) async {
          setState(() {
            _alarms.add(alarm);
          });
          await _saveAlarms();
        },
      ),
    );
  }

  void _editAlarm(int index) {
    showDialog(
      context: context,
      builder: (context) => AlarmDialog(
        alarm: _alarms[index],
        onSave: (alarm) async {
          setState(() {
            _alarms[index] = alarm;
          });
          await _saveAlarms();
        },
      ),
    );
  }

  void _deleteAlarm(int index) async {
    await _cancelAlarmNotification(_alarms[index]);
    setState(() {
      _alarms.removeAt(index);
    });
    await _saveAlarms();
  }

  void _toggleAlarm(int index) async {
    setState(() {
      _alarms[index].isEnabled = !_alarms[index].isEnabled;
    });
    await _saveAlarms();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alarm Clock',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: Icon(Icons.alarm, color: Theme.of(context).colorScheme.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Section: Current Time Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              // Optionally, you can use a gradient based on theme colors
              // gradient: LinearGradient(
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              //   colors: [
              //     Theme.of(context).colorScheme.surface,
              //     Theme.of(context).colorScheme.background,
              //   ],
              // ),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, y').format(_currentTime),
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  DateFormat('hh:mm:ss a').format(_currentTime),
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w200,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  DateFormat('a').format(_currentTime),
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          // Middle Section: Alarms List
          Expanded(
            child: _alarms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.alarm,
                          size: 64,
                          color: Theme.of(context).disabledColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No alarms set',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).disabledColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = _alarms[index];
                      return Card(
                        color: Theme.of(context).cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(
                            alarm.isEnabled ? Icons.alarm : Icons.alarm_off,
                            size: 32,
                            color: alarm.isEnabled 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).disabledColor,
                          ),
                          title: Text(
                            alarm.time.format(context),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: alarm.isEnabled 
                                  ? Theme.of(context).textTheme.bodyLarge?.color 
                                  : Theme.of(context).disabledColor,
                            ),
                          ),
                          subtitle: Text(
                            alarm.label,
                            style: TextStyle(
                              fontSize: 16,
                              color: alarm.isEnabled 
                                  ? Theme.of(context).textTheme.bodyMedium?.color 
                                  : Theme.of(context).disabledColor.withOpacity(0.7),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: alarm.isEnabled,
                                onChanged: (_) => _toggleAlarm(index),
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                              PopupMenuButton(
                                icon: Icon(
                                  Icons.alarm,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.alarm, color: Theme.of(context).iconTheme.color),
                                        const SizedBox(width: 8),
                                        const Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        const SizedBox(width: 8),
                                        const Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editAlarm(index);
                                  } else if (value == 'delete') {
                                    _deleteAlarm(index);
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () => _editAlarm(index),
                        ), // closes ListTile
                      ); // closes Card
                    },
                  ), // closes ListView.builder
            ), // closes Expanded
          ], // closes children of Column
      ), // closes Column
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlarm,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(Icons.alarm, color: Theme.of(context).colorScheme.onPrimary),
        label: Text(
          'Add Alarm',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class AlarmDialog extends StatefulWidget {
  final Alarm? alarm;
  final Function(Alarm) onSave;

  const AlarmDialog({
    super.key,
    this.alarm,
    required this.onSave,
  });

  @override
  State<AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<AlarmDialog> {
  late TimeOfDay _selectedTime;
  late TextEditingController _labelController;
  late List<bool> _weekdays;

  final List<String> _weekdayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.alarm?.time ?? TimeOfDay.now();
    _labelController = TextEditingController(
      text: widget.alarm?.label ?? 'Alarm',
    );
    _weekdays = widget.alarm?.weekdays ?? List.filled(7, true);
  }

  Future<void> _selectTime() async {
    final theme = Theme.of(context);
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.cardColor,
              hourMinuteTextColor: theme.colorScheme.primary,
              dayPeriodTextColor: Colors.black,
              dayPeriodColor: Colors.white,
              dialHandColor: theme.colorScheme.primary,
              dialBackgroundColor: theme.colorScheme.surface,
              entryModeIconColor: theme.colorScheme.primary,
              hourMinuteColor: theme.colorScheme.surface,
              helpTextStyle: theme.textTheme.titleLarge,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
            ),
            textTheme: theme.textTheme,
            dialogBackgroundColor: theme.cardColor,
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveAlarm() {
    final alarm = Alarm(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      time: _selectedTime,
      label: _labelController.text.trim().isEmpty 
          ? 'Alarm' 
          : _labelController.text.trim(),
      isEnabled: widget.alarm?.isEnabled ?? true,
      weekdays: _weekdays,
    );
    widget.onSave(alarm);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(
        widget.alarm == null ? 'Add Alarm' : 'Edit Alarm',
        style: theme.textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time Selection
            Card(
              color: colorScheme.surface,
              child: ListTile(
                leading: Icon(Icons.alarm, color: colorScheme.primary),
                title: Text(
                  _selectedTime.format(context),
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
                ),
                subtitle: Text(
                  'Tap to change time',
                  style: theme.textTheme.bodyMedium,
                ),
                onTap: _selectTime,
              ),
            ),
            const SizedBox(height: 16),

            // Label Input
            TextField(
              controller: _labelController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Alarm Label',
                labelStyle: theme.textTheme.bodyMedium,
                prefixIcon: Icon(Icons.label, color: colorScheme.primary),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Weekdays Selection
            Text(
              'Repeat on',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                return FilterChip(
                  label: Text(_weekdayNames[index],
                      style: TextStyle(
                        color: _weekdays[index]
                            ? Colors.white // Always white when selected
                            : theme.textTheme.bodyLarge?.color,
                      )),
                  selected: _weekdays[index],
                  onSelected: (selected) {
                    setState(() {
                      _weekdays[index] = selected;
                    });
                  },
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                  checkmarkColor: colorScheme.onPrimary,
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: theme.textTheme.bodyLarge),
        ),
        ElevatedButton(
          onPressed: _saveAlarm,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: Text(
            'Save',
            style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppTheme selectedTheme;

  @override
  void initState() {
    super.initState();
    selectedTheme = AlarmClockApp.themeNotifier.value;
    AlarmClockApp.themeNotifier.addListener(_themeListener);
  }

  void _themeListener() {
    setState(() {
      selectedTheme = AlarmClockApp.themeNotifier.value;
    });
  }

  @override
  void dispose() {
    AlarmClockApp.themeNotifier.removeListener(_themeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.color_lens, color: colorScheme.primary),
            title: Text('Theme', style: textTheme.bodyLarge),
            subtitle: Text(
              selectedTheme.name[0].toUpperCase() + selectedTheme.name.substring(1),
              style: textTheme.bodyMedium,
            ),
            trailing: DropdownButton<AppTheme>(
              value: selectedTheme,
              dropdownColor: theme.cardColor,
              style: textTheme.bodyLarge,
              items: const [
                DropdownMenuItem(value: AppTheme.dark, child: Text('Dark')),
                DropdownMenuItem(value: AppTheme.light, child: Text('Light')),
                DropdownMenuItem(value: AppTheme.pink, child: Text('Pink')),
              ],
              onChanged: (theme) {
                if (theme != null) {
                  AlarmClockApp.themeNotifier.setTheme(theme);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: Text('About', style: textTheme.bodyLarge),
            subtitle: Text(
              'Alarm Clock App\nMade with Flutter',
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

const platform = MethodChannel('alarm_channel');

Future<void> setNativeAlarm(DateTime dateTime, String label, String alarmId) async {
  try {
    await platform.invokeMethod('setAlarm', {
      'year': dateTime.year,
      'month': dateTime.month,
      'day': dateTime.day,
      'hour': dateTime.hour,
      'minute': dateTime.minute,
      'label': label,
      'alarmId': alarmId,
    });
  } on PlatformException {
    print("Failed to set alarm");
  }
}

class AlarmRingScreen extends StatefulWidget {
  final String? label;
  const AlarmRingScreen({super.key, this.label});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  static const MethodChannel _platform = MethodChannel('alarm_channel');
  bool _stoppedByNotification = false;

  @override
  void initState() {
    super.initState();
    _platform.setMethodCallHandler(_handlePlatformCall);
  }

  Future<void> _stopAlarm() async {
    try {
      await _platform.invokeMethod('stopNativeAlarm');
    } catch (e) {}
    if (!_stoppedByNotification && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AlarmClockScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handlePlatformCall(MethodCall call) async {
    if (call.method == 'stopAlarmFromNotification') {
      _stoppedByNotification = true;
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AlarmClockScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _platform.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm, size: 100, color: theme.colorScheme.primary),
            const SizedBox(height: 32),
            Text(
              'Alarm!',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 36),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 16),
              Text(
                widget.label!,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 24),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Dismiss'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                textStyle: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () async {
                await _stopAlarm();
              },
            ),
          ],
        ),
      ),
    );
  }
}
