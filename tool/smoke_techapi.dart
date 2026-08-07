// 실제 TechAPI 정적 덤프를 한 번 쳐 보는 수동 스모크 테스트.
//
// 단위 테스트는 픽스처로 고정돼 있어 원격이 죽어도 통과한다.
// 이 스크립트는 그 반대로, 원격이 살아 있는지 확인한다.
//
//   dart run tool/smoke_techapi.dart
//
// ignore_for_file: avoid_print — 콘솔 스크립트라 print가 출력 수단이다.
import 'package:techpicks/data/repository/tech_api_repository.dart';
import 'package:techpicks/domain/repository/device_repository.dart';

Future<void> main() async {
  final repo = TechApiRepository();

  final index = await repo.index();
  index.fold(
    (json) {
      final collections = json['collections'] as Map<String, dynamic>;
      print('컬렉션 ${collections.length}개');
      collections.forEach((name, meta) {
        print('  $name: ${(meta as Map)['count']}');
      });
    },
    (f) => print('인덱스 실패: $f'),
  );

  final phone = await repo.smartphone('galaxy-s25');
  phone.fold(
    (p) {
      final s = p.score;
      print('\n${p.name} (${p.brand?.name}) — ${p.soc?.name}');
      print('  종합 ${s?.overall}  성능 ${s?.performance}  카메라 ${s?.camera}');
      print('  배터리 ${s?.battery}  화면 ${s?.display}  가치 ${s?.value}');
      print('  등급 ${s?.perf?.tier} · 상위 ${s?.perf?.percentile}%');
      print('  출처 ${p.sourceUrls.length}건');
    },
    (f) => print('상세 실패: $f'),
  );

  final missing = await repo.smartphone('존재하지-않는-기기');
  print('\n없는 slug -> ${missing.failureOrNull?.runtimeType}');

  final brands = await repo.list(TechApiCollection.brands);
  print('브랜드 목록 -> ${brands.valueOrNull?.count}건');
}
