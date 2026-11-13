import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udl_assets/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Menampilkan halaman ringkasan aplikasi', (tester) async {
    await tester.pumpWidget(const AssetApp());
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan Aset'), findsOneWidget);
    expect(find.text('Total aset aktif'), findsOneWidget);
  });
}
