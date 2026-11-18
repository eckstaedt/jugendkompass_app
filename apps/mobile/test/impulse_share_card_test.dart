import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugendkompass_app/presentation/widgets/impulse/impulse_share_card.dart';

void main() {
  testWidgets('share card renders in 4:5 without overflow, long title is cut', (tester) async {
    final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAIAAAADnC86AAAAMElEQVR42u3NQQkAAAgEsItkJCMZ2RKCn8H+S/W8iFgsFovFYrFYLBaLxWKxWHxnAT//CGqOGOdjAAAAAElFTkSuQmCC');
    await tester.pumpWidget(Center(
      child: ImpulseShareCard(
        imageBytes: bytes,
        title: 'Ein sehr langer Impuls-Titel ' * 6,
        label: 'Impuls',
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ImpulseShareCard)), ImpulseShareCard.size);
    expect(find.text('JUGENDKOMPASS · IMPULS'), findsOneWidget);
  });
}
