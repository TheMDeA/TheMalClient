import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malclient/src/core/api/mal_api_client.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/data/repositories/media_repository.dart';
import 'package:malclient/src/features/detail/detail_screen.dart';

class _FakeRepo extends MediaRepository {
  _FakeRepo()
      : super(
          MalApiClient(
            getAccessToken: () async => null,
            refreshToken: () async => false,
          ),
          demo: true,
        );

  @override
  Future<AnimeDetail> animeDetail(int id) async {
    return AnimeDetail(
      id: 1,
      title: 'Kusuriya no Hitorigoto',
      titleEn: 'The Apothecary Diaries',
      titleJa: '薬屋のひとりごと',
      genres: const [],
    );
  }
}

void main() {
  testWidgets('TI/EN/JA switcher changes the app bar title',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaRepositoryProvider.overrideWithValue(_FakeRepo()),
        ],
        child: const MaterialApp(
          home: DetailScreen(kind: ListKind.anime, id: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default title shown.
    expect(find.text('Kusuriya no Hitorigoto'), findsWidgets);

    // Tap EN.
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    // App bar title should now be the English title.
    expect(find.text('The Apothecary Diaries'), findsWidgets);
  });
}
