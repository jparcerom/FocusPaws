import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(const FocusPawsApp());
}

abstract final class FocusPawsFeatures {
  static const showStickerAlbum = true;
  static const tasksPerDailySticker = 3;
  static const allowMultipleProfiles = bool.fromEnvironment(
    'FOCUSPAWS_PREMIUM_MULTIUSER',
    defaultValue: kDebugMode,
  );
}

String _localDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _spanishWeekday(DateTime date) => const [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
][date.weekday - 1];

class FocusPawsApp extends StatelessWidget {
  const FocusPawsApp({
    super.key,
    this.profileStore,
    this.progressStore,
    this.focusDuration,
    this.overtimeBlockDuration = const Duration(minutes: 5),
    this.clock = DateTime.now,
    this.startWithSelectedProfile = false,
    this.allowMultipleProfiles,
    this.restBreakNotificationService,
  });

  final UserProfileStore? profileStore;
  final FocusTasksProgressStore? progressStore;
  final Duration? focusDuration;
  final Duration overtimeBlockDuration;
  final DateTime Function() clock;
  final bool startWithSelectedProfile;
  final bool? allowMultipleProfiles;

  static const _forest = Color(0xFF006B70);
  static const _ink = Color(0xFF1E3029);
  static const _canvas = Color(0xFFFFF3D6);
  static const _mint = Color(0xFFE5F7F3);
  static const _mintDeep = Color(0xFFD3F0EA);
  static const _mintBorder = Color(0xFFBBDDD6);
  static const _mintSurface = Color(0xFFF0FAF8);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _forest,
      surface: _canvas,
    );

    return MaterialApp(
      title: 'FocusPaws',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme.copyWith(
          primary: _forest,
          onPrimary: Colors.white,
          onSurface: _ink,
        ),
        scaffoldBackgroundColor: _canvas,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _ink,
          displayColor: _ink,
        ),
      ),
      home: HomePage(
        profileStore: profileStore ?? SharedPreferencesUserProfileStore(),
        progressStore:
            progressStore ?? SharedPreferencesFocusTasksProgressStore(),
        focusDuration: focusDuration,
        overtimeBlockDuration: overtimeBlockDuration,
        clock: clock,
        startWithSelectedProfile: startWithSelectedProfile,
        allowMultipleProfiles: allowMultipleProfiles,
        restBreakNotificationService:
            restBreakNotificationService ??
            AndroidRestBreakNotificationService(),
      ),
    );
  }

  final RestBreakNotificationService? restBreakNotificationService;
}

abstract interface class RestBreakNotificationService {
  Future<bool> showRestTimer(DateTime endsAt);
  Future<void> cancelRestTimer();
}

class AndroidRestBreakNotificationService
    implements RestBreakNotificationService {
  AndroidRestBreakNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _notificationId = 7021;
  static const _completionNotificationId = 7022;
  static const _channelId = 'active_rest_break';
  static const _completionChannelId = 'active_rest_break_finished';
  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher_foreground'),
      ),
    );
    _isInitialized = true;
  }

  @override
  Future<bool> showRestTimer(DateTime endsAt) async {
    await _initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final permissionGranted =
        await android?.requestNotificationsPermission() ?? false;
    if (!permissionGranted) return false;

    try {
      await _plugin.zonedSchedule(
        id: _completionNotificationId,
        scheduledDate: tz.TZDateTime.from(endsAt, tz.UTC),
        title: '¡Descanso terminado!',
        body: 'Tu mascota te espera para volver a tus tareas.',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _completionChannelId,
            'Fin del descanso',
            channelDescription: 'Aviso amable al terminar el descanso',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 180, 120, 180]),
            autoCancel: true,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: endsAt.millisecondsSinceEpoch.toString(),
      );
      await _plugin.show(
        id: _notificationId,
        title: 'Descanso FocusPaws',
        body: 'Tu descanso sigue en marcha',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Descanso activo',
            channelDescription: 'Temporizador del descanso activo',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            playSound: false,
            enableVibration: false,
            when: endsAt.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: true,
            category: AndroidNotificationCategory.stopwatch,
          ),
        ),
        payload: endsAt.millisecondsSinceEpoch.toString(),
      );
    } on Exception {
      await cancelRestTimer();
      rethrow;
    }
    return true;
  }

  @override
  Future<void> cancelRestTimer() async {
    await _plugin.cancel(id: _notificationId);
    await _plugin.cancel(id: _completionNotificationId);
  }
}

enum UserAvatar {
  dog(id: 'dog', label: 'Perro', petName: 'Nori', emoji: '🐶'),
  cat(id: 'cat', label: 'Gato', petName: 'Kitty', emoji: '🐱'),
  fox(id: 'fox', label: 'Zorro', petName: 'Foxy', emoji: '🦊'),
  rabbit(id: 'rabbit', label: 'Conejo', petName: 'Bunny', emoji: '🐰'),
  bear(id: 'bear', label: 'Oso', petName: 'Bruno', emoji: '🐻'),
  panda(id: 'panda', label: 'Panda', petName: 'Panda', emoji: '🐼');

  const UserAvatar({
    required this.id,
    required this.label,
    required this.petName,
    required this.emoji,
  });

  final String id;
  final String label;
  final String petName;
  final String emoji;

  static UserAvatar? fromId(String? id) {
    for (final avatar in values) {
      if (avatar.id == id) return avatar;
    }
    return null;
  }
}

enum FocusTaskSize {
  short(
    minutes: 15,
    points: 10,
    maxRestBonusMinutes: 3,
    label: 'Paso corto',
    buttonLabel: 'Corto',
  ),
  standard(
    minutes: 30,
    points: 20,
    maxRestBonusMinutes: 7,
    label: 'Bloque estándar',
    buttonLabel: 'Medio',
  ),
  long(
    minutes: 45,
    points: 40,
    maxRestBonusMinutes: 10,
    label: 'Gran esfuerzo',
    buttonLabel: 'Largo',
  );

  const FocusTaskSize({
    required this.minutes,
    required this.points,
    required this.maxRestBonusMinutes,
    required this.label,
    required this.buttonLabel,
  });

  final int minutes;
  final int points;
  final int maxRestBonusMinutes;
  final String label;
  final String buttonLabel;

  Duration get duration => Duration(minutes: minutes);
  Duration get maxRestBonus => Duration(minutes: maxRestBonusMinutes);

  static FocusTaskSize fromMinutes(int minutes) {
    for (final size in values) {
      if (size.minutes == minutes) return size;
    }
    throw const FormatException('Invalid estimated task duration.');
  }
}

class FocusTaskDraft {
  const FocusTaskDraft({required this.title, required this.size});

  final String title;
  final FocusTaskSize size;
}

class UserProfile {
  const UserProfile({
    this.id = 'default',
    required this.name,
    required this.avatar,
  });

  final String id;
  final String name;
  final UserAvatar avatar;

  Map<String, String> toJson() => {'id': id, 'name': name, 'avatar': avatar.id};

  factory UserProfile.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['id'] is! String ||
        (value['id'] as String).trim().isEmpty ||
        value['name'] is! String ||
        (value['name'] as String).trim().isEmpty) {
      throw const FormatException('Invalid saved user profile.');
    }
    final avatar = UserAvatar.fromId(value['avatar'] as String?);
    if (avatar == null) {
      throw const FormatException('Invalid saved user avatar.');
    }
    return UserProfile(
      id: value['id'] as String,
      name: (value['name'] as String).trim(),
      avatar: avatar,
    );
  }
}

abstract interface class UserProfileStore {
  Future<UserProfile?> loadProfile();

  Future<void> saveProfile(UserProfile profile);
}

abstract interface class UserProfileCollectionStore
    implements UserProfileStore {
  Future<List<UserProfile>> loadProfiles();

  Future<void> saveProfiles(List<UserProfile> profiles);
}

class SharedPreferencesUserProfileStore implements UserProfileCollectionStore {
  static const _nameKey = 'user_profile_name';
  static const _avatarKey = 'user_profile_avatar';
  static const _profilesKey = 'user_profiles';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<UserProfile?> loadProfile() async {
    final profiles = await loadProfiles();
    return profiles.isEmpty ? null : profiles.first;
  }

  @override
  Future<List<UserProfile>> loadProfiles() async {
    final savedProfiles = await _preferences.getString(_profilesKey);
    if (savedProfiles != null) {
      final decoded = jsonDecode(savedProfiles);
      if (decoded is! List<Object?>) {
        throw const FormatException('Invalid saved user profiles.');
      }
      final profiles = decoded.map(UserProfile.fromJson).toList();
      _validateProfiles(profiles);
      return List.unmodifiable(profiles);
    }

    final name = (await _preferences.getString(_nameKey))?.trim();
    final avatar = UserAvatar.fromId(await _preferences.getString(_avatarKey));

    if (name == null || name.isEmpty || avatar == null) {
      return const [];
    }
    final profile = UserProfile(name: name, avatar: avatar);
    await saveProfiles([profile]);
    return [profile];
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final profiles = await loadProfiles();
    final index = profiles.indexWhere((item) => item.id == profile.id);
    if (index == -1) {
      await saveProfiles([...profiles, profile]);
    } else {
      final updated = [...profiles];
      updated[index] = profile;
      await saveProfiles(updated);
    }
  }

  @override
  Future<void> saveProfiles(List<UserProfile> profiles) async {
    _validateProfiles(profiles);
    await _preferences.setString(
      _profilesKey,
      jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
    );
    if (profiles.isNotEmpty) {
      final defaultProfile = profiles.firstWhere(
        (profile) => profile.id == 'default',
        orElse: () => profiles.first,
      );
      await _preferences.setString(_nameKey, defaultProfile.name);
      await _preferences.setString(_avatarKey, defaultProfile.avatar.id);
    }
  }

  void _validateProfiles(List<UserProfile> profiles) {
    final ids = profiles.map((profile) => profile.id).toSet();
    if (ids.length != profiles.length) {
      throw ArgumentError('User profile IDs must be unique.');
    }
  }
}

class FocusTaskProgress {
  const FocusTaskProgress({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.hasReceivedReward,
    this.estimatedMinutes = 30,
  });

  final int id;
  final String title;
  final bool isCompleted;
  final bool hasReceivedReward;
  final int estimatedMinutes;

  factory FocusTaskProgress.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid task progress entry.');
    }

    final id = value['id'];
    final title = value['title'];
    final isCompleted = value['isCompleted'];
    final hasReceivedReward = value['hasReceivedReward'];
    final estimatedMinutes = value['estimatedMinutes'] ?? 30;
    if (id is! int ||
        id < 0 ||
        title is! String ||
        title.trim().isEmpty ||
        isCompleted is! bool ||
        hasReceivedReward is! bool ||
        estimatedMinutes is! int) {
      throw const FormatException('Invalid task progress fields.');
    }
    FocusTaskSize.fromMinutes(estimatedMinutes);

    return FocusTaskProgress(
      id: id,
      title: title,
      isCompleted: isCompleted,
      hasReceivedReward: hasReceivedReward,
      estimatedMinutes: estimatedMinutes,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'hasReceivedReward': hasReceivedReward,
    'estimatedMinutes': estimatedMinutes,
  };
}

