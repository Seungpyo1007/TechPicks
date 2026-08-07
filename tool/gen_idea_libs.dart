// IntelliJ / Android Studio가 Dart를 인식하도록 .idea/libraries/*.xml 을 만든다.
//
// 이 파일들은 원래 Dart·Flutter 플러그인이 자동 생성하지만, .idea 가 손상되거나
// 브랜치를 옮겨 다니는 사이 사라지면 모든 import 가 빨간 줄로 뜬다. 그때 쓴다.
//
//   dart tool/gen_idea_libs.dart
//
// 실행 전에 `flutter pub get` 으로 .dart_tool/package_config.json 이 현재
// 브랜치의 pubspec 과 맞는 상태여야 한다. 이게 어긋난 채로 돌리면 IDE 가
// 존재하지 않는 버전을 가리킨다.
//
// 끝나면 IDE 를 완전히 닫았다 다시 열 것. 열려 있으면 종료 시 덮어쓴다.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final root = Directory.current;
  final libsDir = Directory('${root.path}/.idea/libraries');
  libsDir.createSync(recursive: true);

  final sdk = _dartSdkPath();
  if (sdk == null) {
    stderr.writeln('Dart SDK를 찾지 못했다. flutter가 PATH에 있는지 확인할 것.');
    exit(1);
  }

  _writeDartSdk(libsDir, sdk);
  final count = _writeDartPackages(libsDir, root);
  final plugins = _writeFlutterPlugins(libsDir, root);

  stdout
    ..writeln('Dart SDK      $sdk')
    ..writeln('Dart Packages $count개')
    ..writeln('Flutter Plugins $plugins개')
    ..writeln('')
    ..writeln('IDE를 완전히 닫았다가 다시 열 것.');
}

/// `flutter` 실행 파일 위치에서 번들 Dart SDK 경로를 역산한다.
String? _dartSdkPath() {
  final which = Process.runSync('which', ['flutter']);
  if (which.exitCode != 0) return null;
  final binDir = File((which.stdout as String).trim()).resolveSymbolicLinksSync();
  // .../flutter/bin/flutter -> .../flutter/bin/cache/dart-sdk
  final flutterBin = Directory(binDir).parent.path;
  final sdk = '$flutterBin/cache/dart-sdk';
  return Directory(sdk).existsSync() ? sdk : null;
}

/// dart:async 같은 SDK 라이브러리를 등록한다.
void _writeDartSdk(Directory libsDir, String sdk) {
  final libRoot = Directory('$sdk/lib');
  final roots = libRoot
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split('/').last)
      // 앞에 밑줄이 붙은 것과 컴파일러 내부 디렉터리는 공개 라이브러리가 아니다.
      .where((n) => !n.startsWith('_') && n != 'dev_compiler' && n != 'internal')
      .toList()
    ..sort();

  final entries =
      roots.map((n) => '      <root url="file://$sdk/lib/$n" />').join('\n');

  File('${libsDir.path}/Dart_SDK.xml').writeAsStringSync('''
<component name="libraryTable">
  <library name="Dart SDK">
    <CLASSES>
$entries
    </CLASSES>
    <JAVADOC />
    <SOURCES />
  </library>
</component>
''');
}

/// pub 이 해석한 패키지들을 등록한다. package_config.json 이 유일한 근거다.
int _writeDartPackages(Directory libsDir, Directory root) {
  final configFile = File('${root.path}/.dart_tool/package_config.json');
  if (!configFile.existsSync()) {
    stderr.writeln('.dart_tool/package_config.json 이 없다. flutter pub get 먼저.');
    exit(1);
  }
  final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final packages = (config['packages'] as List).cast<Map<String, dynamic>>();

  final entries = StringBuffer();
  final classes = StringBuffer();
  var count = 0;

  for (final pkg in packages) {
    final name = pkg['name'] as String;
    final rootUri = pkg['rootUri'] as String;
    final packageUri = (pkg['packageUri'] as String?) ?? 'lib/';

    // 자기 자신은 소스 폴더라 라이브러리로 넣지 않는다.
    if (name == _projectName(root)) continue;

    final base = rootUri.startsWith('file://')
        ? Uri.parse(rootUri).toFilePath()
        : File('${root.path}/.dart_tool/$rootUri').absolute.path;
    final libPath = _normalize('$base/$packageUri');

    if (!Directory(libPath).existsSync()) continue;

    entries.writeln('''        <entry key="$name">
          <value>
            <list>
              <option value="$libPath" />
            </list>
          </value>
        </entry>''');
    classes.writeln('      <root url="file://$libPath" />');
    count++;
  }

  File('${libsDir.path}/Dart_Packages.xml').writeAsStringSync('''
<component name="libraryTable">
  <library name="Dart Packages" type="DartPackagesLibraryType">
    <properties>
      <option name="packageNameToDirsMap">
${entries.toString().trimRight()}
      </option>
    </properties>
    <CLASSES>
${classes.toString().trimRight()}
    </CLASSES>
    <JAVADOC />
    <SOURCES />
  </library>
</component>
''');
  return count;
}

/// 네이티브 코드를 가진 플러그인만 따로 등록한다. Flutter 플러그인이 쓰는 목록이다.
int _writeFlutterPlugins(Directory libsDir, Directory root) {
  final file = File('${root.path}/.flutter-plugins-dependencies');
  if (!file.existsSync()) return 0;

  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final plugins = data['plugins'] as Map<String, dynamic>?;
  if (plugins == null) return 0;

  final paths = <String>{};
  for (final platform in plugins.values) {
    if (platform is! List) continue;
    for (final entry in platform.cast<Map<String, dynamic>>()) {
      final path = entry['path'] as String?;
      if (path != null) paths.add(path.replaceAll(RegExp(r'/$'), ''));
    }
  }

  final roots = (paths.toList()..sort())
      .map((p) => '      <root url="file://$p" />')
      .join('\n');

  File('${libsDir.path}/Flutter_Plugins.xml').writeAsStringSync('''
<component name="libraryTable">
  <library name="Flutter Plugins" type="FlutterPluginsLibraryType">
    <CLASSES>
$roots
    </CLASSES>
    <JAVADOC />
    <SOURCES />
  </library>
</component>
''');
  return paths.length;
}

String _projectName(Directory root) {
  final pubspec = File('${root.path}/pubspec.yaml');
  if (!pubspec.existsSync()) return '';
  for (final line in pubspec.readAsLinesSync()) {
    if (line.startsWith('name:')) return line.substring(5).trim();
  }
  return '';
}

/// `a/b/../c` 같은 경로를 정리한다.
String _normalize(String path) {
  final parts = <String>[];
  for (final seg in path.split('/')) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(seg);
    }
  }
  return '/${parts.join('/')}';
}
