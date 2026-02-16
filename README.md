# SVGSwiftUI

`SVGSwiftUI`는 SVG 문자열/데이터/파일을 SwiftUI `Path` 기반으로 렌더링하는 가벼운 라이브러리입니다.
iOS 15 이상을 대상으로 하며, 파싱 결과(AST)를 메모리 캐싱하고 노드 단위 스타일/변환 오버라이드를 지원합니다.

## 지원 환경

- Swift 6+
- iOS 15+
- Swift Package Manager

## 설치

### SwiftPM (권장)

`Package.swift`에 의존성을 추가합니다.

```swift
dependencies: [
    .package(url: "https://github.com/minsOne/SVGSwiftUI.git", from: "0.1.0")
]
```

타겟 의존성:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "SVGSwiftUI", package: "SVGSwiftUI")
        ]
    )
]
```

## 기본 사용법

```swift
import SwiftUI
import SVGSwiftUI

struct ExampleView: View {
    @StateObject private var cacheStats = SVGCacheStats()

    private let svgSource = """
    <svg width="120" height="120" viewBox="0 0 120 120">
      <g id="badge-group">
        <circle id="badge-ring" cx="60" cy="60" r="50" fill="#f5f5f5" stroke="#333333" stroke-width="4"/>
        <path id="main-path" d="M60 24 L72 48 L99 52 L79 72 L84 99 L60 86 L36 99 L41 72 L21 52 L48 48 Z" fill="#ff7a59"/>
      </g>
    </svg>
    """

    var body: some View {
        SVGView(
            source: .string(svgSource),
            options: .init(),
            cacheStats: cacheStats
        )
        .frame(width: 120, height: 120)
    }
}
```

### `SVGSource` 입력 방식

- `.string(String)`: 인라인 SVG 문자열
- `.data(Data)`: UTF-8로 인코딩된 데이터
- `.fileURL(URL)`: 앱 번들/문서 폴더의 파일 URL

```swift
if let url = Bundle.main.url(forResource: "icon", withExtension: "svg") {
    SVGView(source: .fileURL(url))
}
```

## 노드 제어 (Node Override)

`SVGRenderConfiguration`으로 노드별 오버라이드를 조정할 수 있습니다.

### 1) `idOverrides`

`id` 또는 synthetic id 키로 특정 노드에 직접 오버라이드를 제공합니다.

```swift
var config = SVGRenderConfiguration()
config.idOverrides = [
    "main-path": NodeOverride(
        fill: .color(.init(red: 1, green: 0.25, blue: 0.25, alpha: 1)),
        stroke: .color(.init(red: 0.1, green: 0.2, blue: 1, alpha: 1)),
        strokeWidth: 2.5,
        opacity: 0.95,
        scale: .init(width: 1.2, height: 1.2),
        offset: .init(x: 4, y: -3)
    )
]

SVGView(source: .string(svgSource), configuration: config)
```

### 2) `resolver` 클로저

노드 타입/속성에 따라 동적으로 오버라이드를 생성합니다.

```swift
let resolver: NodeStyleResolver = { context in
    guard context.element == .path else {
        return nil
    }
    if context.id == "main-path" || context.syntheticID == "auto:/0/1" {
        return NodeOverride(
            stroke: .color(.init(red: 0.08, green: 0.3, blue: 1, alpha: 1)),
            strokeWidth: 3
        )
    }
    return nil
}

SVGView(
    source: .string(svgSource),
    configuration: SVGRenderConfiguration(
        idOverrides: [:],
        resolver: resolver
    )
)
```

### XCFramework (GitHub Release)

`GitHub Releases`에 업로드된 `SVGSwiftUI-<version>.xcframework.zip`를 내려받아 통합할 수 있습니다.

1. 릴리스 페이지에서 `SVGSwiftUI-<version>.xcframework.zip`를 다운로드합니다.
2. Xcode에서 `File > Add Packages...`가 아닌 `File > Add Files...`로 압축을 풀어 얻은 `.xcframework`를 프로젝트에 추가합니다.
3. 프로젝트의 타깃 > `General > Frameworks, Libraries, and Embedded Content`에 `SVGSwiftUI.xcframework`를 추가하고, 사용 방식은 `Embed & Sign` 또는 필요에 맞게 설정합니다.
4. Swift 파일에서 `import SVGSwiftUI`로 사용합니다.

릴리스 아티팩트는 아래 명령으로 로컬에서 직접 생성할 수 있습니다.

```bash
./Scripts/package-release.sh --version 1.0.0
```

생성 결과:
- `build/xcframework/SVGSwiftUI-<version>.xcframework.zip`
- `build/xcframework/SVGSwiftUI-<version>.xcframework.zip.sha256`

우선순위는 항상 `idOverrides` → `resolver` 입니다.

## 캐시 및 성능

`SVGView`는 파싱 결과를 캐시할 수 있으며, `SVGCacheStats`로 메트릭을 구독할 수 있습니다.

```swift
@StateObject private var cacheStats = SVGCacheStats()

