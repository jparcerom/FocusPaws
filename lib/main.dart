import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const FocusPawsApp());
}

class FocusPawsApp extends StatelessWidget {
  const FocusPawsApp({
    super.key,
    this.profileStore,
    this.progressStore,
    this.focusDuration,
    this.overtimeBlockDuration = const Duration(minutes: 5),
  });

  final UserProfileStore? profileStore;
  final FocusTasksProgressStore? progressStore;
  final Duration? focusDuration;
  final Duration overtimeBlockDuration;

  static const _forest = Color(0xFF28644F);
  static const _ink = Color(0xFF1E3029);
  static const _canvas = Color(0xFFF7F8F4);

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
      ),
    );
  }
}

enum UserAvatar {
  dog(id: 'dog', label: 'Perro', petName: 'Nori', emoji: '🐶'),
  cat(id: 'cat', label: 'Gato', petName: 'Kitty', emoji: '🐱'),
  fox(id: 'fox', label: 'Zorro', petName: 'Foxy', emoji: '🦊'),
  rabbit(id: 'rabbit', label: 'Conejo', petName: 'Bunny', emoji: '🐰'),
  bear(id: 'bear', label: 'Oso', petName: 'Bruno', emoji: '🐻');

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
  short(minutes: 15, points: 5, maxRestBonusMinutes: 3, label: 'Paso corto'),
  standard(
    minutes: 30,
    points: 15,
    maxRestBonusMinutes: 7,
    label: 'Bloque estándar',
  ),
  long(
    minutes: 45,
    points: 30,
    maxRestBonusMinutes: 10,
    label: 'Gran esfuerzo',
  );

  const FocusTaskSize({
    required this.minutes,
    required this.points,
    required this.maxRestBonusMinutes,
    required this.label,
  });

  final int minutes;
  final int points;
  final int maxRestBonusMinutes;
  final String label;

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
  const UserProfile({required this.name, required this.avatar});

  final String name;
  final UserAvatar avatar;
}

abstract interface class UserProfileStore {
  Future<UserProfile?> loadProfile();

  Future<void> saveProfile(UserProfile profile);
}

class SharedPreferencesUserProfileStore implements UserProfileStore {
  static const _nameKey = 'user_profile_name';
  static const _avatarKey = 'user_profile_avatar';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<UserProfile?> loadProfile() async {
    final name = (await _preferences.getString(_nameKey))?.trim();
    final avatar = UserAvatar.fromId(await _preferences.getString(_avatarKey));

    if (name == null || name.isEmpty || avatar == null) return null;
    return UserProfile(name: name, avatar: avatar);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _preferences.setString(_nameKey, profile.name);
    await _preferences.setString(_avatarKey, profile.avatar.id);
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
  }) : tasks = List.unmodifiable(tasks) {
    if (points < 0) throw ArgumentError.value(points, 'points');
    if (bonusRestSeconds < 0) {
      throw ArgumentError.value(bonusRestSeconds, 'bonusRestSeconds');
    }
    if (perseveranceSnacks < 0) {
      throw ArgumentError.value(perseveranceSnacks, 'perseveranceSnacks');
    }
    final ids = tasks.map((task) => task.id).toSet();
    if (ids.length != tasks.length) {
      throw ArgumentError('Task IDs must be unique.');
    }
  }

  final List<FocusTaskProgress> tasks;
  final int points;
  final int bonusRestSeconds;
  final int perseveranceSnacks;

  static const empty = FocusTasksProgress._(
    tasks: [],
    points: 0,
    bonusRestSeconds: 0,
    perseveranceSnacks: 0,
  );

  const FocusTasksProgress._({
    required this.tasks,
    required this.points,
    required this.bonusRestSeconds,
    required this.perseveranceSnacks,
  });

  factory FocusTasksProgress.fromJson(String json) {
    final value = jsonDecode(json);
    if (value is! Map<String, dynamic> ||
        value['points'] is! int ||
        value['tasks'] is! List<Object?> ||
        (value['bonusRestSeconds'] != null &&
            value['bonusRestSeconds'] is! int) ||
        (value['perseveranceSnacks'] != null &&
            value['perseveranceSnacks'] is! int)) {
      throw const FormatException('Invalid saved task progress.');
    }

    final tasks = (value['tasks'] as List<Object?>)
        .map(FocusTaskProgress.fromJson)
        .toList();
    try {
      return FocusTasksProgress(
        tasks: tasks,
        points: value['points'] as int,
        bonusRestSeconds: value['bonusRestSeconds'] as int? ?? 0,
        perseveranceSnacks: value['perseveranceSnacks'] as int? ?? 0,
      );
    } on ArgumentError {
      throw const FormatException('Invalid saved task progress.');
    }
  }

  String toJson() => jsonEncode({
    'points': points,
    'bonusRestSeconds': bonusRestSeconds,
    'perseveranceSnacks': perseveranceSnacks,
    'tasks': tasks.map((task) => task.toJson()).toList(),
  });
}

