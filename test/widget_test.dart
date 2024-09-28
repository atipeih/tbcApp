import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tbc/main.dart';  // 実際のプロジェクト名に合わせて調整

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // テスト環境で使う SharedPreferences をセットアップ
  SharedPreferences.setMockInitialValues({});

  testWidgets('タバコの本数がカウントアップされる', (WidgetTester tester) async {
    // アプリを初期化してビルド
    await tester.pumpWidget(SmokingTrackerApp());

    // 初期状態でカウントは0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // 「タバコを吸った」ボタンをタップ
    await tester.tap(find.text('タバコを吸った'));
    await tester.pump();  // UIの再描画を反映

    // カウントが1に増えることを確認
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('カウント履歴が表示される', (WidgetTester tester) async {
    // 履歴にデータをモック
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> mockHistory = ['2024-09-23: 3', '2024-09-24: 5'];
    await prefs.setStringList('smoking_history', mockHistory);

    // アプリをビルド
    await tester.pumpWidget(SmokingTrackerApp());

    // 「履歴を確認する」ボタンをタップ
    await tester.tap(find.text('履歴を確認する'));
    await tester.pumpAndSettle();  // ページ遷移とUI更新

    // 履歴がリストに正しく表示されているか確認
    expect(find.text('2024-09-23: 3'), findsOneWidget);
    expect(find.text('2024-09-24: 5'), findsOneWidget);
  });

  testWidgets('0時にカウントがリセットされる', (WidgetTester tester) async {
    // 現在の日付をモック
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_saved_date', '2024-09-23');
    await prefs.setInt('count', 5);

    // アプリをビルドしてデータをロード
    await tester.pumpWidget(SmokingTrackerApp());

    // 初期状態でカウントが5（前日のデータ）であることを確認
    expect(find.text('5'), findsOneWidget);

    // 日付が変わっているため、カウントは0にリセットされるはず
    await prefs.setString('last_saved_date', '2024-09-24');
    await tester.pump();  // UIの再描画を反映

    // カウントが0にリセットされていることを確認
    expect(find.text('0'), findsOneWidget);
  });
}
