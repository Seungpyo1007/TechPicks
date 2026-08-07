import '../../core/failure.dart';
import '../../core/network/tech_api_client.dart';
import '../../core/result.dart';
import '../../domain/repository/device_repository.dart';
import '../dto/brand.dart';
import '../dto/collection_page.dart';
import '../dto/cpu.dart';
import '../dto/gpu.dart';
import '../dto/smartphone.dart';
import '../dto/soc.dart';

/// [TechApiClient] 위에 얹은 [DeviceRepository] 구현.
///
/// 클라이언트가 던지는 [Failure]를 [Result]로 접고, JSON을 DTO로 바꾼다.
/// 파싱 도중 터지는 예외도 [ParseFailure]로 감싸 밖으로 새지 않게 한다.
class TechApiRepository implements DeviceRepository {
  TechApiRepository({TechApiClient? client})
      : _client = client ?? TechApiClient();

  final TechApiClient _client;

  @override
  Future<Result<Smartphone>> smartphone(String slug) =>
      _detail('smartphones', slug, Smartphone.fromJson);

  @override
  Future<Result<Cpu>> cpu(String slug) => _detail('cpus', slug, Cpu.fromJson);

  @override
  Future<Result<Gpu>> gpu(String slug) => _detail('gpus', slug, Gpu.fromJson);

  @override
  Future<Result<Soc>> soc(String slug) => _detail('socs', slug, Soc.fromJson);

  @override
  Future<Result<Brand>> brand(String slug) =>
      _detail('brands', slug, Brand.fromJson);

  @override
  Future<Result<CollectionPage>> list(TechApiCollection collection) =>
      _guard(() async {
        final json = await _client.getJson(
          _client.source.list(collection.path),
          collection: collection.path,
        );
        return CollectionPage.fromJson(json);
      });

  @override
  Future<Result<Map<String, dynamic>>> index() => _guard(() async {
        return _client.getJson(_client.source.index());
      });

  Future<Result<T>> _detail<T>(
    String collection,
    String slug,
    T Function(Map<String, dynamic>) parse,
  ) =>
      _guard(() async {
        final json = await _client.getJson(
          _client.source.detail(collection, slug),
          collection: collection,
          slug: slug,
        );
        return parse(json);
      });

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Failure catch (f) {
      return Err(f);
    } catch (e) {
      // TypeError 등 DTO 파싱 실패. 스키마가 바뀌면 여기로 떨어진다.
      return Err(ParseFailure('응답을 모델로 변환하지 못했다', cause: e));
    }
  }
}
