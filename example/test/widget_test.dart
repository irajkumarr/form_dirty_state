import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_dirty_state_example/main.dart';

void main() {
  testWidgets('Edit profile form displays initial data and updates dirty state',
      (tester) async {
    await tester.pumpWidget(const EditProfileApp());
    await tester.pumpAndSettle();

    // Navigate from HomeScreen to EditProfileScreen
    await tester.tap(find.widgetWithText(FilledButton, 'Edit Profile'));
    await tester.pumpAndSettle();

    // Verify initial values appear
    expect(find.text('Raj Kumar Timalsina'), findsOneWidget);
    expect(find.text('raj@example.com'), findsOneWidget);
    expect(find.text('+977 9800000000'), findsOneWidget);
    expect(find.text('Kathmandu'), findsOneWidget);

    // Initial state: not dirty, Save button disabled
    expect(find.text('Saved'), findsOneWidget);
    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Changes'),
    );
    expect(saveButton.onPressed, isNull);

    // Modify the Name field
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 'Raj Kumar');
    await tester.pumpAndSettle();

    // State after modification: dirty, Save button enabled
    expect(find.text('Unsaved changes'), findsOneWidget);
    final enabledSaveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Changes'),
    );
    expect(enabledSaveButton.onPressed, isNotNull);
    expect(find.text('• isDirty: true'), findsOneWidget);
    expect(find.text('• dirtyFields: name'), findsOneWidget);

    // Press Reset button
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pumpAndSettle();

    // Form reverted back to clean
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Raj Kumar Timalsina'), findsOneWidget);
  });
}
