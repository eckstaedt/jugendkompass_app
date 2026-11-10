import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jugendkompass_app/data/models/app_announcement_model.dart';
import 'package:jugendkompass_app/data/repositories/announcement_repository.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/presentation/widgets/announcement/announcement_overlay.dart';

class _FakeRepository extends AnnouncementRepository {
  _FakeRepository(this.announcement);
  AppAnnouncement? announcement;
  final dismissed = <String>[];
  final requestedLanguages = <String>[];

  @override
  Future<AppAnnouncement?> fetchAnnouncementToShow(String language) async {
    requestedLanguages.add(language);
    return dismissed.contains(announcement?.id) ? null : announcement;
  }

  @override
  Future<void> markDismissed(String id) async => dismissed.add(id);
}

AppAnnouncement _announcement({bool dismissible = true}) => AppAnnouncement(
      id: 'a1',
      title: 'Neue Ausgabe ist da!',
      message: 'Jetzt im Kiosk.',
      // Square (1184x1184) bundled image.
      imageUrl: 'asset:assets/images/logo.png',
      translations: const {},
      startsAt: DateTime.now().subtract(const Duration(hours: 1)),
      endsAt: DateTime.now().add(const Duration(days: 1)),
      dismissible: dismissible,
      showOnce: true,
    );

Future<void> _pump(WidgetTester tester, _FakeRepository repo) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => AnnouncementOverlay(repository: repo, child: child!),
        home: const Scaffold(body: Text('App-Inhalt')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPreferencesService.instance.init();
  });

  testWidgets('shows the popup full screen with an uncropped image', (tester) async {
    final repo = _FakeRepository(_announcement());
    await _pump(tester, repo);

    expect(find.text('Neue Ausgabe ist da!'), findsOneWidget);
    expect(find.text('Jetzt im Kiosk.'), findsOneWidget);
    expect(repo.requestedLanguages, ['de']);

    // Square source image stays square (no forced 3:2 crop).
    final size = tester.getSize(find.byType(Image));
    expect(size.width, closeTo(size.height, 0.5));
  });

  testWidgets('"Verstanden" closes the popup and remembers it', (tester) async {
    final repo = _FakeRepository(_announcement());
    await _pump(tester, repo);

    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();

    expect(find.text('Neue Ausgabe ist da!'), findsNothing);
    expect(find.text('App-Inhalt'), findsOneWidget);
    expect(repo.dismissed, ['a1']);
  });

  testWidgets('non-dismissible popup has no close button', (tester) async {
    final repo = _FakeRepository(_announcement(dismissible: false));
    await _pump(tester, repo);

    expect(find.text('Neue Ausgabe ist da!'), findsOneWidget);
    expect(find.text('Verstanden'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