class FocusTasksProgress {
  FocusTasksProgress({
    required List<FocusTaskProgress> tasks,
    required this.points,
    this.bonusRestSeconds = 0,
    this.perseveranceSnacks = 0,
    Map<String, List<int>> dailyCompletions = const {},
    this.lastActiveDate,
    List<int> pendingCarryoverTaskIds = const [],
    this.activeRestEndTimeMillis,
    this.petMoodMinutes = 0,
    this.petPatCount = 0,
  }) : tasks = List.unmodifiable(tasks),
       dailyCompletions = Map.unmodifiable(
         dailyCompletions.map(
           (date, taskIds) => MapEntry(date, List<int>.unmodifiable(taskIds)),
         ),
       ),
       pendingCarryoverTaskIds = List.unmodifiable(pendingCarryoverTaskIds) {
    if (points < 0) throw ArgumentError.value(points, 'points');
    if (bonusRestSeconds < 0) {
      throw ArgumentError.value(bonusRestSeconds, 'bonusRestSeconds');
    }
    if (perseveranceSnacks < 0) {
      throw ArgumentError.value(perseveranceSnacks, 'perseveranceSnacks');
    }
    if (petMoodMinutes < 0) {
      throw ArgumentError.value(petMoodMinutes, 'petMoodMinutes');
    }
    if (petPatCount < 0) {
      throw ArgumentError.value(petPatCount, 'petPatCount');
    }
    final ids = tasks.map((task) => task.id).toSet();
    if (ids.length != tasks.length) {
      throw ArgumentError('Task IDs must be unique.');
    }
    for (final entry in this.dailyCompletions.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null || _localDateKey(date) != entry.key) {
        throw ArgumentError.value(entry.key, 'dailyCompletions');
      }
      if (entry.value.any((id) => id < 0) ||
          entry.value.toSet().length != entry.value.length) {
        throw ArgumentError.value(entry.value, 'dailyCompletions');
      }
    }
    if (lastActiveDate != null) {
      final date = DateTime.tryParse(lastActiveDate!);
      if (date == null || _localDateKey(date) != lastActiveDate) {
        throw ArgumentError.value(lastActiveDate, 'lastActiveDate');
      }
    }
    if (this.pendingCarryoverTaskIds.any((id) => id < 0) ||
        this.pendingCarryoverTaskIds.toSet().length !=
            this.pendingCarryoverTaskIds.length) {
      throw ArgumentError.value(
        pendingCarryoverTaskIds,
        'pendingCarryoverTaskIds',
      );
    }
  }

  final List<FocusTaskProgress> tasks;
  final int points;
  final int bonusRestSeconds;
  final int perseveranceSnacks;
  final Map<String, List<int>> dailyCompletions;
  final String? lastActiveDate;
  final List<int> pendingCarryoverTaskIds;
  final int? activeRestEndTimeMillis;
  final int petMoodMinutes;
  final int petPatCount;

  List<String> get stickerUnlockDates =>
      dailyCompletions.entries
          .where(
            (entry) =>
                entry.value.length >= FocusPawsFeatures.tasksPerDailySticker,
          )
          .map((entry) => entry.key)
          .toList()
        ..sort();

  static const empty = FocusTasksProgress._(
    tasks: [],
    points: 0,
    bonusRestSeconds: 0,
    perseveranceSnacks: 0,
    dailyCompletions: {},
    lastActiveDate: null,
    pendingCarryoverTaskIds: [],
    activeRestEndTimeMillis: null,
    petMoodMinutes: 0,
    petPatCount: 0,
  );

  const FocusTasksProgress._({
    required this.tasks,
    required this.points,
    required this.bonusRestSeconds,
    required this.perseveranceSnacks,
    required this.dailyCompletions,
    required this.lastActiveDate,
    required this.pendingCarryoverTaskIds,
    required this.activeRestEndTimeMillis,
    required this.petMoodMinutes,
    required this.petPatCount,
  });

  factory FocusTasksProgress.fromJson(String json) {
    final value = jsonDecode(json);
    if (value is! Map<String, dynamic> ||
        value['points'] is! int ||
        value['tasks'] is! List<Object?> ||
        (value['bonusRestSeconds'] != null &&
            value['bonusRestSeconds'] is! int) ||
        (value['perseveranceSnacks'] != null &&
            value['perseveranceSnacks'] is! int) ||
        (value['dailyCompletions'] != null &&
            value['dailyCompletions'] is! Map<String, dynamic>) ||
        (value['lastActiveDate'] != null &&
            value['lastActiveDate'] is! String) ||
        (value['pendingCarryoverTaskIds'] != null &&
            (value['pendingCarryoverTaskIds'] is! List<Object?> ||
                (value['pendingCarryoverTaskIds'] as List<Object?>).any(
                  (id) => id is! int,
                ))) ||
        (value['activeRestEndTimeMillis'] != null &&
            value['activeRestEndTimeMillis'] is! int) ||
        (value['petMoodMinutes'] != null &&
            (value['petMoodMinutes'] is! int ||
                (value['petMoodMinutes'] as int) < 0)) ||
        (value['petPatCount'] != null &&
            (value['petPatCount'] is! int ||
                (value['petPatCount'] as int) < 0))) {
      throw const FormatException('Invalid saved task progress.');
    }

    final tasks = (value['tasks'] as List<Object?>)
        .map(FocusTaskProgress.fromJson)
        .toList();
    final dailyCompletions = <String, List<int>>{};
    final savedDailyCompletions =
        value['dailyCompletions'] as Map<String, dynamic>? ?? {};
    for (final entry in savedDailyCompletions.entries) {
      final date = DateTime.tryParse(entry.key);
      final taskIds = entry.value;
      if (date == null ||
          _localDateKey(date) != entry.key ||
          taskIds is! List<Object?> ||
          taskIds.any((id) => id is! int)) {
        throw const FormatException('Invalid saved daily task completions.');
      }
      dailyCompletions[entry.key] = taskIds.cast<int>();
    }
    try {
      return FocusTasksProgress(
        tasks: tasks,
        points: value['points'] as int,
        bonusRestSeconds: value['bonusRestSeconds'] as int? ?? 0,
        perseveranceSnacks: value['perseveranceSnacks'] as int? ?? 0,
        dailyCompletions: dailyCompletions,
        lastActiveDate: value['lastActiveDate'] as String?,
        pendingCarryoverTaskIds:
            (value['pendingCarryoverTaskIds'] as List<Object?>? ?? [])
                .cast<int>(),
        activeRestEndTimeMillis: value['activeRestEndTimeMillis'] as int?,
        petMoodMinutes: value['petMoodMinutes'] as int? ?? 0,
        petPatCount: value['petPatCount'] as int? ?? 0,
      );
    } on ArgumentError {
      throw const FormatException('Invalid saved task progress.');
    }
  }

  String toJson() => jsonEncode({
    'points': points,
    'bonusRestSeconds': bonusRestSeconds,
    'perseveranceSnacks': perseveranceSnacks,
    'dailyCompletions': dailyCompletions,
    'lastActiveDate': lastActiveDate,
    'pendingCarryoverTaskIds': pendingCarryoverTaskIds,
    'activeRestEndTimeMillis': activeRestEndTimeMillis,
    'petMoodMinutes': petMoodMinutes,
    'petPatCount': petPatCount,
    'tasks': tasks.map((task) => task.toJson()).toList(),
  });
}

abstract interface class FocusTasksProgressStore {
  Future<FocusTasksProgress> loadProgress({String profileId = 'default'});

  Future<void> saveProgress(
    FocusTasksProgress progress, {
    String profileId = 'default',
  });
}

class SharedPreferencesFocusTasksProgressStore
    implements FocusTasksProgressStore {
  static const _progressKey = 'focus_tasks_progress';
  static const _legacyProgressKey = 'focus_tasks_progress';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<FocusTasksProgress> loadProgress({
    String profileId = 'default',
  }) async {
    final key = '${_progressKey}_$profileId';
    var json = await _preferences.getString(key);
    if (json == null && profileId == 'default') {
      json = await _preferences.getString(_legacyProgressKey);
      if (json != null) {
        await _preferences.setString(key, json);
        await _preferences.remove(_legacyProgressKey);
      }
    }
    return json == null
        ? FocusTasksProgress.empty
        : FocusTasksProgress.fromJson(json);
  }

  @override
  Future<void> saveProgress(
    FocusTasksProgress progress, {
    String profileId = 'default',
  }) => _preferences.setString('${_progressKey}_$profileId', progress.toJson());
}

class _UserTasksPage extends StatefulWidget {
  const _UserTasksPage({
    super.key,
    required this.profile,
    required this.progressStore,
    required this.restBreakNotificationService,
    required this.onEndDay,
    this.focusDuration,
    this.overtimeBlockDuration = const Duration(minutes: 5),
    this.clock = DateTime.now,
  });

  final UserProfile profile;
  final FocusTasksProgressStore progressStore;
  final RestBreakNotificationService restBreakNotificationService;
  final VoidCallback onEndDay;
  final Duration? focusDuration;
  final Duration overtimeBlockDuration;
  final DateTime Function() clock;

  @override
  State<_UserTasksPage> createState() => _UserTasksPageState();
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.profileStore,
    required this.progressStore,
    required this.restBreakNotificationService,
    this.focusDuration,
    this.overtimeBlockDuration = const Duration(minutes: 5),
    this.clock = DateTime.now,
    this.startWithSelectedProfile = false,
    this.allowMultipleProfiles,
  });

  final UserProfileStore profileStore;
  final FocusTasksProgressStore progressStore;
  final RestBreakNotificationService restBreakNotificationService;
  final Duration? focusDuration;
  final Duration overtimeBlockDuration;
  final DateTime Function() clock;
  final bool startWithSelectedProfile;
  final bool? allowMultipleProfiles;

  @override
  State<HomePage> createState() => _HomePageShellState();
}

enum _AppScreen {
  loading,
  welcome,
  launcher,
  profileHub,
  editName,
  editAvatar,
  tasks,
}

class _HomePageShellState extends State<HomePage> {
  late Future<List<UserProfile>> _profilesFuture;
  late Future<FocusTasksProgress> _hubProgressFuture;
  List<UserProfile> _profiles = [];
  UserProfile? _selectedProfile;
  _AppScreen _screen = _AppScreen.loading;

  bool get _allowMultipleProfiles =>
      widget.allowMultipleProfiles ?? FocusPawsFeatures.allowMultipleProfiles;

