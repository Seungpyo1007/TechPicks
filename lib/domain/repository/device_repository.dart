import '../../core/result.dart';
import '../../data/dto/brand.dart';
import '../../data/dto/collection_page.dart';
import '../../data/dto/cpu.dart';
import '../../data/dto/gpu.dart';
import '../../data/dto/smartphone.dart';
import '../../data/dto/soc.dart';

/// 기기 데이터 조회.
///
/// 구현은 데이터를 어디서 가져오는지(정적 덤프 / REST / 로컬 캐시)를
/// 감춘다. 호출부는 [Result]만 다룬다.
abstract class DeviceRepository {
  Future<Result<Smartphone>> smartphone(String slug);
  Future<Result<Cpu>> cpu(String slug);
  Future<Result<Gpu>> gpu(String slug);
  Future<Result<Soc>> soc(String slug);
  Future<Result<Brand>> brand(String slug);

  /// 컬렉션 전체 목록.
  ///
  /// 정적 덤프에서는 한 요청에 전부 돌아온다. 스마트폰은 93,000건이
  /// 넘으므로 호출 전에 크기를 고려할 것.
  Future<Result<CollectionPage>> list(TechApiCollection collection);

  /// 컬렉션별 레코드 수 등 API 메타 정보.
  Future<Result<Map<String, dynamic>>> index();
}

/// API가 노출하는 컬렉션.
///
/// 경로에 그대로 쓰이는 값이므로 오타를 컴파일 단계에서 막는다.
enum TechApiCollection {
  smartphones('smartphones'),
  cpus('cpus'),
  gpus('gpus'),
  socs('socs'),
  brands('brands'),
  laptops('laptops'),
  monitors('monitors'),
  tablets('tablets'),
  watches('watches');

  const TechApiCollection(this.path);

  final String path;
}