abstract interface class FocusTasksProgressStore {
  Future<FocusTasksProgress> loadProgress();

  Future<void> saveProgress(FocusTasksProgress progress);
}

class SharedPreferencesFocusTasksProgressStore
    implements FocusTasksProgressStore {
  static const _progressKey = 'focus_tasks_progress';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<FocusTasksProgress> loadProgress() async {
    final json = await _preferences.getString(_progressKey);
    return json == null
        ? FocusTasksProgress.empty
        : FocusTasksProgress.fromJson(json);
  }

  @override
  Future<void> saveProgress(FocusTasksProgress progress) =>
      _preferences.setString(_progressKey, progress.toJson());
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.profileStore,
    required this.progressStore,
    this.focusDuration,
    this.overtimeBlockDuration = const Duration(minutes: 5),
  });

  final UserProfileStore profileStore;
  final FocusTasksProgressStore progressStore;
  final Duration? focusDuration;
  final Duration overtimeBlockDuration;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final List<FocusTask> _tasks = [];
  int _nextTaskId = 0;
  int _earnedPoints = 0;
  Duration _bonusRest = Duration.zero;
  int _perseveranceSnacks = 0;
  late final AnimationController _levelUpController;
  late Future<UserProfile?> _profileFuture;
  late Future<FocusTasksProgress> _progressFuture;
  Future<void> _pendingProgressSave = Future<void>.value();
  bool _hasRestoredProgress = false;
  bool _showAllPendingTasks = false;
  bool _showCompletedTasks = false;

  int get _completedCount => _tasks.where((task) => task.isCompleted).length;

  @override
  void initState() {
    super.initState();
    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _profileFuture = widget.profileStore.loadProfile();
    _progressFuture = widget.progressStore.loadProgress();
  }

  @override
  void dispose() {
    _levelUpController.dispose();
    super.dispose();
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

  Future<void> _saveProfile(UserProfile profile) async {
    await widget.profileStore.saveProfile(profile);
    if (!mounted) return;
    setState(() {
      _profileFuture = Future.value(profile);
    });
  }

  void _retryProfileLoad() {
    setState(() {
      _profileFuture = widget.profileStore.loadProfile();
    });
  }

  void _retryProgressLoad() {
    setState(() {
      _progressFuture = widget.progressStore.loadProgress();
    });
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
    );
    _pendingProgressSave = _pendingProgressSave
        .catchError((Object _) {})
        .then((_) => widget.progressStore.saveProgress(snapshot));
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
    _tasks
      ..clear()
      ..addAll(
        progress.tasks.map(
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
    _perseveranceSnacks = progress.perseveranceSnacks;
  }

  void _toggleTask(FocusTask task, bool isCompleted) {
    if (isCompleted && !task.isCompleted) {
      _completeTask(task);
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
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ProfileLoadingScreen();
        }

        if (snapshot.hasError) {
          return _ProfileErrorScreen(onRetry: _retryProfileLoad);
        }

        final profile = snapshot.data;
        if (profile == null) {
          return WelcomeScreen(onSave: _saveProfile);
        }

        return FutureBuilder<FocusTasksProgress>(
          future: _progressFuture,
          builder: (context, progressSnapshot) {
            if (progressSnapshot.connectionState != ConnectionState.done) {
              return const _ProgressLoadingScreen();
            }
            if (progressSnapshot.hasError) {
              return _ProgressErrorScreen(onRetry: _retryProgressLoad);
            }
            if (!_hasRestoredProgress) {
              _restoreProgress(progressSnapshot.requireData);
              _hasRestoredProgress = true;
            }
            return _buildHome(context, profile);
          },
        );
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
            const _BrandHeader(),
            const SizedBox(height: 28),
            _PersonalGreeting(profile: profile),
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
                    'Tu foco de hoy',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$_completedCount/${_tasks.length} hechas',
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
                title: '¡Todo el foco de hoy está hecho!',
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

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onSave});

  final Future<void> Function(UserProfile profile) onSave;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  UserAvatar _selectedAvatar = UserAvatar.dog;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
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
      await widget.onSave(UserProfile(name: name, avatar: _selectedAvatar));
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
                  colors: [Color(0xFFE5F1E9), Color(0xFFD8EBDD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F8F4),
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
                    '¡Qué bueno tenerte aquí!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Personaliza tu espacio antes de empezar.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF52685B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
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
                  borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF28644F),
                    width: 1.5,
                  ),
                ),
              ),
            ),
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
                    color: isSelected ? const Color(0xFFE4F0E8) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF28644F)
                            : const Color(0xFFE3E9E3),
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
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: FilledButton(
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
              : const Text('Empezar'),
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
  const _PersonalGreeting({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: const Color(0xFFE5F1E9),
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
                            backgroundColor: const Color(0xFFDCE8DF),
                            color: isMicroPause
                                ? const Color(0xFFE9A72B)
                                : isOvertimeCountdown
                                ? const Color(0xFFE9A72B)
                                : const Color(0xFF28644F),
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
                    color: const Color(0xFF28644F),
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
                    Navigator.of(context).pop();
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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F0E8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: Color(0xFF28644F),
            size: 23,
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
          colors: [Color(0xFFE5F1E9), Color(0xFFD8EBDD)],
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
                Text(
                  'TU COMPAÑERO DE HOY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF4F6C5D),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${avatar.petName} 🐾',
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
                const SizedBox(height: 4),
                Text(
                  earnedPoints == 0
                      ? 'Listo para empezar contigo.'
                      : '¡Cada paso cuenta!',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFF52685B)),
                ),
                const SizedBox(height: 14),
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
                          backgroundColor: const Color(0xFFB8D3C0),
                          color: const Color(0xFF28644F),
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
                const SizedBox(height: 4),
                Text(
                  '${progress.totalPoints} pts totales',
                  key: const Key('pet-total-points'),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: const Color(0xFF52685B)),
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
                    color: const Color(0xFFF7F8F4).withValues(alpha: 0.8),
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
                    color: const Color(0xFF28644F),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD8EBDD),
                      width: 2,
                    ),
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
        border: Border.all(color: const Color(0xFFE8ECE7)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4EF),
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
      side: const BorderSide(color: Color(0xFFE8ECE7)),
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
          color: const Color(0xFF28644F),
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
        activeColor: const Color(0xFF28644F),
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
        backgroundColor: selected ? const Color(0xFFE5F1E9) : Colors.white,
        foregroundColor: const Color(0xFF28644F),
        side: BorderSide(
          color: selected ? const Color(0xFF28644F) : const Color(0xFFDCE4DC),
          width: selected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            size.label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: const Color(0xFF52685B), fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${size.minutes} min',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            '+${size.points} pts',
            style: Theme.of(context).textTheme.labelSmall,
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
        color: const Color(0xFFF7F8F4),
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
                      color: const Color(0xFFD3DCD5),
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
                            : const Color(0xFF28644F),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFDCE4DC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF28644F),
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
                            ? const Color(0xFF28644F)
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