  List<UserProfile> get _availableProfiles {
    if (_allowMultipleProfiles || _profiles.length <= 1) return _profiles;
    return [
      _profiles.firstWhere(
        (profile) => profile.id == 'default',
        orElse: () => _profiles.first,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _profilesFuture = _loadProfiles();
  }

  Future<List<UserProfile>> _loadProfiles() async {
    final store = widget.profileStore;
    if (store is UserProfileCollectionStore) return store.loadProfiles();
    final profile = await store.loadProfile();
    return profile == null ? [] : [profile];
  }

  Future<void> _saveProfiles(List<UserProfile> profiles) async {
    final store = widget.profileStore;
    if (store is UserProfileCollectionStore) {
      await store.saveProfiles(profiles);
      return;
    }
    if (profiles.length > 1) {
      throw StateError('This profile store does not support multiple users.');
    }
    if (profiles.isEmpty) return;
    await store.saveProfile(profiles.single);
  }

  void _initializeProfiles(List<UserProfile> profiles) {
    if (_screen != _AppScreen.loading) return;
    _profiles = profiles;
    if (profiles.isEmpty) {
      _screen = _AppScreen.welcome;
    } else if (widget.startWithSelectedProfile) {
      _selectedProfile = profiles.first;
      _screen = _AppScreen.tasks;
    } else {
      _screen = _AppScreen.launcher;
    }
  }

  Future<void> _saveNewProfile(UserProfile profile) async {
    final id = _profiles.isEmpty ? 'default' : _nextProfileId(_profiles);
    final savedProfile = UserProfile(
      id: id,
      name: profile.name,
      avatar: profile.avatar,
    );
    final updatedProfiles = [..._profiles, savedProfile];
    await _saveProfiles(updatedProfiles);
    if (!mounted) return;
    setState(() {
      _profiles = updatedProfiles;
      _selectedProfile = savedProfile;
      _screen = _profiles.length == 1
          ? _AppScreen.tasks
          : _AppScreen.profileHub;
      _hubProgressFuture = widget.progressStore.loadProgress(
        profileId: savedProfile.id,
      );
    });
  }

  String _nextProfileId(List<UserProfile> profiles) {
    var index = 2;
    while (profiles.any((profile) => profile.id == 'user-$index')) {
      index++;
    }
    return 'user-$index';
  }

  void _selectProfile(UserProfile profile) {
    setState(() {
      _selectedProfile = profile;
      _hubProgressFuture = widget.progressStore.loadProgress(
        profileId: profile.id,
      );
      _screen = _AppScreen.profileHub;
    });
  }

  void _enterTasks() => setState(() => _screen = _AppScreen.tasks);

  void _endDay() => setState(() {
    _selectedProfile = null;
    _screen = _AppScreen.launcher;
  });

  Future<void> _saveEditedProfile(UserProfile editedProfile) async {
    final updatedProfiles = [
      for (final profile in _profiles)
        if (profile.id == editedProfile.id) editedProfile else profile,
    ];
    await _saveProfiles(updatedProfiles);
    if (!mounted) return;
    setState(() {
      _profiles = updatedProfiles;
      _selectedProfile = editedProfile;
      _screen = _AppScreen.profileHub;
    });
  }

  void _retryProfiles() {
    setState(() {
      _screen = _AppScreen.loading;
      _profilesFuture = _loadProfiles();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<UserProfile>>(
    future: _profilesFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const _ProfileLoadingScreen();
      }
      if (snapshot.hasError) {
        return _ProfileErrorScreen(onRetry: _retryProfiles);
      }
      _initializeProfiles(snapshot.requireData);
      switch (_screen) {
        case _AppScreen.loading:
          return const _ProfileLoadingScreen();
        case _AppScreen.welcome:
          return WelcomeScreen(
            onSave: _saveNewProfile,
            onCancel: _profiles.isEmpty
                ? null
                : () => setState(() => _screen = _AppScreen.launcher),
          );
        case _AppScreen.launcher:
          return _AccountLauncher(
            profiles: _availableProfiles,
            onSelect: _selectProfile,
            onCreate: _allowMultipleProfiles
                ? () => setState(() => _screen = _AppScreen.welcome)
                : null,
          );
        case _AppScreen.profileHub:
          return _selectedProfile == null
              ? _AccountLauncher(
                  profiles: _availableProfiles,
                  onSelect: _selectProfile,
                  onCreate: null,
                )
              : FutureBuilder<FocusTasksProgress>(
                  future: _hubProgressFuture,
                  builder: (context, progressSnapshot) {
                    if (progressSnapshot.connectionState !=
                        ConnectionState.done) {
                      return const _ProgressLoadingScreen();
                    }
                    if (progressSnapshot.hasError) {
                      return _ProgressErrorScreen(
                        onRetry: () => setState(() {
                          _hubProgressFuture = widget.progressStore
                              .loadProgress(profileId: _selectedProfile!.id);
                        }),
                      );
                    }
                    return _UserProfileHub(
                      profile: _selectedProfile!,
                      unlockedDates: _unlockedStickerDates(
                        progressSnapshot.requireData,
                      ),
                      onEditName: () =>
                          setState(() => _screen = _AppScreen.editName),
                      onEditAvatar: () =>
                          setState(() => _screen = _AppScreen.editAvatar),
                      onEnterTasks: _enterTasks,
                      onBack: _endDay,
                    );
                  },
                );
        case _AppScreen.editName:
        case _AppScreen.editAvatar:
          final profile = _selectedProfile!;
          return WelcomeScreen(
            key: ValueKey('${profile.id}-$_screen'),
            initialProfile: profile,
            editNameOnly: _screen == _AppScreen.editName,
            editAvatarOnly: _screen == _AppScreen.editAvatar,
            onCancel: () => setState(() => _screen = _AppScreen.profileHub),
            onSave: _saveEditedProfile,
          );
        case _AppScreen.tasks:
          final profile = _selectedProfile!;
          return _UserTasksPage(
            key: ValueKey(profile.id),
            profile: profile,
            progressStore: widget.progressStore,
            restBreakNotificationService: widget.restBreakNotificationService,
            focusDuration: widget.focusDuration,
            overtimeBlockDuration: widget.overtimeBlockDuration,
            clock: widget.clock,
            onEndDay: _endDay,
          );
      }
    },
  );
}

List<String> _unlockedStickerDates(FocusTasksProgress progress) =>
    progress.dailyCompletions.entries
        .where(
          (entry) =>
              entry.value.length >= FocusPawsFeatures.tasksPerDailySticker,
        )
        .map((entry) => entry.key)
        .toList()
      ..sort();

class _UserTasksPageState extends State<_UserTasksPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final List<FocusTask> _tasks = [];
  int _nextTaskId = 0;
  int _earnedPoints = 0;
  Duration _bonusRest = Duration.zero;
  DateTime? _activeRestEndsAt;
  int _perseveranceSnacks = 0;
  int _petMoodMinutes = 0;
  int _petPatCount = 0;
  Map<String, Set<int>> _dailyCompletions = {};
  String? _lastActiveDate;
  final List<int> _pendingCarryoverTaskIds = [];
  late final AnimationController _levelUpController;
  late Future<FocusTasksProgress> _progressFuture;
  Future<void> _pendingProgressSave = Future<void>.value();
  bool _hasRestoredProgress = false;
  bool _showAllPendingTasks = false;
  bool _showCompletedTasks = false;
  Timer? _dailyResetTimer;
  bool _isPromptingCarryoverTasks = false;
  bool _isOpeningRest = false;

  int get _completedCount => _tasks.where((task) => task.isCompleted).length;
  String get _todayKey => _localDateKey(widget.clock());
  List<String> get _stickerUnlockDates =>
      _dailyCompletions.entries
          .where(
            (entry) =>
                entry.value.length >= FocusPawsFeatures.tasksPerDailySticker,
          )
          .map((entry) => entry.key)
          .toList()
        ..sort();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDailyRefresh();
    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressFuture = widget.progressStore.loadProgress(
      profileId: widget.profile.id,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dailyResetTimer?.cancel();
    _levelUpController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _advanceToCurrentDay();
      _scheduleDailyRefresh();
      _scheduleCarryoverPrompt();
    }
  }

  void _scheduleDailyRefresh() {
    _dailyResetTimer?.cancel();
    final now = widget.clock();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _dailyResetTimer = Timer(
      nextDay.difference(now) + const Duration(seconds: 1),
      () {
        if (!mounted) return;
        _advanceToCurrentDay();
        _scheduleDailyRefresh();
      },
    );
  }

  Future<void> _addTask() async {
    final draft = await showModalBottomSheet<FocusTaskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskSheet(),
    );

    if (!mounted || draft == null) return;

    setState(() {
      _tasks.insert(
        0,
        FocusTask(id: _nextTaskId++, title: draft.title, size: draft.size),
      );
      _showAllPendingTasks = false;
    });
    _persistProgress();
  }

  void _retryProgressLoad() {
    setState(() {
      _progressFuture = widget.progressStore.loadProgress(
        profileId: widget.profile.id,
      );
    });
  }

