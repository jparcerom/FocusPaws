import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const FocusPawsApp());
}

class FocusPawsApp extends StatelessWidget {
  const FocusPawsApp({super.key, this.profileStore});

  final UserProfileStore? profileStore;

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

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.profileStore});

  final UserProfileStore profileStore;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final List<FocusTask> _tasks = [];
  int _nextTaskId = 0;
  int _earnedPoints = 0;
  late final AnimationController _levelUpController;
  late Future<UserProfile?> _profileFuture;

  int get _completedCount => _tasks.where((task) => task.isCompleted).length;

  @override
  void initState() {
    super.initState();
    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _profileFuture = widget.profileStore.loadProfile();
  }

  @override
  void dispose() {
    _levelUpController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskSheet(),
    );

    if (!mounted || title == null) return;

    setState(() {
      _tasks.insert(0, FocusTask(id: _nextTaskId++, title: title));
    });
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

  void _toggleTask(FocusTask task, bool isCompleted) {
    var leveledUp = false;
    setState(() {
      if (!task.isCompleted && isCompleted) {
        final previousLevel = PetProgress.fromTotalPoints(_earnedPoints).level;
        _earnedPoints += 15;
        leveledUp =
            PetProgress.fromTotalPoints(_earnedPoints).level > previousLevel;
      }
      task.isCompleted = isCompleted;
    });

    if (leveledUp) {
      _levelUpController.forward(from: 0);
    }
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

        return _buildHome(context, profile);
      },
    );
  }

  Widget _buildHome(BuildContext context, UserProfile profile) {
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
            if (_tasks.isEmpty)
              const _EmptyTasksCard()
            else
              ..._tasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TaskCard(
                    task: task,
                    onChanged: (value) => _toggleTask(task, value),
                  ),
                ),
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
  FocusTask({required this.id, required this.title});

  final int id;
  final String title;
  bool isCompleted = false;
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
  });

  final int earnedPoints;
  final Animation<double> levelUpAnimation;
  final UserAvatar avatar;

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
  const _EmptyTasksCard();

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
            'Empezamos con calma',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Añade una tarea y la tendrás a la vista.',
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
  const _TaskCard({required this.task, required this.onChanged});

  final FocusTask task;
  final ValueChanged<bool> onChanged;

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

    Navigator.of(context).pop(title);
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
                    tooltip: _isListening ? 'Detener dictado' : 'Dictar tarea',
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
    );
  }
}
