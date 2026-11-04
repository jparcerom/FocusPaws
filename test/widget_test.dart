import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_paws/main.dart';

void main() {
  testWidgets('sets up and remembers a personalized profile', (tester) async {
    final profileStore = _MemoryUserProfileStore();
    final progressStore = _MemoryFocusTasksProgressStore();

    await tester.pumpWidget(
      FocusPawsApp(profileStore: profileStore, progressStore: progressStore),
    );
    await tester.pumpAndSettle();

    expect(find.text('FocusPaws'), findsOneWidget);
    expect(find.text('¡Qué bueno tenerte aquí!'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    for (final avatar in UserAvatar.values) {
      expect(find.byKey(Key('profile-avatar-${avatar.id}')), findsOneWidget);
    }

    tester
            .widget<TextField>(find.byKey(const Key('profile-name-field')))
            .controller!
            .text =
        '  Lucía  ';
    await tester.pump();
    expect(find.byKey(const Key('save-profile-button')), findsOneWidget);
    final foxAvatar = find.byKey(const Key('profile-avatar-fox'));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(foxAvatar);
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();

    expect(profileStore.profile?.name, 'Lucía');
    expect(profileStore.profile?.avatar, UserAvatar.fox);
    expect(find.text('¡Hola, Lucía!'), findsOneWidget);
    expect(find.text('🦊'), findsOneWidget);
    expect(find.text('Foxy 🐾'), findsOneWidget);
    expect(find.byKey(const Key('progress-pet-avatar')), findsOneWidget);
    expect(find.byKey(const Key('profile-avatar-display')), findsNothing);

    await tester.pumpWidget(
      FocusPawsApp(profileStore: profileStore, progressStore: progressStore),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Lucía!'), findsOneWidget);
    expect(find.text('Foxy 🐾'), findsOneWidget);
    expect(find.text('¡Qué bueno tenerte aquí!'), findsNothing);
  });

  test('gives each progress animal its own name', () {
    expect(UserAvatar.dog.petName, 'Nori');
    expect(UserAvatar.cat.petName, 'Kitty');
    expect(UserAvatar.fox.petName, 'Foxy');
    expect(UserAvatar.rabbit.petName, 'Bunny');
    expect(UserAvatar.bear.petName, 'Bruno');
  });

  testWidgets('requires a name before saving the profile', (tester) async {
    final profileStore = _MemoryUserProfileStore();

    await tester.pumpWidget(
      FocusPawsApp(
        profileStore: profileStore,
        progressStore: _MemoryFocusTasksProgressStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu nombre para continuar.'), findsOneWidget);
    expect(profileStore.profile, isNull);
  });

  test('increases the points needed as pet levels rise', () {
    final levelTwo = PetProgress.fromTotalPoints(150);
    expect(levelTwo.level, 2);
    expect(levelTwo.pointsInLevel, 0);
    expect(levelTwo.nextLevel, 3);

    final justBeforeLevelThree = PetProgress.fromTotalPoints(299);
    expect(justBeforeLevelThree.level, 2);
    expect(justBeforeLevelThree.pointsInLevel, 149);
    expect(PetProgress.pointsRequiredForLevel(justBeforeLevelThree.level), 150);

    final levelThree = PetProgress.fromTotalPoints(300);
    expect(levelThree.level, 3);
    expect(levelThree.pointsInLevel, 0);
    expect(levelThree.pointsRequired, 180);
    expect(levelThree.progress, 0);

    final levelFour = PetProgress.fromTotalPoints(480);
    expect(levelFour.level, 4);
    expect(levelFour.pointsInLevel, 0);
    expect(levelFour.pointsRequired, 180);

    final levelSix = PetProgress.fromTotalPoints(840);
    expect(levelSix.level, 6);
    expect(levelSix.pointsInLevel, 0);
    expect(levelSix.pointsRequired, 210);

    final halfwayToLevelFour = PetProgress.fromTotalPoints(390);
    expect(halfwayToLevelFour.level, 3);
    expect(halfwayToLevelFour.pointsInLevel, 90);
    expect(halfwayToLevelFour.pointsRequired, 180);
    expect(halfwayToLevelFour.progress, 0.5);
  });

  testWidgets('shows an uncluttered empty home screen', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.text('FocusPaws'), findsOneWidget);
    expect(find.text('¡Hola, Alex!'), findsOneWidget);
    expect(find.text('Kitty 🐾'), findsOneWidget);
    expect(find.text('🐱'), findsOneWidget);
    expect(find.text('Empezamos con calma'), findsOneWidget);
    expect(find.text('Añadir una tarea'), findsOneWidget);
    expect(find.text('0/0 hechas'), findsOneWidget);
    expect(find.text('NIVEL 1'), findsOneWidget);
    expect(find.text('0 / 150 pts'), findsOneWidget);
    expect(find.text('0 pts totales'), findsOneWidget);
    expect(find.text('Progreso hacia nivel 2'), findsOneWidget);
  });

  testWidgets('shows three pending tasks first and keeps the rest accessible', (
    tester,
  ) async {
    final progressStore = _MemoryFocusTasksProgressStore()
      ..progress = FocusTasksProgress(
        tasks: [
          for (var id = 4; id >= 0; id--)
            FocusTaskProgress(
              id: id,
              title: 'Tarea $id',
              isCompleted: false,
              hasReceivedReward: false,
            ),
        ],
        points: 0,
      );

    await tester.pumpWidget(_homeApp(progressStore: progressStore));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('task-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('task-0')), findsNothing);

    final toggleExtraTasks = find.byKey(const Key('toggle-extra-tasks'));
    await _scrollToFinder(tester, toggleExtraTasks);
    expect(find.text('Ver 2 tareas más'), findsOneWidget);
    await tester.tap(toggleExtraTasks);
    await tester.pumpAndSettle();
    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    expect(find.byKey(const ValueKey('task-0')), findsOneWidget);
    await _scrollToFinder(tester, toggleExtraTasks);
    expect(find.text('Mostrar solo las 3 principales'), findsOneWidget);
  });

  testWidgets('restores tasks and earned points after restarting the app', (
    tester,
  ) async {
    final progressStore = _MemoryFocusTasksProgressStore();
    await tester.pumpWidget(_homeApp(progressStore: progressStore));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Preparar el desayuno',
    );
    await tester.ensureVisible(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();
    expect(find.text('15 pts totales'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_homeApp(progressStore: progressStore));
    await tester.pumpAndSettle();

    expect(find.text('Preparar el desayuno'), findsNothing);
    expect(find.text('1/1 hechas'), findsOneWidget);
    expect(find.text('15 pts totales'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-0')), findsNothing);
    final toggleCompleted = find.byKey(const Key('toggle-completed-tasks'));
    await _scrollToFinder(tester, toggleCompleted);
    expect(find.text('Ver completadas (1)'), findsOneWidget);
    await tester.tap(toggleCompleted);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('task-0')), findsOneWidget);
    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('task-0')), findsOneWidget);
    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();
    expect(find.text('15 pts totales'), findsOneWidget);
  });

  test('round-trips persisted task progress and rejects invalid data', () {
    final progress = FocusTasksProgress(
      tasks: const [
        FocusTaskProgress(
          id: 3,
          title: 'Leer',
          isCompleted: true,
          hasReceivedReward: true,
        ),
      ],
      points: 15,
      bonusRestSeconds: 300,
      perseveranceSnacks: 2,
    );

    final restored = FocusTasksProgress.fromJson(progress.toJson());
    expect(restored.points, 15);
    expect(restored.bonusRestSeconds, 300);
    expect(restored.perseveranceSnacks, 2);
    expect(restored.tasks.single.id, 3);
    expect(restored.tasks.single.isCompleted, isTrue);
    expect(restored.tasks.single.hasReceivedReward, isTrue);
    expect(restored.tasks.single.estimatedMinutes, 30);
    expect(
      () => FocusTasksProgress.fromJson('{"points":-1,"tasks":[]}'),
      throwsFormatException,
    );
    final previousVersion = FocusTasksProgress.fromJson(
      '{"points":15,"tasks":[{"id":0,"title":"Anterior",'
      '"isCompleted":false,"hasReceivedReward":false}]}',
    );
    expect(previousVersion.bonusRestSeconds, 0);
    expect(previousVersion.perseveranceSnacks, 0);
    expect(previousVersion.tasks.single.estimatedMinutes, 30);
  });

  testWidgets('adds a task and lets the user mark it complete', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Preparar el desayuno',
    );
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Preparar el desayuno'), findsOneWidget);
    expect(find.text('0/1 hechas'), findsOneWidget);

    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();

    expect(find.text('1/1 hechas'), findsOneWidget);
    expect(find.text('15 / 150 pts'), findsOneWidget);
    expect(find.text('15 pts totales'), findsOneWidget);

    expect(find.byKey(const ValueKey('task-0')), findsNothing);
    final toggleCompleted = find.byKey(const Key('toggle-completed-tasks'));
    await _scrollToFinder(tester, toggleCompleted);
    await tester.tap(toggleCompleted);
    await tester.pumpAndSettle();
    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();
    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();

    expect(find.text('1/1 hechas'), findsOneWidget);
    expect(find.text('15 / 150 pts'), findsOneWidget);
    expect(find.text('15 pts totales'), findsOneWidget);
  });

  testWidgets('saves the selected task size and awards its points', (
    tester,
  ) async {
    final progressStore = _MemoryFocusTasksProgressStore();
    await tester.pumpWidget(_homeApp(progressStore: progressStore));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Hacer la cama',
    );
    await tester.tap(find.byKey(const Key('task-size-short')));
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Paso corto · 15 min · +5 pts'), findsOneWidget);
    expect(progressStore.progress.tasks.single.estimatedMinutes, 15);

    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();
    expect(find.text('5 pts totales'), findsOneWidget);
    expect(progressStore.progress.points, 5);

    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Preparar una presentación',
    );
    await tester.tap(find.byKey(const Key('task-size-long')));
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    expect(find.text('Gran esfuerzo · 45 min · +30 pts'), findsOneWidget);
    expect(progressStore.progress.tasks.first.estimatedMinutes, 45);

    await _scrollToFinder(tester, find.byKey(const ValueKey('task-1')));
    await tester.tap(find.byKey(const ValueKey('task-1')));
    await tester.pumpAndSettle();
    expect(find.text('35 pts totales'), findsOneWidget);
    expect(progressStore.progress.points, 35);
  });

  testWidgets('completes a focus block and grants its reward only once', (
    tester,
  ) async {
    final progressStore = _MemoryFocusTasksProgressStore();
    await tester.pumpWidget(
      _homeApp(
        progressStore: progressStore,
        focusDuration: const Duration(minutes: 20),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Preparar el desayuno',
    );
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    await _scrollToFinder(tester, find.byKey(const Key('start-focus-0')));
    await tester.tap(find.byKey(const Key('start-focus-0')));
    await tester.pumpAndSettle();
    expect(find.text('Modo foco'), findsOneWidget);
    expect(find.text('Preparar el desayuno'), findsOneWidget);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byKey(const Key('focus-timer-progress')),
          )
          .value,
      1,
    );

    await tester.pump(const Duration(minutes: 11));
    await tester.tap(find.byKey(const Key('focus-finish-early-button')));
    await tester.pumpAndSettle();
    expect(find.text('¡Conseguido!'), findsOneWidget);
    expect(
      find.text('¡Guau! Tu cerebro ha volado hoy. Kitty celebra tu rapidez.'),
      findsOneWidget,
    );
    expect(
      find.text('Tiempo de Bonificación para Descanso: +7 min'),
      findsOneWidget,
    );
    expect(find.text('+15 puntos de energía para tu mascota'), findsOneWidget);
    await tester.tap(find.byKey(const Key('focus-reward-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('1/1 hechas'), findsOneWidget);
    expect(find.text('15 pts totales'), findsOneWidget);
    expect(find.text('Descanso +7 min'), findsOneWidget);
    expect(progressStore.progress.bonusRestSeconds, 420);
    expect(find.byKey(const ValueKey('task-0')), findsNothing);

    final toggleCompleted = find.byKey(const Key('toggle-completed-tasks'));
    await _scrollToFinder(tester, toggleCompleted);
    expect(find.text('Ver completadas (1)'), findsOneWidget);
    await tester.tap(toggleCompleted);
    await tester.pumpAndSettle();
    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('task-0')), findsOneWidget);
    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();
    expect(find.text('1/1 hechas'), findsOneWidget);
    expect(find.text('15 pts totales'), findsOneWidget);
  });

  testWidgets('very early completion keeps the standard rest only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _homeApp(focusDuration: const Duration(minutes: 10)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Guardar el documento',
    );
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-focus-0')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 4));
    await tester.tap(find.byKey(const Key('focus-finish-early-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('focus-standard-rest-message')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('focus-bonus-rest-reward')), findsNothing);
    expect(
      find.text(
        '¡Vaya, qué rápido! Kitty celebra que hayas terminado. Esta vez tu '
        'descanso será el estándar, sin minutos extra.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'offers overtime and rewards a snack after more than ten minutes',
    (tester) async {
      final progressStore = _MemoryFocusTasksProgressStore();
      await tester.pumpWidget(
        _homeApp(
          progressStore: progressStore,
          focusDuration: const Duration(seconds: 2),
          overtimeBlockDuration: const Duration(seconds: 1),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir una tarea'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Terminar el informe',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-focus-0')));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Sigue a tu ritmo'), findsOneWidget);
      expect(find.byKey(const Key('focus-timer-progress')), findsNothing);
      expect(
        find.byKey(const Key('focus-overtime-five-more-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('focus-overtime-free-mode-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('focus-overtime-five-more-button')),
      );
      await tester.pump();
      expect(find.byKey(const Key('focus-timer-progress')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Sigue a tu ritmo'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('focus-overtime-free-mode-button')),
      );
      await tester.pump();
      expect(find.byKey(const Key('focus-timer-progress')), findsNothing);
      await tester.pump(const Duration(minutes: 9, seconds: 59));
      expect(find.byKey(const Key('focus-overtime-elapsed')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('focus-overtime-elapsed')))
            .data,
        'Tiempo extra · 10 min',
      );
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester
            .widget<Text>(find.byKey(const Key('focus-overtime-elapsed')))
            .data,
        'Tiempo extra · 10 min 2 s',
      );
      await tester.tap(find.byKey(const Key('focus-finish-task-button')));
      await tester.pumpAndSettle();

      expect(find.text('¡Conseguido!'), findsOneWidget);
      expect(
        find.byKey(const Key('focus-overtime-total-reward')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('focus-overtime-total-reward')))
            .data,
        'Tiempo extra realizado: 10 min 2 s',
      );
      expect(
        find.byKey(const Key('focus-perseverance-snack-reward')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('focus-reward-continue-button')));
      await tester.pumpAndSettle();
      expect(find.text('15 pts totales'), findsOneWidget);
      expect(find.text('🍪 1'), findsOneWidget);
      expect(progressStore.progress.perseveranceSnacks, 1);
      expect(progressStore.progress.tasks.single.isCompleted, isTrue);
    },
  );

  testWidgets('micro-pause resumes focus and pause stops the countdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FocusSessionPage(
          taskTitle: 'Estudiar',
          avatar: UserAvatar.dog,
          focusDuration: const Duration(seconds: 8),
          microPauseDuration: const Duration(seconds: 2),
          onRewardContinue: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('focus-micro-pause-button')));
    await tester.pump();
    expect(find.text('Tómate un respiro'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('focus-pause-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('focus-pause-button')));
    await tester.pump();
    final pausedProgress = tester
        .widget<CircularProgressIndicator>(
          find.byKey(const Key('focus-timer-progress')),
        )
        .value;
    await tester.pump(const Duration(seconds: 5));
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byKey(const Key('focus-timer-progress')),
          )
          .value,
      pausedProgress,
    );
    await tester.tap(find.byKey(const Key('focus-resume-button')));
    await tester.pump();
    expect(find.byKey(const Key('focus-pause-button')), findsOneWidget);
  });

  testWidgets('requires confirmation before abandoning focus', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Leer un capítulo',
    );
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('start-focus-0')));
    await tester.pumpAndSettle();
    await _scrollToFinder(
      tester,
      find.byKey(const Key('focus-abandon-button')),
    );
    await tester.tap(find.byKey(const Key('focus-abandon-button')));
    await tester.pumpAndSettle();
    expect(find.text('¿Quieres abandonar el foco?'), findsOneWidget);
    await tester.tap(find.text('Seguir enfocándome'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focus-pause-button')), findsOneWidget);

    await _scrollToFinder(
      tester,
      find.byKey(const Key('focus-abandon-button')),
    );
    await tester.tap(find.byKey(const Key('focus-abandon-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandonar'));
    await tester.pumpAndSettle();
    expect(find.text('0/1 hechas'), findsOneWidget);
    expect(find.text('Leer un capítulo'), findsOneWidget);
  });

  testWidgets('advances the pet level without losing lifetime points', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    for (var index = 0; index < 21; index++) {
      await tester.tap(find.text('Añadir una tarea'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Tarea ${index + 1}',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      final taskFinder = find.byKey(ValueKey('task-$index'));
      await tester.ensureVisible(taskFinder);
      await tester.tap(taskFinder);
      if (index == 9 || index == 19) {
        await tester.drag(find.byType(ListView), const Offset(0, 3000));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 225));
        final avatar = tester.widget<Transform>(
          find.byKey(const Key('pet-level-up-animation')),
        );
        expect(avatar.transform.getMaxScaleOnAxis(), greaterThan(1));
        expect(find.byKey(const Key('pet-level-up-sparkle')), findsOneWidget);
        await tester.pumpAndSettle();
      } else {
        await tester.pumpAndSettle();
      }

      if (index == 9 || index == 19) {
        await tester.drag(find.byType(ListView), const Offset(0, 3000));
        await tester.pumpAndSettle();
        final level = index == 9 ? 2 : 3;
        final nextLevelPoints = index == 9 ? 150 : 180;
        final totalPoints = index == 9 ? 150 : 300;
        expect(find.text('NIVEL $level'), findsOneWidget);
        expect(find.text('Progreso hacia nivel ${level + 1}'), findsOneWidget);
        expect(find.text('0 / $nextLevelPoints pts'), findsOneWidget);
        expect(find.text('$totalPoints pts totales'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byKey(const Key('pet-level-progress')),
              )
              .value,
          0,
        );
        expect(find.text('$level'), findsOneWidget);
      }
    }

    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('21/21 hechas'), findsOneWidget);
    expect(find.text('NIVEL 3'), findsOneWidget);
    expect(find.text('15 / 180 pts'), findsOneWidget);
    expect(find.text('315 pts totales'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('pet-level-progress')),
          )
          .value,
      closeTo(15 / 180, 0.001),
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('does not save a blank task', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Escribe una tarea para poder guardarla.'),
      findsOneWidget,
    );
    expect(find.text('0/0 hechas'), findsOneWidget);
  });

  testWidgets('transcribes Spanish speech and saves the task', (tester) async {
    final speechRecognizer = _FakeTaskSpeechRecognizer();
    FocusTaskDraft? savedTask;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                savedTask = await showModalBottomSheet<FocusTaskDraft>(
                  context: context,
                  builder: (context) =>
                      AddTaskSheet(speechRecognizer: speechRecognizer),
                );
              },
              child: const Text('Abrir captura'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir captura'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Preparar',
    );
    await tester.tap(find.byKey(const Key('voice-input-button')));
    await tester.pumpAndSettle();

    expect(speechRecognizer.startedLocale, 'es-ES');
    expect(find.text('Escuchando... Habla con naturalidad.'), findsOneWidget);

    speechRecognizer.sendResult('el desayuno');
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('task-title-field')))
          .controller!
          .text,
      'Preparar el desayuno',
    );

    await tester.ensureVisible(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    expect(savedTask?.title, 'Preparar el desayuno');
    expect(savedTask?.size, FocusTaskSize.standard);
  });

  testWidgets('keeps typed task entry available when voice is unavailable', (
    tester,
  ) async {
    final speechRecognizer = _FakeTaskSpeechRecognizer(isAvailable: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (context) =>
                    AddTaskSheet(speechRecognizer: speechRecognizer),
              ),
              child: const Text('Abrir captura'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir captura'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voice-input-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No se pudo acceder al micrófono o al reconocimiento de voz. '
        'Revisa el permiso del micrófono o escribe la tarea.',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Llamar a la clínica',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('task-title-field')))
          .controller!
          .text,
      'Llamar a la clínica',
    );
  });
}

