import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:todo_refatoracao_baguncado/features/todos/presentation/app_root.dart';
import 'package:todo_refatoracao_baguncado/features/todos/presentation/viewmodels/todo_viewmodel.dart';

void main() {
  testWidgets('App renders TodosPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TodoViewModel()),
        ],
        child: const AppRoot(),
      ),
    );

    expect(find.text('Todos'), findsOneWidget);
  });
}
