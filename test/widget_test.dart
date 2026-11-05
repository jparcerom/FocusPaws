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
    final welcomeLogo = tester.widget<Image>(
      find.byKey(const Key('profile-welcome-logo')),
    );
    expect(
      (welcomeLogo.image as AssetImage).assetName,
      'assets/images/focuspaws_logo_circular.png',
    );
    expect(find.byIcon(Icons.pets_rounded), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(UserAvatar.values, hasLength(6));
    for (final avatar in UserAvatar.values) {
      expect(find.byKey(Key('profile-avatar-${avatar.id}')), findsOneWidget);
    }
    expect(find.byKey(const Key('profile-avatar-panda')), findsOneWidget);

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
    expect(
      tester.widget<Text>(find.byKey(const Key('progress-pet-avatar'))).data,
      '🦊',
    );
    expect(find.text('Soy Foxy 🐾'), findsOneWidget);
    expect(find.byKey(const Key('progress-pet-avatar')), findsOneWidget);
    expect(find.byKey(const Key('profile-avatar-display')), findsNothing);

    await tester.pumpWidget(
      FocusPawsApp(
        key: const ValueKey('restarted-app'),
        profileStore: profileStore,
        progressStore: progressStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('select-profile-default')), findsOneWidget);
    await tester.tap(find.byKey(const Key('select-profile-default')));
    await tester.pumpAndSettle();
    expect(find.text('Tu espacio, Lucía'), findsOneWidget);
    await tester.tap(find.byKey(const Key('enter-tasks-button')));
    await tester.pumpAndSettle();
    expect(find.text('¡Hola, Lucía!'), findsOneWidget);
    expect(find.text('Soy Foxy 🐾'), findsOneWidget);
    expect(find.text('¡Qué bueno tenerte aquí!'), findsNothing);
  });

  test('gives each progress animal its own name', () {
    expect(UserAvatar.dog.petName, 'Nori');
    expect(UserAvatar.cat.petName, 'Kitty');
    expect(UserAvatar.fox.petName, 'Foxy');
    expect(UserAvatar.rabbit.petName, 'Bunny');
    expect(UserAvatar.bear.petName, 'Bruno');
    expect(UserAvatar.panda.petName, 'Panda');
    expect(UserAvatar.panda.emoji, '🐼');
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

  testWidgets('edits the selected profile without losing its task progress', (
    tester,
  ) async {
    final profileStore = _MemoryUserProfileStore(
      profile: const UserProfile(name: 'Alex', avatar: UserAvatar.cat),
    );
    final progressStore = _MemoryFocusTasksProgressStore()
      ..progress = FocusTasksProgress(
        tasks: [
          const FocusTaskProgress(
            id: 4,
            title: 'Tarea persistente',
            isCompleted: false,
            hasReceivedReward: false,
          ),
        ],
        points: 0,
      );

    await tester.pumpWidget(
      FocusPawsApp(profileStore: profileStore, progressStore: progressStore),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-profile-default')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-name-option')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-name-field')),
      'Lucía',
    );
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tu espacio, Lucía'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-avatar-option')));
    await tester.pumpAndSettle();
    await _scrollToFinder(tester, find.byKey(const Key('profile-avatar-fox')));
    await tester.tap(find.byKey(const Key('profile-avatar-fox')));
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();
    expect(find.text('🦊'), findsOneWidget);

    await tester.tap(find.byKey(const Key('enter-tasks-button')));
    await tester.pumpAndSettle();
    expect(find.text('¡Hola, Lucía!'), findsOneWidget);
    expect(find.text('Tarea persistente'), findsOneWidget);
    expect(progressStore.progress.points, 0);
  });

  testWidgets('keeps task progress separate between user profiles', (
    tester,
  ) async {
    final profileStore = _MemoryUserProfileStore(
      profile: const UserProfile(name: 'Alex', avatar: UserAvatar.cat),
    );
    final progressStore = _MemoryFocusTasksProgressStore();
    await tester.pumpWidget(
      FocusPawsApp(profileStore: profileStore, progressStore: progressStore),
    );
    await tester.pumpAndSettle();

    final createProfileButton = find.byKey(const Key('create-profile-button'));
    expect(createProfileButton, findsOneWidget);
    final button = tester.widget<FilledButton>(createProfileButton);
    expect(button.style?.backgroundColor?.resolve({}), const Color(0xFF006B70));
    expect(button.style?.foregroundColor?.resolve({}), Colors.white);
    await tester.tap(createProfileButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile-name-field')), 'Bea');
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();
    expect(find.text('Tu espacio, Bea'), findsOneWidget);
    await tester.tap(find.byKey(const Key('enter-tasks-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Tarea de Bea',
    );
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finish-day-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('select-profile-default')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enter-tasks-button')));
    await tester.pumpAndSettle();
    expect(find.text('Tarea de Bea'), findsNothing);
    expect(find.text('0/0 tareas hechas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('finish-day-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-profile-user-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enter-tasks-button')));
    await tester.pumpAndSettle();
    expect(find.text('Tarea de Bea'), findsOneWidget);
  });

  testWidgets('hides additional profiles in the free-profile view', (
    tester,
  ) async {
    final profileStore =
        _MemoryUserProfileStore(
            profile: const UserProfile(name: 'Alex', avatar: UserAvatar.cat),
          )
          ..profiles.add(
            const UserProfile(
              id: 'user-2',
              name: 'Bea',
              avatar: UserAvatar.dog,
            ),
          );

    await tester.pumpWidget(
      FocusPawsApp(
        profileStore: profileStore,
        progressStore: _MemoryFocusTasksProgressStore(),
        allowMultipleProfiles: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('select-profile-default')), findsOneWidget);
    expect(find.byKey(const Key('select-profile-user-2')), findsNothing);
    expect(find.byKey(const Key('create-profile-button')), findsNothing);
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
    await tester.pumpWidget(_homeApp(clock: () => DateTime(2026, 11, 5, 12)));
    await tester.pumpAndSettle();

    expect(find.text('FocusPaws'), findsOneWidget);
    expect(find.byKey(const Key('brand-logo')), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byKey(const Key('brand-logo'))))
          .scaffoldBackgroundColor,
      const Color(0xFFFFF3D6),
    );
    expect(find.byKey(const Key('open-user-profile')), findsNothing);
    expect(find.byKey(const Key('finish-day-button')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('finish-day-button')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(
      tester.getRect(find.byKey(const Key('finish-day-button'))).center.dy,
      closeTo(tester.getRect(find.text('FocusPaws')).center.dy, 1),
    );
    expect(
      tester.getRect(find.byKey(const Key('finish-day-button'))).right,
      greaterThan(tester.getRect(find.text('FocusPaws')).right),
    );
    expect(find.text('¡Hola, Alex!'), findsOneWidget);
    expect(find.text('Hoy es jueves'), findsOneWidget);
    expect(find.text('Soy Kitty 🐾'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('progress-pet-avatar'))).data,
      '🐱',
    );
    expect(find.text('Empezamos con calma'), findsOneWidget);
    expect(find.text('Añadir una tarea'), findsOneWidget);
    expect(find.text('0/0 tareas hechas'), findsOneWidget);
    expect(find.text('NIVEL 1'), findsOneWidget);
    expect(find.text('0 / 150 pts'), findsOneWidget);
    expect(find.byKey(const Key('pet-total-points')), findsNothing);
    expect(find.text('TU COMPAÑERO DE HOY'), findsNothing);
    expect(find.text('Tu reto del día'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('finish-day-button'))),
      isA<FilledButton>(),
    );
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

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_homeApp(progressStore: progressStore));
    await tester.pumpAndSettle();

    expect(find.text('Preparar el desayuno'), findsNothing);
    expect(find.text('1/1 tareas hechas'), findsOneWidget);
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
      dailyCompletions: {
        '2026-11-04': [3, 5, 8],
        '2026-11-03': [2, 4],
      },
      lastActiveDate: '2026-11-04',
      activeRestEndTimeMillis: DateTime(
        2026,
        11,
        4,
        12,
        5,
      ).millisecondsSinceEpoch,
      petMoodMinutes: 9,
      petPatCount: 9,
    );

    final restored = FocusTasksProgress.fromJson(progress.toJson());
    expect(restored.points, 15);
    expect(restored.bonusRestSeconds, 300);
    expect(restored.perseveranceSnacks, 2);
    expect(restored.tasks.single.id, 3);
    expect(restored.tasks.single.isCompleted, isTrue);
    expect(restored.tasks.single.hasReceivedReward, isTrue);
    expect(restored.tasks.single.estimatedMinutes, 30);
    expect(restored.dailyCompletions['2026-11-04'], [3, 5, 8]);
    expect(restored.lastActiveDate, '2026-11-04');
    expect(restored.pendingCarryoverTaskIds, isEmpty);
    expect(
      restored.activeRestEndTimeMillis,
      DateTime(2026, 11, 4, 12, 5).millisecondsSinceEpoch,
    );
    expect(restored.petMoodMinutes, 9);
    expect(restored.petPatCount, 9);
    expect(restored.stickerUnlockDates, ['2026-11-04']);
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
    expect(previousVersion.dailyCompletions, isEmpty);
    expect(previousVersion.lastActiveDate, isNull);
    expect(previousVersion.pendingCarryoverTaskIds, isEmpty);
    expect(previousVersion.activeRestEndTimeMillis, isNull);
    expect(previousVersion.petMoodMinutes, 0);
    expect(previousVersion.petPatCount, 0);
    expect(
      () => FocusTasksProgress.fromJson(
        '{"points":0,"petMoodMinutes":-1,"tasks":[]}',
      ),
      throwsFormatException,
    );
    expect(
      () => FocusTasksProgress.fromJson(
        '{"points":0,"petPatCount":-1,"tasks":[]}',
      ),
      throwsFormatException,
    );
  });

  testWidgets('resumes an active rest timer after reopening the app', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 5, 12);
    final progressStore = _MemoryFocusTasksProgressStore()
      ..progress = FocusTasksProgress(
        tasks: const [],
        points: 0,
        lastActiveDate: '2026-11-05',
        activeRestEndTimeMillis: now
            .add(const Duration(seconds: 90))
            .millisecondsSinceEpoch,
      );

    await tester.pumpWidget(
      _homeApp(progressStore: progressStore, clock: () => now),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActiveRestBreakPage), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
  });

  testWidgets('accumulates remaining rest time when ending early', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 5, 12);
    final progressStore = _MemoryFocusTasksProgressStore()
      ..progress = FocusTasksProgress(
        tasks: const [],
        points: 0,
        bonusRestSeconds: 30,
        lastActiveDate: '2026-11-05',
        activeRestEndTimeMillis: now
            .add(const Duration(seconds: 90))
            .millisecondsSinceEpoch,
      );
    final notificationService = _MemoryRestBreakNotificationService();

    await tester.pumpWidget(
      _homeApp(
        progressStore: progressStore,
        clock: () => now,
        restBreakNotificationService: notificationService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActiveRestBreakPage), findsOneWidget);
    final finishButton = find.byKey(const Key('rest-finish-early-button'));
    await _scrollToFinder(tester, finishButton);
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    expect(find.byType(ActiveRestBreakPage), findsNothing);
    expect(progressStore.progress.activeRestEndTimeMillis, isNull);
    expect(progressStore.progress.bonusRestSeconds, 120);
    expect(notificationService.cancelledTimers, 1);
  });

  testWidgets('spends accumulated rest time in the active-rest flow', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 5, 12);
    final progressStore = _MemoryFocusTasksProgressStore()
      ..progress = FocusTasksProgress(
        tasks: const [
          FocusTaskProgress(
            id: 8,
            title: 'Ordenar el escritorio',
            isCompleted: false,
            hasReceivedReward: false,
          ),
        ],
        points: 0,
        bonusRestSeconds: 180,
      );
    final notificationService = _MemoryRestBreakNotificationService();

    await tester.pumpWidget(
      _homeApp(
        progressStore: progressStore,
        clock: () => now,
        restBreakNotificationService: notificationService,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-8')));
    await tester.pumpAndSettle();

    expect(find.byType(ActiveRestBreakPage), findsOneWidget);
    expect(find.text('03:00'), findsOneWidget);
    expect(progressStore.progress.bonusRestSeconds, 0);
    expect(
      progressStore.progress.activeRestEndTimeMillis,
      now.add(const Duration(minutes: 3)).millisecondsSinceEpoch,
    );

    final petActivity = find.byKey(const Key('rest-activity-pet'));
    await _scrollToFinder(tester, petActivity);
    await tester.tap(petActivity);
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Minutos felices: 1'), findsOneWidget);
    expect(progressStore.progress.petMoodMinutes, 1);

    final petInteractButton = find.byKey(const Key('rest-pet-interact-button'));
    await _scrollToFinder(tester, petInteractButton);
    for (var pat = 0; pat < 10; pat++) {
      await tester.tap(petInteractButton);
      await tester.pump();
    }
    expect(find.text('Caricias: 10'), findsOneWidget);
    expect(find.text('+2 puntos'), findsOneWidget);
    expect(progressStore.progress.petPatCount, 10);
    expect(progressStore.progress.points, 22);

    final freeActivity = find.byKey(const Key('rest-activity-free'));
    await _scrollToFinder(tester, freeActivity);
    await tester.tap(freeActivity);
    await tester.pumpAndSettle();
    expect(notificationService.shownTimers, 1);
    expect(
      find.text(
        'Al terminar, recibirás una notificación para volver a tus tareas.',
      ),
      findsOneWidget,
    );
    final physicalActivity = find.byKey(const Key('rest-activity-physical'));
    await _scrollToFinder(tester, physicalActivity);
    await tester.tap(physicalActivity);
    await tester.pumpAndSettle();
    expect(notificationService.cancelledTimers, 1);
  });

  testWidgets('keeps free rest mode active when notifications fail', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 5, 12);
    final progressStore = _MemoryFocusTasksProgressStore()
      ..progress = FocusTasksProgress(
        tasks: const [],
        points: 0,
        activeRestEndTimeMillis: now
            .add(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
      );
    final notificationService = _MemoryRestBreakNotificationService()
      ..showTimerException = Exception('PlatformException(test failure)');

    await tester.pumpWidget(
      _homeApp(
        progressStore: progressStore,
        clock: () => now,
        restBreakNotificationService: notificationService,
      ),
    );
    await tester.pumpAndSettle();

    final freeActivity = find.byKey(const Key('rest-activity-free'));
    await _scrollToFinder(tester, freeActivity);
    await tester.tap(freeActivity);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Puedes usar el móvil o hacer otra actividad. El temporizador '
        'sigue activo.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Modo libre activo, pero no se pudo programar la notificación:',
      ),
      findsOneWidget,
    );
  });

  testWidgets('persists daily sticker unlocks and resets the daily counter', (
    tester,
  ) async {
    var today = DateTime(2026, 11, 4, 12);
    final progressStore = _MemoryFocusTasksProgressStore()
      ..progress = FocusTasksProgress(
        tasks: [
          for (var id = 0; id < 3; id++)
            FocusTaskProgress(
              id: id,
              title: 'Tarea $id',
              isCompleted: false,
              hasReceivedReward: false,
            ),
        ],
        points: 0,
      );

    await tester.pumpWidget(
      _homeApp(progressStore: progressStore, clock: () => today),
    );
    await tester.pumpAndSettle();
    await _scrollToFinder(
      tester,
      find.byKey(const Key('open-sticker-album-button')),
    );
    expect(find.text('0 de 3 tareas para la pegatina de hoy'), findsOneWidget);

    for (var id = 0; id < 3; id++) {
      final task = find.byKey(ValueKey('task-$id'));
      await _scrollToFinder(tester, task);
      await tester.tap(task);
      await tester.pumpAndSettle();
    }

    await _scrollToFinder(
      tester,
      find.byKey(const Key('open-sticker-album-button')),
    );
    expect(find.text('¡Pegatina de hoy desbloqueada!'), findsOneWidget);
    expect(find.text('1 pegatina en tu colección'), findsOneWidget);
    expect(progressStore.progress.dailyCompletions['2026-11-04'], [0, 1, 2]);
    expect(progressStore.progress.stickerUnlockDates, ['2026-11-04']);

    await tester.tap(find.byKey(const Key('open-sticker-album-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sticker-album-grid')), findsOneWidget);
    expect(find.byKey(const Key('sticker-2026-11-04')), findsOneWidget);
    expect(find.text('04/11/2026'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    today = DateTime(2026, 11, 5, 9);
    await tester.pumpWidget(
      _homeApp(progressStore: progressStore, clock: () => today),
    );
    await tester.pumpAndSettle();
    await _scrollToFinder(
      tester,
      find.byKey(const Key('open-sticker-album-button')),
    );
    expect(find.text('0 de 3 tareas para la pegatina de hoy'), findsOneWidget);
    expect(find.text('1 pegatina en tu colección'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-sticker-album-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sticker-2026-11-04')), findsOneWidget);
  });

  testWidgets(
    'starts a new day with pending tasks and asks how to handle them',
    (tester) async {
      final today = DateTime(2026, 11, 5, 12);
      final progressStore = _MemoryFocusTasksProgressStore()
        ..progress = FocusTasksProgress(
          tasks: const [
            FocusTaskProgress(
              id: 0,
              title: 'Tarea completada ayer',
              isCompleted: true,
              hasReceivedReward: true,
            ),
            FocusTaskProgress(
              id: 1,
              title: 'Tarea pendiente',
              isCompleted: false,
              hasReceivedReward: false,
            ),
          ],
          points: 20,
          dailyCompletions: {
            '2026-11-04': [0],
          },
        );

      await tester.pumpWidget(
        _homeApp(progressStore: progressStore, clock: () => today),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tarea pendiente de ayer'), findsOneWidget);
      expect(
        find.textContaining(
          '¿Quieres conservarla para terminarla hoy o cancelarla?',
        ),
        findsOneWidget,
      );
      expect(find.text('0/1 tareas hechas'), findsOneWidget);
      expect(find.text('Tarea completada ayer'), findsNothing);
      expect(find.text('¡Misión cumplida por hoy!'), findsNothing);

      await tester.tap(find.text('Conservar tarea'));
      await tester.pumpAndSettle();
      expect(find.text('Tarea pendiente'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('task-1')));
      await tester.pumpAndSettle();
      expect(find.text('1/1 tareas hechas'), findsOneWidget);
      expect(find.text('¡Misión cumplida por hoy!'), findsOneWidget);
      expect(progressStore.progress.dailyCompletions['2026-11-04'], [0]);
      expect(progressStore.progress.dailyCompletions['2026-11-05'], [1]);
    },
  );

  testWidgets('can cancel a pending task carried over from yesterday', (
    tester,
  ) async {
    final progressStore = _MemoryFocusTasksProgressStore()
      ..progress = FocusTasksProgress(
        tasks: const [
          FocusTaskProgress(
            id: 1,
            title: 'Tarea que ya no hace falta',
            isCompleted: false,
            hasReceivedReward: false,
          ),
        ],
        points: 0,
        lastActiveDate: '2026-11-04',
      );

    await tester.pumpWidget(
      _homeApp(
        progressStore: progressStore,
        clock: () => DateTime(2026, 11, 5, 12),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar tarea'));
    await tester.pumpAndSettle();

    expect(find.text('Tarea que ya no hace falta'), findsNothing);
    expect(find.text('0/0 tareas hechas'), findsOneWidget);
    expect(find.text('¡Misión cumplida por hoy!'), findsNothing);
    expect(progressStore.progress.tasks, isEmpty);
  });

  testWidgets('resets completed tasks at midnight without restarting', (
    tester,
  ) async {
    var today = DateTime(2026, 11, 4, 23, 59);
    final progressStore = _MemoryFocusTasksProgressStore();
    await tester.pumpWidget(
      _homeApp(progressStore: progressStore, clock: () => today),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Tarea de ayer',
    );
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();
    expect(find.text('1/1 tareas hechas'), findsOneWidget);

    today = DateTime(2026, 11, 5, 0, 1);
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();

    expect(find.text('0/0 tareas hechas'), findsOneWidget);
    expect(find.text('Tarea de ayer'), findsNothing);
    expect(find.text('¡Misión cumplida por hoy!'), findsNothing);
    expect(progressStore.progress.dailyCompletions['2026-11-04'], [0]);
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
    expect(find.text('0/1 tareas hechas'), findsOneWidget);

    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();

    expect(find.text('1/1 tareas hechas'), findsOneWidget);
    expect(find.text('20 / 150 pts'), findsOneWidget);
    expect(find.text('¡Misión cumplida por hoy!'), findsOneWidget);

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

    expect(find.text('1/1 tareas hechas'), findsOneWidget);
    expect(find.text('20 / 150 pts'), findsOneWidget);
  });

  testWidgets('saves the selected task size and awards its points', (
    tester,
  ) async {
    final progressStore = _MemoryFocusTasksProgressStore();
    await tester.pumpWidget(_homeApp(progressStore: progressStore));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    for (final entry in {
      'short': 'Corto',
      'standard': 'Medio',
      'long': 'Largo',
    }.entries) {
      final button = find.byKey(Key('task-size-${entry.key}'));
      expect(
        find.descendant(of: button, matching: find.text(entry.value)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: button, matching: find.textContaining('min')),
        findsNothing,
      );
      expect(
        find.descendant(of: button, matching: find.textContaining('pts')),
        findsNothing,
      );
    }
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Hacer la cama',
    );
    await tester.tap(find.byKey(const Key('task-size-short')));
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Paso corto · 15 min · +10 pts'), findsOneWidget);
    expect(progressStore.progress.tasks.single.estimatedMinutes, 15);

    await _scrollToFinder(tester, find.byKey(const ValueKey('task-0')));
    await tester.tap(find.byKey(const ValueKey('task-0')));
    await tester.pumpAndSettle();
    expect(find.text('10 / 150 pts'), findsOneWidget);
    expect(progressStore.progress.points, 10);

    await tester.tap(find.text('Añadir una tarea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Preparar una presentación',
    );
    await tester.tap(find.byKey(const Key('task-size-long')));
    await tester.tap(find.byKey(const Key('save-task-button')));
    await tester.pumpAndSettle();
    expect(find.text('Gran esfuerzo · 45 min · +40 pts'), findsOneWidget);
    expect(progressStore.progress.tasks.first.estimatedMinutes, 45);

    await _scrollToFinder(tester, find.byKey(const ValueKey('task-1')));
    await tester.tap(find.byKey(const ValueKey('task-1')));
    await tester.pumpAndSettle();
    expect(find.text('50 / 150 pts'), findsOneWidget);
    expect(progressStore.progress.points, 50);
  });

  testWidgets('completes a focus block and grants its reward only once', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 5, 12);
    final progressStore = _MemoryFocusTasksProgressStore();
    final notificationService = _MemoryRestBreakNotificationService();
    await tester.pumpWidget(
      _homeApp(
        progressStore: progressStore,
        focusDuration: const Duration(minutes: 20),
        clock: () => now,
        restBreakNotificationService: notificationService,
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
    expect(find.text('+20 puntos de energía para tu mascota'), findsOneWidget);
    await tester.tap(find.byKey(const Key('focus-reward-continue-button')));
    await tester.pumpAndSettle();

    expect(find.byType(ActiveRestBreakPage), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(progressStore.progress.activeRestEndTimeMillis, isNotNull);
    expect(progressStore.progress.bonusRestSeconds, 0);
    now = now.add(const Duration(minutes: 7));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('¡Descanso terminado!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rest-finished-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('1/1 tareas hechas'), findsOneWidget);
    expect(progressStore.progress.bonusRestSeconds, 0);
    expect(progressStore.progress.activeRestEndTimeMillis, isNull);
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
    expect(find.text('1/1 tareas hechas'), findsOneWidget);
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
    await _scrollToFinder(tester, find.byKey(const Key('start-focus-0')));
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
      await _scrollToFinder(tester, find.byKey(const Key('start-focus-0')));
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

    await _scrollToFinder(tester, find.byKey(const Key('start-focus-0')));
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
    expect(find.text('0/1 tareas hechas'), findsOneWidget);
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
      await _scrollToFinder(tester, taskFinder);
      await tester.tap(taskFinder);
      if (index == 7 || index == 14) {
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

      if (index == 7 || index == 14) {
        await tester.drag(find.byType(ListView), const Offset(0, 3000));
        await tester.pumpAndSettle();
        final level = index == 7 ? 2 : 3;
        final nextLevelPoints = index == 7 ? 150 : 180;
        final pointsInLevel = index == 7 ? 10 : 0;
        expect(find.text('NIVEL $level'), findsOneWidget);
        expect(find.text('Progreso hacia nivel ${level + 1}'), findsOneWidget);
        expect(
          find.text('$pointsInLevel / $nextLevelPoints pts'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byKey(const Key('pet-level-progress')),
              )
              .value,
          closeTo(pointsInLevel / nextLevelPoints, 0.001),
        );
        expect(find.text('$level'), findsOneWidget);
      }
    }

    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('21/21 tareas hechas'), findsOneWidget);
    expect(find.text('NIVEL 3'), findsOneWidget);
    expect(find.text('120 / 180 pts'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('pet-level-progress')),
          )
          .value,
      closeTo(120 / 180, 0.001),
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
    expect(find.text('0/0 tareas hechas'), findsOneWidget);
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
  RestBreakNotificationService? restBreakNotificationService,
  DateTime Function()? clock,
}) => FocusPawsApp(
  profileStore: _MemoryUserProfileStore(
    profile: const UserProfile(name: 'Alex', avatar: UserAvatar.cat),
  ),
  progressStore: progressStore ?? _MemoryFocusTasksProgressStore(),
  focusDuration: focusDuration,
  overtimeBlockDuration: overtimeBlockDuration,
  clock: clock ?? DateTime.now,
  startWithSelectedProfile: true,
  restBreakNotificationService:
      restBreakNotificationService ?? _MemoryRestBreakNotificationService(),
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

class _MemoryUserProfileStore implements UserProfileCollectionStore {
  _MemoryUserProfileStore({UserProfile? profile})
    : profiles = profile == null ? [] : [profile];

  List<UserProfile> profiles;
  UserProfile? get profile => profiles.isEmpty ? null : profiles.first;

  @override
  Future<UserProfile?> loadProfile() async => profile;

  @override
  Future<List<UserProfile>> loadProfiles() async => List.of(profiles);

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await saveProfiles([profile]);
  }

  @override
  Future<void> saveProfiles(List<UserProfile> profiles) async {
    this.profiles = List.of(profiles);
  }
}

class _MemoryFocusTasksProgressStore implements FocusTasksProgressStore {
  final Map<String, FocusTasksProgress> _progressByProfile = {};

  FocusTasksProgress get progress =>
      _progressByProfile['default'] ?? FocusTasksProgress.empty;
  set progress(FocusTasksProgress value) {
    _progressByProfile['default'] = value;
  }

  @override
  Future<FocusTasksProgress> loadProgress({
    String profileId = 'default',
  }) async => _progressByProfile[profileId] ?? FocusTasksProgress.empty;

  @override
  Future<void> saveProgress(
    FocusTasksProgress progress, {
    String profileId = 'default',
  }) async {
    _progressByProfile[profileId] = FocusTasksProgress(
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
      dailyCompletions: progress.dailyCompletions,
      lastActiveDate: progress.lastActiveDate,
      pendingCarryoverTaskIds: progress.pendingCarryoverTaskIds,
      activeRestEndTimeMillis: progress.activeRestEndTimeMillis,
      petMoodMinutes: progress.petMoodMinutes,
      petPatCount: progress.petPatCount,
    );
  }
}

class _MemoryRestBreakNotificationService
    implements RestBreakNotificationService {
  bool permissionGranted = true;
  Exception? showTimerException;
  int shownTimers = 0;
  int cancelledTimers = 0;

  @override
  Future<bool> showRestTimer(DateTime endsAt) async {
    shownTimers++;
    if (showTimerException case final error?) throw error;
    return permissionGranted;
  }

  @override
  Future<void> cancelRestTimer() async {
    cancelledTimers++;
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