var body: some View {
    VStack {
        SVGView(
            source: .string(svgSource),
            cacheStats: cacheStats
        )

        Text("Cache hit rate: \(cacheStats.metrics.hitRate * 100, specifier: \"%.2f%%\")")
    }
}
```

측정 항목:
- `requests`, `hits`, `misses`
- `entries`, `totalCost`
- `hitRate`

`SVGParseCache`와 키는 파서 옵션을 포함해 구성되므로, 동일한 입력+옵션에서만 cache hit이 발생합니다.

### 파서 옵션

`SVGParserOptions`는 현재 파서 정책 버전(`parserSchemaVersion`)과 캐시 키 분기를 위한 확장 필드를 포함합니다.
현재 렌더 경로는 v1 기본 동작이 우선이지만, `enableStyleTag`는 CSS subset 수집용 파싱에만 사용됩니다.
`enableDataURI`, `maxDataURIBytes`, `maxEmbeddedImageCount`, `maxEmbeddedImageDepth`, `imageNodePolicy`는 v2 목표인 `data:` URI/이미지 정책에서 사용됩니다.

`imageNodePolicy`는 `image` 요소의 렌더 정책을 제어합니다.
- `.ignore`: `image` 노드를 렌더/노드 구조에서 제거
- `.renderRaster`: 비-SVG `image`를 placeholder 렌더 노드로 변환
- `.failOnRaster`: 비-SVG `image`를 파싱 에러로 처리(`notImplemented`)

## 지원 기능 (V1 기준)

- 요소: `svg`, `g`, `path`, `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`
- Path 명령: `M`, `L`, `H`, `V`, `C`, `S`, `Q`, `T`, `A`, `Z` (대/소문자 구분 없이)
- 스타일: `fill`, `fill-opacity`, `stroke`, `stroke-width`, `stroke-opacity`, `opacity`, `style` 속성 내 제한된 속성
- `<style>` 규칙 파싱: `enableStyleTag` 옵션 활성 시 CSS의 `type/class/element` selector 기반 기본 rule 수집 지원
- 변환: `transform`의 `translate`, `scale`, `rotate`, `matrix`
- 노드 제어: id 기반 override map + resolver closure
- 캐시 키: 입력 데이터 + parser options + schema version

### SMIL/CSS 애니메이션 지원 상태

본 라이브러리는 SMIL/애니메이션을 기본적으로 지원하지만 100%가 아닌 **제어된 스펙 범위**입니다.

- 파서 수집 지원: `animate`, `set`, `animateTransform`, `animateMotion`
- 렌더 반영 지원:
  - `animate` / `set`의 `from`/`to`/`by` 및 기본 `values` 보간
  - `animateTransform`의 `rotate`, `scale`, `translate` 기본 보간
  - `animateMotion`의 이동 좌표/경로 보간 및 `rotate`(fixed/auto/auto-reverse) 최소 동작
  - CSS `@keyframes`와 `animation` 단축/개별 속성의 매핑(SMIL 엔진으로 변환)
- 부분 지원(실험/제약):
  - `keyTimes`, `keySplines`, `begin` 이벤트 체인, 일부 고급 SMIL 속성
  - `repeatDur`, 다중 `begin`/`end` 의존성의 완전한 타이밍 정합
  - 일부 SMIL 속성/요소(`animateColor`, `animateOpacity` 등)는 `unsupportedFeatures`로 폴백 처리
- 미지원/확장 항목은 `docs/SMIL_FEATURE_MATRIX.md`에 실시간 갱신

지원되지 않거나 제한적으로 동작하는 항목:
- 고급 렌더 규칙 중 `mask`, `filter`, 그라디언트, 텍스트/이미지 고급 케이스는 미지원
- `clipPath`는 `url(#id)` 참조의 기본 케이스만 제한적으로 지원

## 데모 앱 및 테스트

프로젝트에는 `Examples/SVGSwiftUIDemo`가 포함됩니다.

- 데모 앱은 렌더/오버라이드/캐시 통계를 직접 확인할 수 있는 UI를 제공합니다.
- 기준 이미지 시각 회귀 테스트를 통해 실제 렌더 결과를 검증합니다.
- 단위 테스트: 파서/스타일/캐시/변환/path 빌더/fixture 회귀 테스트로 구성

### 테스트 실행

```bash
swift test --parallel
```

### 데모 UITest 실행

```bash
xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj \
  -scheme SVGSwiftUIDemo \
  -destination "id=<YOUR_SIMULATOR_ID>" \
  test
```

CI에서는 iOS Simulator를 자동 탐색한 뒤 실행되며, 스냅샷 동시 실행은 비활성화(`-parallel-testing-enabled NO`)로 재현성을 확보합니다.

### 배포/CI 체크 포인트

- `swift test --no-parallel`  
  - 라이브러리 API 및 렌더 파이프라인 회귀 탐지
- `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination "platform=iOS Simulator,name=iPhone 17" build CODE_SIGNING_ALLOWED=NO`
  - 데모 앱 빌드 유효성 검사
- `./Scripts/package-release.sh --version <ver> --output build/xcframework`
  - xcframework 생성 경로 점검 및 아티팩트(`.zip`, `.sha256`) 존재성 확인

모든 배포 산출물은 `.gitignore`에서 무시되며, 공개 저장소에는 코드/문서/테스트/스크립트만 반영됩니다.

## 개발 관련 문서

- `docs/STEP_BY_STEP_PLAN.md`: 단계별 수행 계획
- `docs/TASK_BOARD.md`: 작업 상태 보드
- `docs/WORK_CONTINUATION.md`: 다음 실행 순서
- `docs/WORK_LOG.md`: 작업 세션 로그
- `docs/API_SURFACE_POLICY.md`: 공개 API 정책
- `docs/DEMO_UITEST_STRATEGY.md`: Demo UITest 전략
- `docs/W3C_CONFORMANCE_PLAN.md`: W3C conformance 확장 계획

## 라이선스

MIT