Widget _homeApp({
  Duration focusDuration = const Duration(minutes: 25),
  Duration overtimeBlockDuration = const Duration(minutes: 5),
  FocusTasksProgressStore? progressStore,
}) => FocusPawsApp(
  profileStore: _MemoryUserProfileStore(
    profile: const UserProfile(name: 'Alex', avatar: UserAvatar.cat),
  ),
  progressStore: progressStore ?? _MemoryFocusTasksProgressStore(),
  focusDuration: focusDuration,
  overtimeBlockDuration: overtimeBlockDuration,
);

Future<void> _scrollToFinder(WidgetTester tester, Finder finder) async {
  final screenHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  for (var attempt = 0; attempt < 10; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      final rect = tester.getRect(finder);
      if (rect.top >= 0 && rect.bottom <= screenHeight - 100) return;
    }

    final delta =
        finder.evaluate().isEmpty ||
            tester.getRect(finder).bottom > screenHeight - 100
        ? const Offset(0, -300)
        : const Offset(0, 300);
    await tester.drag(find.byType(ListView), delta);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
}

class _MemoryUserProfileStore implements UserProfileStore {
  _MemoryUserProfileStore({this.profile});

  UserProfile? profile;

  @override
  Future<UserProfile?> loadProfile() async => profile;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    this.profile = profile;
  }
}

