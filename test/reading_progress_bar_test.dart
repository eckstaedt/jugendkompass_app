import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugendkompass_app/presentation/widgets/common/reading_progress_bar.dart';

void main() {
  testWidgets('hidden until past the image, then follows scroll progress', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(bottom: ReadingProgressBar(controller: controller, revealAfter: 300)),
        body: SingleChildScrollView(
          controller: controller,
          child: const SizedBox(height: 3000),
        ),
      ),
    ));

    double opacity() => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
    double? value() => tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value;

    expect(opacity(), 0);

    controller.jumpTo(200); // still on the image
    await tester.pumpAndSettle();
    expect(opacity(), 0);

    controller.jumpTo(800);
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    final max = controller.position.maxScrollExtent;
    // the image (first 300 px) does not count
    expect(value(), closeTo((800 - 300) / (max - 300), 0.01));

    controller.jumpTo(301); // just below the image → starts at ~0
    await tester.pumpAndSettle();
    expect(value(), lessThan(0.01));

    controller.jumpTo(max);
    await tester.pumpAndSettle();
    expect(value(), closeTo(1, 0.001));
  });
}