  Future<void> _finishDay() async {
    try {
      await _pendingProgressSave;
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar tu progreso. Inténtalo de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (mounted) widget.onEndDay();
  }

  void _persistProgress() {
    final snapshot = FocusTasksProgress(
      tasks: _tasks
          .map(
            (task) => FocusTaskProgress(
              id: task.id,
              title: task.title,
              isCompleted: task.isCompleted,
              hasReceivedReward: task.hasReceivedReward,
              estimatedMinutes: task.size.minutes,
            ),
          )
          .toList(),
      points: _earnedPoints,
      bonusRestSeconds: _bonusRest.inSeconds,
      perseveranceSnacks: _perseveranceSnacks,
      dailyCompletions: {
        for (final entry in _dailyCompletions.entries)
          entry.key: entry.value.toList()..sort(),
      },
      lastActiveDate: _lastActiveDate ?? _todayKey,
      pendingCarryoverTaskIds: _pendingCarryoverTaskIds,
      activeRestEndTimeMillis: _activeRestEndsAt?.millisecondsSinceEpoch,
      petMoodMinutes: _petMoodMinutes,
      petPatCount: _petPatCount,
    );
    _pendingProgressSave = _pendingProgressSave
        .catchError((Object _) {})
        .then(
          (_) => widget.progressStore.saveProgress(
            snapshot,
            profileId: widget.profile.id,
          ),
        );
    _pendingProgressSave.catchError((Object error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar tu progreso: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _restoreProgress(FocusTasksProgress progress) {
    final today = _todayKey;
    final lastRecordedCompletionDate = progress.dailyCompletions.keys.toList()
      ..sort();
    final previousActiveDate =
        progress.lastActiveDate ??
        (lastRecordedCompletionDate.isEmpty
            ? null
            : lastRecordedCompletionDate.last);
    final isNewDay =
        previousActiveDate != null && previousActiveDate.compareTo(today) < 0;
    final isLegacyProgressWithoutDate =
        progress.lastActiveDate == null && previousActiveDate == null;
    final completedToday = progress.dailyCompletions[today]?.toSet() ?? <int>{};
    final hasLegacyCompletedTasks =
        isLegacyProgressWithoutDate &&
        progress.tasks.any(
          (task) => task.isCompleted && !completedToday.contains(task.id),
        );
    final restoredTasks = progress.tasks.where((task) {
      if (!task.isCompleted) return true;
      if (isNewDay) return false;
      return !isLegacyProgressWithoutDate || completedToday.contains(task.id);
    }).toList();

    _tasks
      ..clear()
      ..addAll(
        restoredTasks.map(
          (task) => FocusTask(
            id: task.id,
            title: task.title,
            isCompleted: task.isCompleted,
            hasReceivedReward: task.hasReceivedReward,
            size: FocusTaskSize.fromMinutes(task.estimatedMinutes),
          ),
        ),
      );
    _nextTaskId = _tasks.fold(
      0,
      (nextId, task) => math.max(nextId, task.id + 1),
    );
    _earnedPoints = progress.points;
    _bonusRest = Duration(seconds: progress.bonusRestSeconds);
    _activeRestEndsAt = progress.activeRestEndTimeMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            progress.activeRestEndTimeMillis!,
          );
    _petMoodMinutes = progress.petMoodMinutes;
    _petPatCount = progress.petPatCount;
    _perseveranceSnacks = progress.perseveranceSnacks;
    _dailyCompletions = {
      for (final entry in progress.dailyCompletions.entries)
        entry.key: entry.value.toSet(),
    };
    _lastActiveDate = today;
    _pendingCarryoverTaskIds
      ..clear()
      ..addAll(
        progress.pendingCarryoverTaskIds.where(
          (id) => _tasks.any((task) => task.id == id && !task.isCompleted),
        ),
      );
    if (isNewDay || hasLegacyCompletedTasks) {
      _pendingCarryoverTaskIds
        ..clear()
        ..addAll(
          _tasks.where((task) => !task.isCompleted).map((task) => task.id),
        );
    }

    if (progress.lastActiveDate != today ||
        isNewDay ||
        isLegacyProgressWithoutDate ||
        !listEquals(
          progress.pendingCarryoverTaskIds,
          _pendingCarryoverTaskIds,
        ) ||
        progress.tasks.length != _tasks.length) {
      _persistProgress();
    }
    _scheduleCarryoverPrompt();
    _scheduleRestResume();
  }

  void _advanceToCurrentDay() {
    final today = _todayKey;
    final lastActiveDate = _lastActiveDate;
    if (!_hasRestoredProgress ||
        lastActiveDate == null ||
        lastActiveDate.compareTo(today) >= 0) {
      return;
    }

    setState(() {
      _tasks.removeWhere((task) => task.isCompleted);
      _pendingCarryoverTaskIds
        ..clear()
        ..addAll(_tasks.map((task) => task.id));
      _lastActiveDate = today;
    });
    _persistProgress();
    _scheduleCarryoverPrompt();
  }

  void _scheduleCarryoverPrompt() {
    if (_activeRestEndsAt != null ||
        _isPromptingCarryoverTasks ||
        _pendingCarryoverTaskIds.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isPromptingCarryoverTasks) return;
      _promptCarryoverTasks();
    });
  }

  void _scheduleRestResume() {
    if (_activeRestEndsAt == null || _isOpeningRest) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isOpeningRest && _activeRestEndsAt != null) {
        _openRestIfAvailable();
      }
    });
  }

  Future<void> _openRestIfAvailable() async {
    if (!mounted || _isOpeningRest) return;
    final navigator = Navigator.of(context);
    var endsAt = _activeRestEndsAt;
    if (endsAt == null) {
      if (_bonusRest <= Duration.zero) return;
      final restDuration = _bonusRest;
      endsAt = widget.clock().add(restDuration);
      setState(() {
        _activeRestEndsAt = endsAt;
        _bonusRest = Duration.zero;
      });
      final messenger = ScaffoldMessenger.of(context);
      _persistProgress();
      try {
        await _pendingProgressSave;
      } on Exception {
        if (!mounted) return;
        setState(() {
          _bonusRest += restDuration;
          _activeRestEndsAt = null;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar el inicio del descanso. Inténtalo de nuevo.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    _isOpeningRest = true;
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ActiveRestBreakPage(
          endsAt: endsAt!,
          pet: widget.profile.avatar,
          petName: widget.profile.avatar.petName,
          clock: widget.clock,
          notificationService: widget.restBreakNotificationService,
          onPetMoodMinute: _recordPetMoodMinute,
          petPatCount: _petPatCount,
          onPetPat: _recordPetPat,
          onFinished: _finishRestBreak,
          onFinishEarly: _finishRestBreakEarly,
        ),
      ),
    );
    _isOpeningRest = false;
    if (mounted && _activeRestEndsAt == null) _scheduleCarryoverPrompt();
  }

  void _recordPetMoodMinute() {
    if (!mounted) return;
    setState(() => _petMoodMinutes++);
    _persistProgress();
  }

  void _recordPetPat() {
    if (!mounted) return;
    var leveledUp = false;
    setState(() {
      _petPatCount++;
      if (_petPatCount % 10 == 0) {
        final previousLevel = PetProgress.fromTotalPoints(_earnedPoints).level;
        _earnedPoints += 2;
        leveledUp =
            PetProgress.fromTotalPoints(_earnedPoints).level > previousLevel;
      }
    });
    _persistProgress();
    if (leveledUp) _levelUpController.forward(from: 0);
  }

  void _finishRestBreak() {
    if (!mounted) return;
    setState(() => _activeRestEndsAt = null);
    _persistProgress();
  }

  void _finishRestBreakEarly(Duration remaining) {
    if (!mounted) return;
    final remainingSeconds =
        remaining.inSeconds +
        (remaining.inMicroseconds % Duration.microsecondsPerSecond == 0
            ? 0
            : 1);
    setState(() {
      _bonusRest += Duration(seconds: remainingSeconds);
      _activeRestEndsAt = null;
    });
    _persistProgress();
  }

  Future<void> _promptCarryoverTasks() async {
    _isPromptingCarryoverTasks = true;
    try {
      while (mounted && _pendingCarryoverTaskIds.isNotEmpty) {
        final taskId = _pendingCarryoverTaskIds.first;
        FocusTask? task;
        for (final candidate in _tasks) {
          if (candidate.id == taskId) {
            task = candidate;
            break;
          }
        }

        if (task == null || task.isCompleted) {
          setState(() => _pendingCarryoverTaskIds.remove(taskId));
          _persistProgress();
          continue;
        }

        final shouldCancel = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Tarea pendiente de ayer'),
              content: Text(
                'Ayer quedó pendiente «${task!.title}». '
                '¿Quieres conservarla para terminarla hoy o cancelarla?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Conservar tarea'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Cancelar tarea'),
                ),
              ],
            ),
          ),
        );
        if (!mounted || shouldCancel == null) return;

        setState(() {
          if (shouldCancel) {
            _tasks.removeWhere((candidate) => candidate.id == taskId);
          }
          _pendingCarryoverTaskIds.remove(taskId);
        });
        _persistProgress();
      }
    } finally {
      _isPromptingCarryoverTasks = false;
    }
  }

  Future<void> _toggleTask(FocusTask task, bool isCompleted) async {
    if (isCompleted && !task.isCompleted) {
      _completeTask(task);
      await _openRestIfAvailable();
      return;
    }

    setState(() {
      task.isCompleted = isCompleted;
    });
    _persistProgress();
  }

  void _completeTask(FocusTask task, [FocusSessionResult? result]) {
    var leveledUp = false;
    setState(() {
      task.isCompleted = true;
      _pendingCarryoverTaskIds.remove(task.id);
      _dailyCompletions.putIfAbsent(_todayKey, () => <int>{}).add(task.id);
      if (!task.hasReceivedReward) {
        final previousLevel = PetProgress.fromTotalPoints(_earnedPoints).level;
        _earnedPoints += task.size.points;
        task.hasReceivedReward = true;
        if (result != null) {
          _bonusRest += result.bonusRest;
          if (result.overtime > const Duration(minutes: 10)) {
            _perseveranceSnacks++;
          }
        }
        leveledUp =
            PetProgress.fromTotalPoints(_earnedPoints).level > previousLevel;
      }
    });
    _persistProgress();

    if (leveledUp) {
      _levelUpController.forward(from: 0);
    }
  }

  Future<void> _startFocus(FocusTask task, UserAvatar avatar) async {
    final result = await Navigator.of(context).push<FocusSessionResult>(
      MaterialPageRoute<FocusSessionResult>(
        builder: (context) => FocusSessionPage(
          taskTitle: task.title,
          avatar: avatar,
          focusDuration: widget.focusDuration ?? task.size.duration,
          taskSize: task.size,
          overtimeBlockDuration: widget.overtimeBlockDuration,
          onRewardContinue: (result) => _completeTask(task, result),
        ),
      ),
    );
    if (result != null) await _openRestIfAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FocusTasksProgress>(
      future: _progressFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ProgressLoadingScreen();
        }

        if (snapshot.hasError) {
          return _ProgressErrorScreen(onRetry: _retryProgressLoad);
        }

        if (!_hasRestoredProgress) {
          _restoreProgress(snapshot.requireData);
          _hasRestoredProgress = true;
        }
        return _buildHome(context, widget.profile);
      },
    );
  }

  Widget _buildHome(BuildContext context, UserProfile profile) {
    final pendingTasks = _tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();
    final visiblePendingTasks = _showAllPendingTasks
        ? pendingTasks
        : pendingTasks.take(3).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Row(
              children: [
                Expanded(child: const _BrandHeader()),
                FilledButton(
                  key: const Key('finish-day-button'),
                  onPressed: _finishDay,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Finalizar día'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _PersonalGreeting(profile: profile, today: widget.clock()),
            const SizedBox(height: 24),
            _PetCard(
              earnedPoints: _earnedPoints,
              levelUpAnimation: _levelUpController,
              avatar: profile.avatar,
              bonusRest: _bonusRest,
              perseveranceSnacks: _perseveranceSnacks,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tu reto del día',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$_completedCount/${_tasks.length} tareas hechas',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: const Color(0xFF64756D)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (pendingTasks.isEmpty && completedTasks.isEmpty)
              const _EmptyTasksCard()
            else if (pendingTasks.isEmpty)
              const _EmptyTasksCard(
                title: '¡Misión cumplida por hoy!',
                message: 'Tu mascota celebra cada paso que has dado.',
              ),
            for (final task in visiblePendingTasks)
              _buildTaskCard(task, profile.avatar),
            if (pendingTasks.length > 3)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('toggle-extra-tasks'),
                  onPressed: () {
                    setState(() {
                      _showAllPendingTasks = !_showAllPendingTasks;
                    });
                  },
                  icon: Icon(
                    _showAllPendingTasks
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    _showAllPendingTasks
                        ? 'Mostrar solo las 3 principales'
                        : 'Ver ${pendingTasks.length - 3} tareas más',
                  ),
                ),
              ),
            if (completedTasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('toggle-completed-tasks'),
                  onPressed: () {
                    setState(() {
                      _showCompletedTasks = !_showCompletedTasks;
                    });
                  },
                  icon: Icon(
                    _showCompletedTasks
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    _showCompletedTasks
                        ? 'Ocultar tareas completadas'
                        : 'Ver completadas (${completedTasks.length})',
                  ),
                ),
              ),
              if (_showCompletedTasks)
                for (final task in completedTasks)
                  _buildTaskCard(task, profile.avatar),
            ],
            const SizedBox(height: 14),
            _DailyStickerCard(
              completedTasks: _dailyCompletions[_todayKey]?.length ?? 0,
              unlockedStickerCount: _stickerUnlockDates.length,
              stickerUnlockedToday:
                  (_dailyCompletions[_todayKey]?.length ?? 0) >=
                  FocusPawsFeatures.tasksPerDailySticker,
              showAlbum: FocusPawsFeatures.showStickerAlbum,
              onPressed: FocusPawsFeatures.showStickerAlbum
                  ? () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => StickerAlbumPage(
                            unlockedDates: _stickerUnlockDates,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: FilledButton.icon(
          onPressed: _addTask,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Añadir una tarea'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(FocusTask task, UserAvatar avatar) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _TaskCard(
      task: task,
      onChanged: (value) => _toggleTask(task, value),
      onStart: () => _startFocus(task, avatar),
    ),
  );
}

class _AccountLauncher extends StatelessWidget {
  const _AccountLauncher({
    required this.profiles,
    required this.onSelect,
    required this.onCreate,
  });

  final List<UserProfile> profiles;
  final ValueChanged<UserProfile> onSelect;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        children: [
          const _BrandHeader(),
          const SizedBox(height: 32),
          Text(
            '¿Quién va a jugar hoy?',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige tu perfil para continuar con tus tareas y tu progreso.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: const Color(0xFF52685B)),
          ),
          const SizedBox(height: 22),
          for (final profile in profiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                key: Key('select-profile-${profile.id}'),
                onPressed: () => onSelect(profile),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                  backgroundColor: Colors.white,
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      profile.avatar.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  ],
                ),
              ),
            ),
          if (onCreate != null)
            FilledButton.icon(
              key: const Key('create-profile-button'),
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Crear otro usuario'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: FocusPawsApp._forest,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    ),
  );
}

class _UserProfileHub extends StatelessWidget {
  const _UserProfileHub({
    required this.profile,
    required this.unlockedDates,
    required this.onEditName,
    required this.onEditAvatar,
    required this.onEnterTasks,
    required this.onBack,
  });

  final UserProfile profile;
  final List<String> unlockedDates;
  final VoidCallback onEditName;
  final VoidCallback onEditAvatar;
  final VoidCallback onEnterTasks;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        children: [
          const _BrandHeader(),
          const SizedBox(height: 24),
          Text(
            'Tu espacio, ${profile.name}',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          _ProfileActionCard(
            key: const Key('edit-avatar-option'),
            icon: Text(
              profile.avatar.emoji,
              style: const TextStyle(fontSize: 30),
            ),
            title: 'Animalito escogido',
            subtitle: 'Cambiar a otro animalito',
            onPressed: onEditAvatar,
          ),
          const SizedBox(height: 12),
          _ProfileActionCard(
            key: const Key('edit-name-option'),
            icon: const Icon(Icons.person_outline_rounded, size: 30),
            title: 'Tu nombre',
            subtitle: profile.name,
            onPressed: onEditName,
          ),
          if (FocusPawsFeatures.showStickerAlbum) ...[
            const SizedBox(height: 12),
            _ProfileActionCard(
              key: const Key('open-album-option'),
              icon: const Icon(Icons.collections_bookmark_outlined, size: 30),
              title: 'Habitación y álbum de pegatinas',
              subtitle: '${unlockedDates.length} pegatinas desbloqueadas',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      StickerAlbumPage(unlockedDates: unlockedDates),
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const Key('enter-tasks-button'),
            onPressed: onEnterTasks,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Ir a tareas'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(onPressed: onBack, child: const Text('Volver a usuarios')),
        ],
      ),
    ),
  );
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      alignment: Alignment.centerLeft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    child: Row(
      children: [
        SizedBox(width: 44, height: 44, child: Center(child: icon)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF64756D)),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onSave,
    this.initialProfile,
    this.editNameOnly = false,
    this.editAvatarOnly = false,
    this.onCancel,
  });

  final Future<void> Function(UserProfile profile) onSave;
  final UserProfile? initialProfile;
  final bool editNameOnly;
  final bool editAvatarOnly;
  final VoidCallback? onCancel;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  UserAvatar _selectedAvatar = UserAvatar.dog;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    if (profile != null) {
      _nameController.text = profile.name;
      _selectedAvatar = profile.avatar;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = widget.editAvatarOnly
        ? widget.initialProfile!.name
        : _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Escribe tu nombre para continuar.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(
        UserProfile(
          id: widget.initialProfile?.id ?? 'default',
          name: name,
          avatar: widget.editNameOnly
              ? widget.initialProfile!.avatar
              : _selectedAvatar,
        ),
      );
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage =
            'No se pudo guardar tu perfil. Inténtalo de nuevo, por favor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            const _BrandHeader(),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [FocusPawsApp._mint, FocusPawsApp._mintDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  if (widget.initialProfile == null)
                    Image.asset(
                      'assets/images/focuspaws_logo_circular.png',
                      key: const Key('profile-welcome-logo'),
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    )
                  else
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: FocusPawsApp._mintSurface,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.pets_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    widget.editNameOnly
                        ? 'Cambia tu nombre'
                        : widget.editAvatarOnly
                        ? 'Elige tu animalito'
                        : '¡Qué bueno tenerte aquí!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.initialProfile == null
                        ? 'Personaliza tu espacio antes de empezar.'
                        : 'Actualiza tu perfil cuando quieras.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF52685B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            if (!widget.editAvatarOnly) ...[
              Text(
                '¿Cuál es tu nombre?',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('profile-name-field'),
                controller: _nameController,
                autofocus: false,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 24,
                onSubmitted: (_) => _saveProfile(),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Escribe tu nombre',
                  errorText: _errorMessage,
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: FocusPawsApp._mintBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: FocusPawsApp._mintBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: FocusPawsApp._forest,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
            if (!widget.editNameOnly) ...[
              const SizedBox(height: 22),
              Text(
                'Elige tu animalito',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                'Acompañará tu progreso y celebrará contigo.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF64756D)),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                key: const Key('profile-avatar-options'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: UserAvatar.values.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 92,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final avatar = UserAvatar.values[index];
                  final isSelected = avatar == _selectedAvatar;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: avatar.label,
                    child: Material(
                      color: isSelected ? FocusPawsApp._mint : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: isSelected
                              ? FocusPawsApp._forest
                              : FocusPawsApp._mintBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: Key('profile-avatar-${avatar.id}'),
                        onTap: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _selectedAvatar = avatar;
                                });
                              },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              avatar.emoji,
                              style: const TextStyle(fontSize: 30),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              avatar.label,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: const Color(0xFF355544),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onCancel != null)
              TextButton(
                onPressed: _isSaving ? null : widget.onCancel,
                child: const Text('Volver'),
              ),
            FilledButton(
              key: const Key('save-profile-button'),
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.initialProfile == null
                          ? 'Empezar'
                          : 'Guardar cambios',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoadingScreen extends StatelessWidget {
  const _ProfileLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Cargando tu perfil',
          ),
        ),
      ),
    );
  }
}