class _MemoryFocusTasksProgressStore implements FocusTasksProgressStore {
  FocusTasksProgress progress = FocusTasksProgress.empty;

  @override
  Future<FocusTasksProgress> loadProgress() async => progress;

  @override
  Future<void> saveProgress(FocusTasksProgress progress) async {
    this.progress = FocusTasksProgress(
      tasks: progress.tasks
          .map(
            (task) => FocusTaskProgress(
              id: task.id,
              title: task.title,
              isCompleted: task.isCompleted,
              hasReceivedReward: task.hasReceivedReward,
              estimatedMinutes: task.estimatedMinutes,
            ),
          )
          .toList(),
      points: progress.points,
      bonusRestSeconds: progress.bonusRestSeconds,
      perseveranceSnacks: progress.perseveranceSnacks,
    );
  }
}

class _FakeTaskSpeechRecognizer implements TaskSpeechRecognizer {
  _FakeTaskSpeechRecognizer({this.isAvailable = true});

  final bool isAvailable;
  late ValueChanged<String> _onResult;
  String? startedLocale;

  @override
  Future<bool> initialize({
    required ValueChanged<String> onStatus,
    required ValueChanged<String> onError,
  }) async {
    return isAvailable;
  }

  @override
  Future<String?> spanishLocaleId() async => 'es-ES';

  @override
  Future<void> listen({
    required String localeId,
    required ValueChanged<String> onResult,
  }) async {
    startedLocale = localeId;
    _onResult = onResult;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  void sendResult(String words) => _onResult(words);
}
