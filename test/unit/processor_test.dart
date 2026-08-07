import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/dto/brand.dart';
import 'package:techpicks/data/dto/cpu.dart';
import 'package:techpicks/data/dto/score.dart';
import 'package:techpicks/data/dto/soc.dart';
import 'package:techpicks/domain/model/processor.dart';

Soc _soc(String slug, {double? overall, double? nm, String? gpu}) => Soc(
      slug: slug,
      name: slug,
      manufacturer: const Brand(slug: 'qualcomm', name: 'Qualcomm'),
      processNm: nm,
      gpuName: gpu,
      score: overall == null ? null : SocScore(overall: overall),
    );

Cpu _cpu(String slug, {double? overall, int? cores, int? threads, int? tdp}) =>
    Cpu(
      slug: slug,
      name: slug,
      manufacturer: const Brand(slug: 'intel', name: 'Intel'),
      cores: cores,
      threads: threads,
      tdpW: tdp,
      score: overall == null ? null : CpuScore(overall: overall),
    );

void main() {
  group('sub 줄', () {
    test('모바일은 제조사·공정·GPU 를 가운뎃점으로 잇는다', () {
      final p = Processor.fromSoc(
        _soc('snapdragon-8-elite', overall: 96.7, nm: 3, gpu: 'Adreno 830'),
      );
      expect(p.sub, 'Qualcomm · 3nm · Adreno 830');
      expect(p.segment, ProcessorSegment.mobile);
      expect(p.index, 97);
    });

    test('공정이 소수면 그대로 쓴다', () {
      expect(Processor.fromSoc(_soc('x', nm: 4.5)).sub, 'Qualcomm · 4.5nm');
    });

    test('노트북은 코어 구성과 TDP 를 쓴다', () {
      final p = Processor.fromCpu(
        _cpu('core-i9-14900hx', overall: 77.7, cores: 24, threads: 32, tdp: 55),
      );
      expect(p.sub, 'Intel · 24C/32T · 55W');
      expect(p.segment, ProcessorSegment.laptop);
      expect(p.index, 78);
    });

    test('스레드 수가 없으면 코어만 쓴다', () {
      expect(Processor.fromCpu(_cpu('x', cores: 8)).sub, 'Intel · 8C');
    });

    test('없는 값은 자리를 남기지 않는다', () {
      expect(Processor.fromCpu(_cpu('x')).sub, 'Intel');
    });
  });

  group('정렬', () {
    test('점수 높은 순', () {
      final ranked = ProcessorRanking.of(<Processor>[
        Processor.fromSoc(_soc('b', overall: 80)),
        Processor.fromSoc(_soc('a', overall: 95)),
        Processor.fromSoc(_soc('c', overall: 87)),
      ]);
      expect(ranked.map((r) => r.processor.slug), <String>['a', 'c', 'b']);
      expect(ranked.map((r) => r.position), <int>[1, 2, 3]);
    });

    test('점수 없는 칩은 빼지 않고 아래로 민다', () {
      final ranked = ProcessorRanking.of(<Processor>[
        Processor.fromSoc(_soc('nope')),
        Processor.fromSoc(_soc('yes', overall: 50)),
      ]);
      expect(ranked.map((r) => r.processor.slug), <String>['yes', 'nope']);
      expect(ranked.last.fraction, 0);
    });

    test('트랙은 1위 기준으로 채운다', () {
      final ranked = ProcessorRanking.of(<Processor>[
        Processor.fromSoc(_soc('a', overall: 100)),
        Processor.fromSoc(_soc('b', overall: 50)),
      ]);
      expect(ranked.first.fraction, 1);
      expect(ranked.last.fraction, closeTo(0.5, 0.01));
    });

    test('점수가 하나도 없으면 이름순이고 트랙은 비어 있다', () {
      final ranked = ProcessorRanking.of(<Processor>[
        Processor.fromSoc(_soc('b')),
        Processor.fromSoc(_soc('a')),
      ]);
      expect(ranked.map((r) => r.processor.slug), <String>['a', 'b']);
      expect(ranked.every((r) => r.fraction == 0), isTrue);
    });

    test('빈 목록', () {
      expect(ProcessorRanking.of(const <Processor>[]), isEmpty);
    });
  });
}