class _ProgressLoadingScreen extends StatelessWidget {
  const _ProgressLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Cargando tus tareas y puntos',
          ),
        ),
      ),
    );
  }
}

class _ProgressErrorScreen extends StatelessWidget {
  const _ProgressErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: Color(0xFF9A4E38),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pudimos cargar tus tareas y puntos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Comprueba el almacenamiento del dispositivo e inténtalo '
                  'de nuevo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Intentar de nuevo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorScreen extends StatelessWidget {
  const _ProfileErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: Color(0xFF9A4E38),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pudimos cargar tu perfil.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Comprueba el almacenamiento del dispositivo e inténtalo '
                  'de nuevo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Intentar de nuevo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalGreeting extends StatelessWidget {
  const _PersonalGreeting({required this.profile, required this.today});

  final UserProfile profile;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    '¡Hola, ${profile.name}!',
                    key: const Key('personal-greeting'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Hoy es ${_spanishWeekday(today)}',
                    key: const Key('current-weekday'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF52685B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Hoy, a tu ritmo. Un pequeño paso también cuenta.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: const Color(0xFF64756D)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FocusTask {
  FocusTask({
    required this.id,
    required this.title,
    this.size = FocusTaskSize.standard,
    this.isCompleted = false,
    this.hasReceivedReward = false,
  });

  final int id;
  final String title;
  final FocusTaskSize size;
  bool isCompleted = false;
  bool hasReceivedReward = false;
}

class PetProgress {
  const PetProgress({
    required this.totalPoints,
    required this.level,
    required this.pointsInLevel,
  });

  static const pointsPerLevel = 150;

  factory PetProgress.fromTotalPoints(int totalPoints) {
    assert(totalPoints >= 0);
    var pointsToAllocate = totalPoints;
    var level = 1;
    var pointsRequired = pointsRequiredForLevel(level);

    while (pointsToAllocate >= pointsRequired) {
      pointsToAllocate -= pointsRequired;
      level++;
      pointsRequired = pointsRequiredForLevel(level);
    }

    return PetProgress(
      totalPoints: totalPoints,
      level: level,
      pointsInLevel: pointsToAllocate,
    );
  }

  static int pointsRequiredForLevel(int level) =>
      pointsPerLevel + 30 * (level ~/ 3);

  final int totalPoints;
  final int level;
  final int pointsInLevel;

  int get nextLevel => level + 1;

  int get pointsRequired => pointsRequiredForLevel(level);

  double get progress => pointsInLevel / pointsRequired;
}

enum _RestActivity { physical, pet, free }

class ActiveRestBreakPage extends StatefulWidget {
  const ActiveRestBreakPage({
    super.key,
    required this.endsAt,
    required this.pet,
    required this.petName,
    required this.clock,
    required this.notificationService,
    required this.onPetMoodMinute,
    required this.petPatCount,
    required this.onPetPat,
    required this.onFinished,
    required this.onFinishEarly,
  });

  final DateTime endsAt;
  final UserAvatar pet;
  final String petName;
  final DateTime Function() clock;
  final RestBreakNotificationService notificationService;
  final VoidCallback onPetMoodMinute;
  final int petPatCount;
  final VoidCallback onPetPat;
  final VoidCallback onFinished;
  final ValueChanged<Duration> onFinishEarly;

  @override
  State<ActiveRestBreakPage> createState() => _ActiveRestBreakPageState();
}

class _ActiveRestBreakPageState extends State<ActiveRestBreakPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _ticker;
  final math.Random _random = math.Random();
  late final AnimationController _pointsRewardController;
  late Duration _remaining;
  late final Duration _totalDuration;
  _RestActivity _activity = _RestActivity.physical;
  DateTime? _petActivityStartedAt;
  int _recordedPetMinutes = 0;
  int _petMoodMinutesThisSession = 0;
  int _petTaps = 0;
  Timer? _petMovementTimer;
  double _petHorizontalProgress = 0.5;
  double _petVerticalOffset = 56;
  Duration _petMoveDuration = const Duration(seconds: 3);
  bool _showPointsReward = false;
  bool _isFinishing = false;
  bool _canExit = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pointsRewardController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _showPointsReward = false);
          }
        });
    _totalDuration = widget.endsAt.difference(widget.clock());
    _refreshRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshRemaining();
    });
    _schedulePetMovement();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _petMovementTimer?.cancel();
    _pointsRewardController.dispose();
    super.dispose();
  }

  void _schedulePetMovement([Duration delay = const Duration(seconds: 3)]) {
    _petMovementTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _petHorizontalProgress = _random.nextDouble();
        _petVerticalOffset = 12 + _random.nextDouble() * 88;
        _petMoveDuration = Duration(milliseconds: 2400 + _random.nextInt(1601));
      });
      _schedulePetMovement(
        _petMoveDuration + Duration(seconds: 2 + _random.nextInt(4)),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) _refreshRemaining();
  }

  void _refreshRemaining() {
    final remaining = widget.endsAt.difference(widget.clock());
    _recordCompletedPetMinutes();
    if (remaining <= Duration.zero) {
      _remaining = Duration.zero;
      _ticker?.cancel();
      _finishBreak();
      return;
    }
    if (mounted) setState(() => _remaining = remaining);
  }

  void _recordCompletedPetMinutes() {
    final startedAt = _petActivityStartedAt;
    if (_activity != _RestActivity.pet || startedAt == null) return;
    final completedMinutes = widget.clock().difference(startedAt).inMinutes;
    while (_recordedPetMinutes < completedMinutes) {
      _recordedPetMinutes++;
      _petMoodMinutesThisSession++;
      widget.onPetMoodMinute();
    }
  }

  void _selectActivity(_RestActivity activity) {
    if (activity == _activity) return;
    final wasFreeMode = _activity == _RestActivity.free;
    _recordCompletedPetMinutes();
    setState(() {
      _activity = activity;
      _petActivityStartedAt = activity == _RestActivity.pet
          ? widget.clock()
          : null;
      _recordedPetMinutes = 0;
    });
    if (wasFreeMode && activity != _RestActivity.free) {
      unawaited(_disableFreeMode());
    }
    if (activity == _RestActivity.free) _enableFreeMode();
  }

  Future<void> _enableFreeMode() async {
    try {
      final permissionGranted = await widget.notificationService.showRestTimer(
        widget.endsAt,
      );
      if (!mounted || _activity != _RestActivity.free) {
        await widget.notificationService.cancelRestTimer();
        return;
      }
      if (!permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Modo libre activo. Activa las notificaciones para '
              'recibir el aviso al terminar.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Exception catch (error) {
      if (!mounted) return;
      if (_activity == _RestActivity.free) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Modo libre activo, pero no se pudo programar la notificación: '
              '$error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _disableFreeMode() async {
    try {
      await widget.notificationService.cancelRestTimer();
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cerrar el aviso del modo libre: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _finishBreak() async {
    if (_isFinishing) return;
    _isFinishing = true;
    _ticker?.cancel();
    try {
      await widget.notificationService.cancelRestTimer();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cerrar el aviso del descanso: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (!mounted) return;
    if (_lifecycleState == AppLifecycleState.resumed) {
      unawaited(_playFinishFeedback());
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('¡Descanso terminado!'),
          content: Text(
            '¡Me lo he pasado genial! Mis baterías están al 100%. '
            '¿Hacemos otra misión patitas juntos?',
          ),
          actions: [
            FilledButton(
              key: const Key('rest-finished-continue-button'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver a mis tareas'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    widget.onFinished();
    setState(() => _canExit = true);
    Navigator.of(context).pop();
  }

  Future<void> _finishBreakEarly() async {
    final remaining = widget.endsAt.difference(widget.clock());
    if (remaining <= Duration.zero) {
      await _finishBreak();
      return;
    }
    if (_isFinishing) return;
    _isFinishing = true;
    _recordCompletedPetMinutes();
    _ticker?.cancel();
    try {
      await widget.notificationService.cancelRestTimer();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cerrar el aviso del descanso: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (!mounted) return;
    widget.onFinishEarly(remaining);
    setState(() => _canExit = true);
    Navigator.of(context).pop();
  }

  Future<void> _playFinishFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.alert);
    } on PlatformException catch (error) {
      if (mounted) _showFeedbackError(error);
    } on MissingPluginException catch (error) {
      if (mounted) _showFeedbackError(error);
    }
  }

  void _showFeedbackError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo reproducir el aviso del descanso: $error'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get _formattedRemaining {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _physicalSuggestion {
    final minutes = _remaining.inMinutes;
    if (minutes <= 5) {
      return 'Tienes $minutes minutos: ve a beber un vaso de agua y estira '
          'las piernas.';
    }
    if (minutes <= 8) {
      return 'Da un paseo corto, respira aire fresco y vuelve con calma.';
    }
    return 'Si puedes, sal a caminar unos minutos. ¡Mover el cuerpo ayuda!';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration <= Duration.zero
        ? 0.0
        : (_remaining.inMicroseconds / _totalDuration.inMicroseconds).clamp(
            0.0,
            1.0,
          );
    return PopScope(
      canPop: _canExit,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Descanso activo'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: [
              Center(
                child: Text(
                  'Tu mascota descansa en el parque mientras tú recargas '
                  'energía.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: SizedBox(
                  width: 218,
                  height: 218,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 13,
                          strokeCap: StrokeCap.round,
                          backgroundColor: const Color(0xFFD3F0EA),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.pet.emoji,
                                style: const TextStyle(fontSize: 44),
                              ),
                              const SizedBox(width: 4),
                              const Column(
                                children: [
                                  Text('💤', style: TextStyle(fontSize: 20)),
                                  Text(
                                    'descansando',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formattedRemaining,
                            key: const Key('rest-countdown'),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Text('para volver a tus tareas'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '¿Cómo quieres descansar?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      key: const Key('rest-activity-physical'),
                      label: const Text('Paseo físico'),
                      selected: _activity == _RestActivity.physical,
                      onSelected: (_) =>
                          _selectActivity(_RestActivity.physical),
                    ),
                    ChoiceChip(
                      key: const Key('rest-activity-pet'),
                      label: const Text('Jugar con mi mascota'),
                      selected: _activity == _RestActivity.pet,
                      onSelected: (_) => _selectActivity(_RestActivity.pet),
                    ),
                    ChoiceChip(
                      key: const Key('rest-activity-free'),
                      label: const Text('Modo libre'),
                      selected: _activity == _RestActivity.free,
                      onSelected: (_) => _selectActivity(_RestActivity.free),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFFE5F7F3),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: switch (_activity) {
                    _RestActivity.physical => _buildPhysicalRest(context),
                    _RestActivity.pet => _buildPetInteraction(context),
                    _RestActivity.free => _buildFreeRest(context),
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('rest-finish-early-button'),
                onPressed: _isFinishing ? null : _finishBreakEarly,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Terminar descanso'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhysicalRest(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Un pequeño movimiento ayuda a recargar energía.',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Text(_physicalSuggestion),
    ],
  );

  Widget _buildPetInteraction(BuildContext context) => Column(
    children: [
      Text(
        '¡${widget.petName} quiere jugar! Acaríciala cuando pase por la '
        'pantalla.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) => Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF3E4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBBDDD6)),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 12,
                bottom: 12,
                child: Icon(
                  Icons.grass_rounded,
                  size: 28,
                  color: Colors.green.shade600,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Icon(
                  Icons.local_florist_rounded,
                  size: 25,
                  color: Colors.pink.shade300,
                ),
              ),
              AnimatedPositioned(
                key: const Key('rest-pet-moving-target-position'),
                duration: _petMoveDuration,
                curve: Curves.easeInOut,
                left:
                    (constraints.maxWidth - 68).clamp(0, double.infinity) *
                    _petHorizontalProgress,
                top: _petVerticalOffset,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('rest-pet-interact-button'),
                    onTap: _recordPetTap,
                    borderRadius: BorderRadius.circular(40),
                    child: SizedBox(
                      width: 68,
                      height: 68,
                      child: Center(
                        child: Text(
                          widget.pet.emoji,
                          style: const TextStyle(fontSize: 50),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_showPointsReward)
                Positioned(
                  left:
                      (constraints.maxWidth - 68).clamp(0, double.infinity) *
                          _petHorizontalProgress +
                      18,
                  top: _petVerticalOffset - 10,
                  child: AnimatedBuilder(
                    animation: _pointsRewardController,
                    builder: (context, child) => Opacity(
                      opacity: 1 - _pointsRewardController.value,
                      child: Transform.translate(
                        offset: Offset(0, -40 * _pointsRewardController.value),
                        child: child,
                      ),
                    ),
                    child: const Text(
                      '+2 puntos',
                      key: Key('rest-pet-points-reward'),
                      style: TextStyle(
                        color: Color(0xFF006B70),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.white,
                            blurRadius: 5,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Caricias: ${widget.petPatCount + _petTaps}',
        key: const Key('rest-pet-pat-count'),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        'Minutos felices: $_petMoodMinutesThisSession',
        key: const Key('rest-pet-mood-minutes'),
      ),
      const SizedBox(height: 4),
      Text(
        'Cada 10 caricias: +2 puntos de estado. '
        'Próximo premio en '
        '${10 - ((widget.petPatCount + _petTaps) % 10)}.',
      ),
    ],
  );

  void _recordPetTap() {
    final nextPatCount = widget.petPatCount + _petTaps + 1;
    setState(() {
      _petTaps++;
      _showPointsReward = nextPatCount % 10 == 0;
    });
    widget.onPetPat();
    if (nextPatCount % 10 == 0) {
      _pointsRewardController.forward(from: 0);
    }
  }

  Widget _buildFreeRest(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Puedes usar el móvil o hacer otra actividad. El temporizador '
        'sigue activo.',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'Al terminar, recibirás una notificación para volver a tus tareas.',
      ),
    ],
  );
}

enum _FocusSessionPhase {
  focusing,
  paused,
  microPause,
  overtimeChoice,
  overtimeCountdown,
  freeMode,
  completed,
}

class FocusSessionResult {
  const FocusSessionResult({
    required this.bonusRest,
    required this.overtime,
    required this.finishedEarly,
    required this.finishedTooQuickly,
  });

  final Duration bonusRest;
  final Duration overtime;
  final bool finishedEarly;
  final bool finishedTooQuickly;
}

class FocusSessionPage extends StatefulWidget {
  const FocusSessionPage({
    super.key,
    required this.taskTitle,
    required this.avatar,
    required this.onRewardContinue,
    this.taskSize = FocusTaskSize.standard,
    this.overtimeBlockDuration = const Duration(minutes: 5),
    this.focusDuration,
    this.microPauseDuration = const Duration(minutes: 2),
  }) : assert(focusDuration == null || focusDuration > Duration.zero),
       assert(microPauseDuration > Duration.zero),
       assert(overtimeBlockDuration > Duration.zero);

  final String taskTitle;
  final UserAvatar avatar;
  final ValueChanged<FocusSessionResult> onRewardContinue;
  final Duration? focusDuration;
  final FocusTaskSize taskSize;
  final Duration microPauseDuration;
  final Duration overtimeBlockDuration;

  @override
  State<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends State<FocusSessionPage>
    with WidgetsBindingObserver {
  Timer? _ticker;
  DateTime? _backgroundedAt;
  late Duration _focusRemaining;
  late Duration _microPauseRemaining;
  late Duration _overtimeRemaining;
  Duration _overtimeElapsed = Duration.zero;
  FocusSessionResult? _result;
  _FocusSessionPhase _phase = _FocusSessionPhase.focusing;

  Duration get _focusDuration =>
      widget.focusDuration ?? widget.taskSize.duration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusRemaining = _focusDuration;
    _microPauseRemaining = widget.microPauseDuration;
    _overtimeRemaining = widget.overtimeBlockDuration;
    _beginCountdown(_FocusSessionPhase.focusing, _focusRemaining);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_phase == _FocusSessionPhase.focusing ||
          _phase == _FocusSessionPhase.microPause ||
          _phase == _FocusSessionPhase.overtimeCountdown ||
          _phase == _FocusSessionPhase.freeMode) {
        _backgroundedAt ??= DateTime.now();
        _ticker?.cancel();
        _ticker = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      _resumeAfterBackground();
    }
  }

  void _beginCountdown(_FocusSessionPhase phase, Duration duration) {
    _ticker?.cancel();
    _phase = phase;
    switch (phase) {
      case _FocusSessionPhase.focusing:
        _focusRemaining = duration;
      case _FocusSessionPhase.microPause:
        _microPauseRemaining = duration;
      case _FocusSessionPhase.overtimeCountdown:
        _overtimeRemaining = duration;
      case _FocusSessionPhase.paused:
      case _FocusSessionPhase.overtimeChoice:
      case _FocusSessionPhase.freeMode:
      case _FocusSessionPhase.completed:
        throw StateError('Cannot start a countdown for $phase.');
    }
    _startTicker();
  }

  void _refreshCountdown() {
    if (!mounted) return;
    setState(() {
      switch (_phase) {
        case _FocusSessionPhase.focusing:
          if (_focusRemaining <= const Duration(seconds: 1)) {
            _focusRemaining = Duration.zero;
            _phase = _FocusSessionPhase.overtimeChoice;
            _stopTicker();
          } else {
            _focusRemaining -= const Duration(seconds: 1);
          }
        case _FocusSessionPhase.microPause:
          if (_microPauseRemaining <= const Duration(seconds: 1)) {
            _microPauseRemaining = Duration.zero;
            _beginCountdown(_FocusSessionPhase.focusing, _focusRemaining);
          } else {
            _microPauseRemaining -= const Duration(seconds: 1);
          }
        case _FocusSessionPhase.overtimeCountdown:
          _overtimeElapsed += const Duration(seconds: 1);
          if (_overtimeRemaining <= const Duration(seconds: 1)) {
            _overtimeRemaining = Duration.zero;
            _phase = _FocusSessionPhase.overtimeChoice;
            _stopTicker();
          } else {
            _overtimeRemaining -= const Duration(seconds: 1);
          }
        case _FocusSessionPhase.freeMode:
          _overtimeElapsed += const Duration(seconds: 1);
          break;
        case _FocusSessionPhase.paused:
        case _FocusSessionPhase.overtimeChoice:
        case _FocusSessionPhase.completed:
          _stopTicker();
      }
    });
  }

  void _resumeAfterBackground() {
    final backgroundedAt = _backgroundedAt;
    if (backgroundedAt == null) return;
    _backgroundedAt = null;
    var elapsed = DateTime.now().difference(backgroundedAt);
    if (elapsed < Duration.zero) elapsed = Duration.zero;
    setState(() {
      switch (_phase) {
        case _FocusSessionPhase.focusing:
          _focusRemaining = _subtractElapsed(_focusRemaining, elapsed);
          if (_focusRemaining == Duration.zero) {
            _phase = _FocusSessionPhase.overtimeChoice;
          }
        case _FocusSessionPhase.microPause:
          if (elapsed >= _microPauseRemaining) {
            elapsed -= _microPauseRemaining;
            _microPauseRemaining = Duration.zero;
            _phase = _FocusSessionPhase.focusing;
            _focusRemaining = _subtractElapsed(_focusRemaining, elapsed);
            if (_focusRemaining == Duration.zero) {
              _phase = _FocusSessionPhase.overtimeChoice;
            }
          } else {
            _microPauseRemaining -= elapsed;
          }
        case _FocusSessionPhase.overtimeCountdown:
          final overtimeElapsed = elapsed > _overtimeRemaining
              ? _overtimeRemaining
              : elapsed;
          _overtimeElapsed += overtimeElapsed;
          _overtimeRemaining = _subtractElapsed(_overtimeRemaining, elapsed);
          if (_overtimeRemaining == Duration.zero) {
            _phase = _FocusSessionPhase.overtimeChoice;
          }
        case _FocusSessionPhase.freeMode:
          _overtimeElapsed += elapsed;
          break;
        case _FocusSessionPhase.paused:
        case _FocusSessionPhase.overtimeChoice:
        case _FocusSessionPhase.completed:
          return;
      }

      if (_phase == _FocusSessionPhase.focusing ||
          _phase == _FocusSessionPhase.microPause ||
          _phase == _FocusSessionPhase.overtimeCountdown ||
          _phase == _FocusSessionPhase.freeMode) {
        _startTicker();
      }
    });
  }

  Duration _subtractElapsed(Duration remaining, Duration elapsed) =>
      elapsed >= remaining ? Duration.zero : remaining - elapsed;

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshCountdown(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _pauseFocus() {
    _stopTicker();
    _phase = _FocusSessionPhase.paused;
  }

  void _startMicroPause() {
    _beginCountdown(_FocusSessionPhase.microPause, widget.microPauseDuration);
  }

  void _startOvertimeBlock() {
    _beginCountdown(
      _FocusSessionPhase.overtimeCountdown,
      widget.overtimeBlockDuration,
    );
  }

  void _startFreeMode() {
    _phase = _FocusSessionPhase.freeMode;
    _startTicker();
  }

  void _finishTask() {
    final finishedEarly =
        _phase == _FocusSessionPhase.focusing ||
        _phase == _FocusSessionPhase.paused;
    final finishedTooQuickly =
        finishedEarly &&
        _focusRemaining.inMicroseconds * 2 > _focusDuration.inMicroseconds;
    final remainingRest = finishedEarly && !finishedTooQuickly
        ? _focusRemaining
        : Duration.zero;
    final bonusRest = remainingRest > widget.taskSize.maxRestBonus
        ? widget.taskSize.maxRestBonus
        : remainingRest;
    _stopTicker();
    setState(() {
      _result = FocusSessionResult(
        bonusRest: bonusRest,
        overtime: _overtimeElapsed,
        finishedEarly: finishedEarly,
        finishedTooQuickly: finishedTooQuickly,
      );
      _phase = _FocusSessionPhase.completed;
    });
  }

  Future<void> _confirmAbandon() async {
    final shouldAbandon = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quieres abandonar el foco?'),
        content: const Text(
          'Este bloque no contará como terminado. Puedes volver a tu tarea '
          'cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir enfocándome'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );

    if (shouldAbandon == true && mounted) {
      _ticker?.cancel();
      Navigator.of(context).pop();
    }
  }

  String _spokenTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return 'Quedan $seconds segundos';
    return 'Quedan $minutes minutos y $seconds segundos';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return '$seconds s';
    if (seconds == 0) return '$minutes min';
    return '$minutes min $seconds s';
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _FocusSessionPhase.completed) return _buildReward(context);

    final isMicroPause = _phase == _FocusSessionPhase.microPause;
    final isPaused = _phase == _FocusSessionPhase.paused;
    final isOvertimeChoice = _phase == _FocusSessionPhase.overtimeChoice;
    final isOvertimeCountdown = _phase == _FocusSessionPhase.overtimeCountdown;
    final isFreeMode = _phase == _FocusSessionPhase.freeMode;
    final isZen = isOvertimeChoice || isFreeMode;
    final remaining = isMicroPause
        ? _microPauseRemaining
        : isOvertimeCountdown
        ? _overtimeRemaining
        : _focusRemaining;
    final total = isMicroPause
        ? widget.microPauseDuration
        : isOvertimeCountdown
        ? widget.overtimeBlockDuration
        : _focusDuration;
    final progress = (remaining.inMilliseconds / total.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
    final phaseLabel = isOvertimeChoice
        ? 'El bloque de foco ha terminado. Elige cómo continuar.'
        : isFreeMode
        ? 'Modo libre. Tiempo extra: ${_formatDuration(_overtimeElapsed)}.'
        : isOvertimeCountdown
        ? 'Prórroga. ${_spokenTime(remaining)}.'
        : isMicroPause
        ? 'Micro-pausa. ${_spokenTime(remaining)}.'
        : isPaused
        ? 'Foco en pausa. ${_spokenTime(remaining)}.'
        : 'Modo foco. ${_spokenTime(remaining)}.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo foco'),
        leading: IconButton(
          tooltip: 'Abandonar foco',
          onPressed: _confirmAbandon,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              isOvertimeChoice
                  ? 'Sigue a tu ritmo'
                  : isFreeMode
                  ? 'Modo libre'
                  : isOvertimeCountdown
                  ? 'Cinco minutos más'
                  : isMicroPause
                  ? 'Tómate un respiro'
                  : isPaused
                  ? 'Tu foco está en pausa'
                  : 'Te acompaño en esta tarea',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.taskTitle,
              key: const Key('focus-task-title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: const Color(0xFF52685B)),
            ),
            const SizedBox(height: 24),
            if (isZen)
              Semantics(
                label: phaseLabel,
                child: Container(
                  key: const Key('focus-zen-state'),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: FocusPawsApp._mint,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.avatar.emoji,
                        key: const Key('focus-pet-zen-avatar'),
                        style: const TextStyle(fontSize: 88),
                      ),
                      if (isFreeMode) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tiempo extra · ${_formatDuration(_overtimeElapsed)}',
                          key: const Key('focus-overtime-elapsed'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: const Color(0xFF52685B)),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Semantics(
                label: phaseLabel,
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 224,
                    width: 224,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 210,
                          width: 210,
                          child: CircularProgressIndicator(
                            key: const Key('focus-timer-progress'),
                            value: progress,
                            strokeWidth: 17,
                            backgroundColor: FocusPawsApp._mintDeep,
                            color: isMicroPause
                                ? const Color(0xFFE9A72B)
                                : isOvertimeCountdown
                                ? const Color(0xFFE9A72B)
                                : FocusPawsApp._forest,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          widget.avatar.emoji,
                          key: const Key('focus-pet-avatar'),
                          style: const TextStyle(fontSize: 78),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              isOvertimeChoice
                  ? '${widget.avatar.petName} te anima a seguir. '
                        '¿Qué necesitas ahora?'
                  : isFreeMode
                  ? 'Sin prisa y sin cuenta atrás. Pulsa cuando termines.'
                  : isOvertimeCountdown
                  ? 'Tu mascota sigue contigo. Puedes terminar cuando quieras.'
                  : isMicroPause
                  ? 'Estira los brazos y bebe un poco de agua. '
                        'Volveremos al foco automáticamente.'
                  : isPaused
                  ? 'El tiempo está detenido. Cuando quieras, seguimos.'
                  : 'Un paso cada vez. Tu mascota sigue aquí contigo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF52685B), height: 1.4),
            ),
            const SizedBox(height: 28),
            if (isOvertimeChoice) ...[
              FilledButton.icon(
                key: const Key('focus-overtime-five-more-button'),
                onPressed: () => setState(_startOvertimeBlock),
                icon: const Icon(Icons.add_alarm_rounded),
                label: const Text('Necesito 5 minutos más'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('focus-overtime-free-mode-button'),
                onPressed: () => setState(_startFreeMode),
                icon: const Icon(Icons.self_improvement_rounded),
                label: const Text('Seguir en modo libre'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                key: const Key('focus-finish-task-button'),
                onPressed: _finishTask,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Finalizar tarea'),
              ),
            ] else if (isOvertimeCountdown || isFreeMode) ...[
              FilledButton(
                key: const Key('focus-finish-task-button'),
                onPressed: _finishTask,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Finalizar tarea'),
              ),
              if (isOvertimeCountdown) ...[
                const SizedBox(height: 10),
                TextButton(
                  key: const Key('focus-overtime-free-mode-button'),
                  onPressed: () => setState(_startFreeMode),
                  child: const Text('Seguir en modo libre'),
                ),
              ],
            ] else if (_phase == _FocusSessionPhase.focusing) ...[
              FilledButton(
                key: const Key('focus-finish-early-button'),
                onPressed: _finishTask,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('¡Terminé antes!'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('focus-pause-button'),
                onPressed: () => setState(_pauseFocus),
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pausar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('focus-micro-pause-button'),
                onPressed: () => setState(_startMicroPause),
                icon: const Icon(Icons.self_improvement_rounded),
                label: const Text('Micro-pausa de 2 minutos'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ] else if (isPaused)
              Column(
                children: [
                  FilledButton(
                    key: const Key('focus-finish-early-button'),
                    onPressed: _finishTask,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: const Text('¡Terminé antes!'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: const Key('focus-resume-button'),
                    onPressed: () => setState(
                      () => _beginCountdown(
                        _FocusSessionPhase.focusing,
                        _focusRemaining,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Reanudar foco'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            TextButton.icon(
              key: const Key('focus-abandon-button'),
              onPressed: _confirmAbandon,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Abandonar foco'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReward(BuildContext context) {
    final result = _result!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉 🐾 🎉', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 20),
                Text(
                  widget.avatar.emoji,
                  key: const Key('reward-pet-avatar'),
                  style: const TextStyle(fontSize: 88),
                ),
                const SizedBox(height: 18),
                Text(
                  '¡Conseguido!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  result.finishedEarly
                      ? result.finishedTooQuickly
                            ? '¡Vaya, qué rápido! ${widget.avatar.petName} '
                                  'celebra que hayas terminado. Esta vez tu '
                                  'descanso será el estándar, sin minutos extra.'
                            : '¡Guau! Tu cerebro ha volado hoy. '
                                  '${widget.avatar.petName} celebra tu rapidez.'
                      : result.overtime > Duration.zero
                      ? '${widget.avatar.petName} está orgulloso de tu '
                            'perseverancia. Has completado «${widget.taskTitle}».'
                      : 'Has completado «${widget.taskTitle}». '
                            '${widget.avatar.petName} celebra contigo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  '+${widget.taskSize.points} puntos de energía para tu mascota',
                  key: const Key('focus-reward-points'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: FocusPawsApp._forest,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (result.bonusRest > Duration.zero) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Tiempo de Bonificación para Descanso: '
                    '+${_formatDuration(result.bonusRest)}',
                    key: const Key('focus-bonus-rest-reward'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF52685B)),
                  ),
                ],
                if (result.finishedTooQuickly) ...[
                  const SizedBox(height: 10),
                  Text(
                    'El descanso será el estándar, sin bonificación adicional.',
                    key: const Key('focus-standard-rest-message'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF52685B)),
                  ),
                ],
                if (result.overtime > Duration.zero) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Tiempo extra realizado: ${_formatDuration(result.overtime)}',
                    key: const Key('focus-overtime-total-reward'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF52685B)),
                  ),
                ],
                if (result.overtime > const Duration(minutes: 10)) ...[
                  const SizedBox(height: 10),
                  Text(
                    '🍪 ¡Snack para ${widget.avatar.petName} por tu '
                    'perseverancia!',
                    key: const Key('focus-perseverance-snack-reward'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF805915),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  key: const Key('focus-reward-continue-button'),
                  onPressed: () {
                    widget.onRewardContinue(result);
                    Navigator.of(context).pop(result);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: Image.asset(
            'assets/launcher/focuspaws_sin_texto_1024.png',
            key: const Key('brand-logo'),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 11),
        Text(
          'FocusPaws',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.earnedPoints,
    required this.levelUpAnimation,
    required this.avatar,
    required this.bonusRest,
    required this.perseveranceSnacks,
  });

  final int earnedPoints;
  final Animation<double> levelUpAnimation;
  final UserAvatar avatar;
  final Duration bonusRest;
  final int perseveranceSnacks;

  @override
  Widget build(BuildContext context) {
    final progress = PetProgress.fromTotalPoints(earnedPoints);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FocusPawsApp._mint, FocusPawsApp._mintDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Soy ${avatar.petName} 🐾',
                        key: const Key('progress-pet-name'),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0CE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NIVEL ${progress.level}',
                        key: const Key('pet-level-label'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF805915),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  earnedPoints == 0
                      ? 'Listo para empezar contigo.'
                      : '¡Cada paso cuenta!',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFF52685B)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Progreso hacia nivel ${progress.nextLevel}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF52685B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          key: const Key('pet-level-progress'),
                          value: progress.progress,
                          minHeight: 8,
                          backgroundColor: FocusPawsApp._mintDeep,
                          color: FocusPawsApp._forest,
                          semanticsLabel: 'Progreso de ${avatar.petName}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${progress.pointsInLevel} / '
                      '${progress.pointsRequired} pts',
                      key: const Key('pet-level-points'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF355544),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (bonusRest > Duration.zero || perseveranceSnacks > 0) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (bonusRest > Duration.zero)
                        _PetRewardBadge(
                          key: const Key('pet-bonus-rest-badge'),
                          label: 'Descanso +${_formatDuration(bonusRest)}',
                        ),
                      if (perseveranceSnacks > 0)
                        _PetRewardBadge(
                          key: const Key('pet-snacks-badge'),
                          label: '🍪 $perseveranceSnacks',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PetAvatar(
            level: progress.level,
            levelUpAnimation: levelUpAnimation,
            avatar: avatar,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return '$seconds s';
    if (seconds == 0) return '$minutes min';
    return '$minutes min $seconds s';
  }
}

class _DailyStickerCard extends StatelessWidget {
  const _DailyStickerCard({
    required this.completedTasks,
    required this.unlockedStickerCount,
    required this.stickerUnlockedToday,
    required this.showAlbum,
    required this.onPressed,
  });

  final int completedTasks;
  final int unlockedStickerCount;
  final bool stickerUnlockedToday;
  final bool showAlbum;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: FocusPawsApp._mint,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      key: const Key('open-sticker-album-button'),
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            const Text('🌟', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showAlbum ? 'Álbum de pegatinas' : 'Progreso de hoy',
                    // Keep daily progress visible if the premium album is hidden.
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stickerUnlockedToday
                        ? '¡Pegatina de hoy desbloqueada!'
                        : '$completedTasks de '
                              '${FocusPawsFeatures.tasksPerDailySticker} tareas '
                              'para la pegatina de hoy',
                    key: const Key('daily-sticker-progress'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFF52685B)),
                  ),
                  Text(
                    showAlbum
                        ? '$unlockedStickerCount '
                              '${unlockedStickerCount == 1 ? 'pegatina' : 'pegatinas'} '
                              'en tu colección'
                        : 'Progreso de hoy',
                    key: const Key('sticker-collection-count'),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: const Color(0xFF64756D)),
                  ),
                ],
              ),
            ),
            if (showAlbum) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _StickerDesign {
  const _StickerDesign(this.emoji, this.name);

  final String emoji;
  final String name;
}

const _stickerDesigns = [
  _StickerDesign('🌟', 'Estrella brillante'),
  _StickerDesign('🐾', 'Huella amiga'),
  _StickerDesign('🍀', 'Trébol de la suerte'),
  _StickerDesign('🎈', 'Globo alegre'),
  _StickerDesign('🦋', 'Mariposa tranquila'),
  _StickerDesign('🌈', 'Arcoíris de colores'),
  _StickerDesign('🍓', 'Fresa dulce'),
  _StickerDesign('🌙', 'Luna serena'),
  _StickerDesign('🧸', 'Osito tierno'),
  _StickerDesign('🎨', 'Paleta creativa'),
  _StickerDesign('🌻', 'Girasol sonriente'),
  _StickerDesign('💎', 'Gema brillante'),
];

class StickerAlbumPage extends StatelessWidget {
  const StickerAlbumPage({super.key, required this.unlockedDates});

  final List<String> unlockedDates;

  String _displayDate(String dateKey) {
    final date = DateTime.parse(dateKey);
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Álbum de pegatinas')),
    body: SafeArea(
      child: unlockedDates.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📒', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      'Tu álbum empieza aquí',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Completa tres tareas en un mismo día para ganar '
                      'una pegatina.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Cada pegatina recuerda un día en que completaste '
                  '${FocusPawsFeatures.tasksPerDailySticker} tareas.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  key: const Key('sticker-album-grid'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unlockedDates.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisExtent: 132,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final design =
                        _stickerDesigns[index % _stickerDesigns.length];
                    final date = unlockedDates[index];
                    return Container(
                      key: Key('sticker-$date'),
                      decoration: BoxDecoration(
                        color: FocusPawsApp._mint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FocusPawsApp._mintBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            design.emoji,
                            style: const TextStyle(fontSize: 38),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            design.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _displayDate(date),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: const Color(0xFF64756D)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    ),
  );
}

class _PetRewardBadge extends StatelessWidget {
  const _PetRewardBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF355544),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({
    required this.level,
    required this.levelUpAnimation,
    required this.avatar,
  });

  final int level;
  final Animation<double> levelUpAnimation;
  final UserAvatar avatar;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: '${avatar.petName}, nivel $level',
      image: true,
      child: SizedBox(
        width: 88,
        height: 88,
        child: AnimatedBuilder(
          animation: levelUpAnimation,
          builder: (context, child) {
            final progress = levelUpAnimation.value;
            final celebration = reduceMotion
                ? 0.0
                : math.sin(math.pi * progress);

            return Transform.scale(
              key: const Key('pet-level-up-animation'),
              scale: 1 + 0.28 * celebration,
              child: Transform.rotate(
                angle: reduceMotion
                    ? 0
                    : 0.12 * math.sin(progress * math.pi * 4),
                child: child,
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: FocusPawsApp._mintSurface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    avatar.emoji,
                    key: const Key('progress-pet-avatar'),
                    style: const TextStyle(fontSize: 43),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: FocusPawsApp._forest,
                    shape: BoxShape.circle,
                    border: Border.all(color: FocusPawsApp._mint, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$level',
                    key: const Key('pet-level-avatar-badge'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: levelUpAnimation,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  key: Key('pet-level-up-sparkle'),
                  color: Color(0xFFE9A72B),
                  size: 25,
                ),
                builder: (context, child) => Positioned(
                  top: -4,
                  right: -2,
                  child: Opacity(
                    opacity: reduceMotion
                        ? 0
                        : math.sin(math.pi * levelUpAnimation.value),
                    child: Transform.scale(
                      scale: reduceMotion
                          ? 0.7
                          : 0.7 +
                                0.4 *
                                    math.sin(math.pi * levelUpAnimation.value),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTasksCard extends StatelessWidget {
  const _EmptyTasksCard({
    this.title = 'Empezamos con calma',
    this.message = 'Añade una tarea y la tendrás a la vista.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FocusPawsApp._mintBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: FocusPawsApp._mintSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_outlined, color: Color(0xFF527261)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: const Color(0xFF64756D)),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onChanged,
    required this.onStart,
  });

  final FocusTask task;
  final ValueChanged<bool> onChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: FocusPawsApp._mintBorder),
    );

    return Material(
      color: Colors.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        key: ValueKey('task-${task.id}'),
        value: task.isCompleted,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        controlAffinity: ListTileControlAffinity.leading,
        secondary: IconButton(
          key: ValueKey('start-focus-${task.id}'),
          tooltip: 'Iniciar foco: ${task.title}',
          onPressed: task.isCompleted ? null : onStart,
          icon: const Icon(Icons.play_circle_fill_rounded),
          color: FocusPawsApp._forest,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: task.isCompleted
                ? const Color(0xFF7C8B83)
                : const Color(0xFF1E3029),
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${task.size.label} · ${task.size.minutes} min · '
          '+${task.size.points} pts',
          style: const TextStyle(color: Color(0xFF64756D)),
        ),
        activeColor: FocusPawsApp._forest,
        shape: shape,
      ),
    );
  }
}

abstract interface class TaskSpeechRecognizer {
  Future<bool> initialize({
    required ValueChanged<String> onStatus,
    required ValueChanged<String> onError,
  });

  Future<String?> spanishLocaleId();

  Future<void> listen({
    required String localeId,
    required ValueChanged<String> onResult,
  });

  Future<void> stop();

  Future<void> cancel();
}

class _TaskSizeButton extends StatelessWidget {
  const _TaskSizeButton({
    required this.size,
    required this.selected,
    required this.onPressed,
  });

  final FocusTaskSize size;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${size.label}, ${size.minutes} minutos, ${size.points} puntos',
    child: OutlinedButton(
      key: Key('task-size-${size.name}'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? FocusPawsApp._mint : Colors.white,
        foregroundColor: FocusPawsApp._forest,
        side: BorderSide(
          color: selected ? FocusPawsApp._forest : FocusPawsApp._mintBorder,
          width: selected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            size.buttonLabel,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    ),
  );
}

class _DeviceTaskSpeechRecognizer implements TaskSpeechRecognizer {
  final SpeechToText _speech = SpeechToText();

  @override
  Future<bool> initialize({
    required ValueChanged<String> onStatus,
    required ValueChanged<String> onError,
  }) {
    return _speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError(error.errorMsg),
    );
  }

  @override
  Future<String?> spanishLocaleId() async {
    final locales = await _speech.locales();
    for (final locale in locales) {
      if (locale.localeId.replaceAll('_', '-').toLowerCase() == 'es-es') {
        return locale.localeId;
      }
    }

    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('es')) {
        return locale.localeId;
      }
    }

    return null;
  }

  @override
  Future<void> listen({
    required String localeId,
    required ValueChanged<String> onResult,
  }) async {
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, this.speechRecognizer});

  final TaskSpeechRecognizer? speechRecognizer;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _controller = TextEditingController();
  late final TaskSpeechRecognizer _speech =
      widget.speechRecognizer ?? _DeviceTaskSpeechRecognizer();
  String _voiceBaseText = '';
  String? _errorText;
  String? _voiceMessage;
  bool _isStartingVoice = false;
  bool _isListening = false;
  FocusTaskSize _selectedSize = FocusTaskSize.standard;

  @override
  void dispose() {
    if (_isListening) {
      _speech.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorText = 'Escribe una tarea para poder guardarla.';
      });
      return;
    }

    Navigator.of(context)
        .pop(FocusTaskDraft(title: title, size: _selectedSize));
  }

  Future<void> _toggleVoiceInput() async {
    if (_isStartingVoice) return;

    if (_isListening) {
      try {
        await _speech.stop();
        if (mounted) {
          setState(() {
            _isListening = false;
            _voiceMessage = _controller.text.trim().isEmpty
                ? 'No se detectó voz. Puedes intentarlo de nuevo o escribir.'
                : 'Dictado finalizado. Puedes revisar el texto.';
          });
        }
      } on Exception {
        if (mounted) {
          setState(() {
            _isListening = false;
            _voiceMessage =
                'No se pudo detener el dictado. Puedes continuar escribiendo.';
          });
        }
      }
      return;
    }

    setState(() {
      _isStartingVoice = true;
      _voiceMessage = 'Preparando el micrófono...';
      _errorText = null;
    });

    try {
      final available = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
      );
      if (!mounted) return;

      if (!available) {
        setState(() {
          _isStartingVoice = false;
          _voiceMessage =
              'No se pudo acceder al micrófono o al reconocimiento de voz. '
              'Revisa el permiso del micrófono o escribe la tarea.';
        });
        return;
      }

      final localeId = await _speech.spanishLocaleId();
      if (!mounted) return;

      if (localeId == null) {
        setState(() {
          _isStartingVoice = false;
          _voiceMessage =
              'El reconocimiento en español no está disponible. '
              'Revisa los idiomas de voz del dispositivo o escribe la tarea.';
        });
        return;
      }

      _voiceBaseText = _controller.text.trim();
      await _speech.listen(localeId: localeId, onResult: _handleSpeechResult);
      if (mounted) {
        setState(() {
          _isStartingVoice = false;
          _isListening = true;
          _voiceMessage = 'Escuchando... Habla con naturalidad.';
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _isStartingVoice = false;
          _isListening = false;
          _voiceMessage =
              'No se pudo iniciar el dictado. Puedes intentarlo de nuevo '
              'o escribir la tarea.';
        });
      }
    }
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;

    if (status == SpeechToText.listeningStatus) {
      setState(() {
        _isStartingVoice = false;
        _isListening = true;
        _voiceMessage = 'Escuchando... Habla con naturalidad.';
      });
    } else if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      final wasListening = _isListening;
      setState(() {
        _isStartingVoice = false;
        _isListening = false;
        if (wasListening) {
          _voiceMessage = _controller.text.trim().isEmpty
              ? 'No se detectó voz. Puedes intentarlo de nuevo o escribir.'
              : 'Dictado finalizado. Puedes revisar el texto.';
        }
      });
    }
  }

  void _handleSpeechError(String _) {
    if (!mounted) return;
    setState(() {
      _isStartingVoice = false;
      _isListening = false;
      _voiceMessage =
          'No se pudo reconocer la voz. Comprueba el permiso y vuelve '
          'a intentarlo, o escribe la tarea.';
    });
  }

  void _handleSpeechResult(String recognizedWords) {
    final words = recognizedWords.trim();
    if (!mounted || words.isEmpty) return;

    final combinedText = _voiceBaseText.isEmpty
        ? words
        : '$_voiceBaseText $words';
    final text = combinedText.length > 100
        ? combinedText.substring(0, 100).trimRight()
        : combinedText;

    setState(() {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: FocusPawsApp._mintSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FocusPawsApp._mintBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '¿Qué tienes en mente?',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Anótalo aquí. Lo demás puede esperar.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFF64756D)),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const Key('task-title-field'),
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLength: 100,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() {
                        _errorText = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Por ejemplo: preparar el desayuno',
                    errorText: _errorText,
                    counterText: '',
                    suffixIcon: IconButton(
                      key: const Key('voice-input-button'),
                      tooltip: _isListening
                          ? 'Detener dictado'
                          : 'Dictar tarea',
                      onPressed: _isStartingVoice ? null : _toggleVoiceInput,
                      icon: _isStartingVoice
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isListening
                                  ? Icons.stop_circle_rounded
                                  : Icons.mic_rounded,
                            ),
                      style: IconButton.styleFrom(
                        foregroundColor: _isListening
                            ? const Color(0xFFB34343)
                            : FocusPawsApp._forest,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: FocusPawsApp._mintBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: FocusPawsApp._mintBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: FocusPawsApp._forest,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '¿Cuánto tiempo crees que necesitas?',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final size in FocusTaskSize.values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: size == FocusTaskSize.long ? 0 : 8,
                          ),
                          child: _TaskSizeButton(
                            size: size,
                            selected: _selectedSize == size,
                            onPressed: () {
                              setState(() {
                                _selectedSize = size;
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                if (_voiceMessage case final voiceMessage?) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      voiceMessage,
                      key: const Key('voice-status-message'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _isListening
                            ? FocusPawsApp._forest
                            : const Color(0xFF64756D),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Ahora no'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('save-task-button'),
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
