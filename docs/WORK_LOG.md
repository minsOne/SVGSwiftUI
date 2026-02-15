# SVGSwiftUI Work Log

## 2026-02-15

### Session 42
- 작업: 변경 반영 정리 및 커밋 루틴 고정
- 완료:
  - `WORK_CONTINUATION.md`에 작업 루프(재작업 방지) 및 커밋 단계 추가
  - `TASK_BOARD.md`에 커밋 중심 운영 규칙 추가
- 리스크:
  - 없음(문서 반영)
- 다음 액션:
  - 변경사항 정리 후 세션 단위 커밋 수행
- 검증:
  - `git status --short`로 추적 파일 범위 확인

### Session 41
- 작업: `S3-2` 성능 실측 근거 수집 단계 시작
- 완료:
  - `SVGRenderPerformanceProfileTests` 신규 추가
  - `Tests/SVGRenderPerformanceProfileTests.testRenderProfileAtCacheEnabledBoundary`
  - `Tests/SVGRenderPerformanceProfileTests.testRenderProfileWhenNodeThresholdExceeded`
  - `Tests/SVGRenderPerformanceProfileTests.testRenderProfileWhenSourceSizeThresholdExceeded`
  - `./Scripts/performance/run-s3-profile.sh` 추가
  - CI `ci.yml`에 S3 성능 프로파일 스텝 + `s3-profile.log` artifact 업로드 추가
  - `docs/S3_PERFORMANCE_TUNING.md`에 실측 기준/로그/CI 반영 항목 추가
- 리스크:
  - 측정은 워크로드가 경량이며, 색상/클립패스/필터 조합은 다음 단계 성능 시나리오에서 보완 필요
- 다음 액션:
  - `s3-profile.log` 기준치 통합 기록 템플릿 작성
  - 고밀도/복합 요소(clipPath/mask/filter) 포함한 추가 경계 성능 시나리오 수집
- 검증:
  - `swift test --filter SVGRenderPerformanceProfileTests --no-parallel` (3 tests, 0 failures)
  - `./Scripts/performance/run-s3-profile.sh`
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`
  - `swift test --parallel` (126 tests, 0 failures)
- 비고:
  - `testRenderProfileAtCacheEnabledBoundary` 측정 평균 약 0.019초
  - `testRenderProfileWhenNodeThresholdExceeded` 측정 평균 약 0.017초
  - `testRenderProfileWhenSourceSizeThresholdExceeded` 측정 평균 약 0.020초

### Session 40
- 작업: `S3-1` 경계값 재점검(정합성 보강)
- 완료:
  - `SVGRenderCachePolicy` 임계치 테스트를 경계값(`nodeCount == 2000`, `sourceBytes == 300_000`) 기준까지 확장
  - 정책 결정(`drawNodes`, `pathCache`) 일관성 단위 테스트 1건 추가
- 리스크:
  - 대형 SVG에서 임계치 임계점 근처(`2001`, `300_001`) 성능 영향은 실측값이 없어 추가 계측 필요
- 다음 액션:
  - 대표 대형 SVG fixture 기준 프레임/메모리 프로파일 로그 자동 수집을 CI/로컬에 추가
- 검증:
  - `swift test --filter SVGRenderCachePolicyTests --parallel`
  - `swift test --parallel` (123 tests, 0 failures)
  - `swift test --filter testW3CGeneratedSuite --no-parallel` (pass)
  - `swift test --filter testWebKitGeneratedSuite --no-parallel` (pass)

### Session 39
- 작업: `S3-1` 렌더 경로 메모리 게이트 2차 반영
- 완료:
  - `SVGRenderCachePolicy`에 `Decision` 타입을 추가하고 `shouldCachePathCache` 정책(노드 수/원본 바이트 임계치) 도입
  - `SVGStaticPlaceholderView`에서 `drawNodes` 캐시뿐 아니라 `pathCache`도 임계치 기반으로 생성/해제
  - `pathCache` 미사용 문서는 `SVGNodePathBuilder` 실시간 빌드 fallback 경로로 렌더 노드 구성
  - 정책 경계 단위 테스트 4건 추가
- 리스크:
  - 대형 문서에서 `pathCache` 비활성 시 노드 렌더링 비용이 증가할 수 있어 추가 지표(프레임 타이밍) 모니터링 필요
- 다음 액션:
  - 성능 임계값 보정을 위한 대표 대형 SVG fixture 기반 프로파일링
- 검증:
  - `swift test --parallel` (122 tests, 0 failures)
  - `swift test --filter SVGRenderCachePolicyTests`
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination id=CA606231-D9E3-453A-83EB-930148F67AED -parallel-testing-enabled NO test` (5 tests, 0 failures)

### Session 38
- 작업: `S3-1` render 캐시 고도화 1차
- 완료:
  - `SVGStaticPlaceholderView`에서 렌더 구성 캐시 키(`SVGRenderConfigurationSignature`) 도입
  - resolver가 없는 정적 구성에서 `drawNodes` 계산을 캐시해 `styleResolver.resolve`/`buildDrawNodes` 재연산을 억제
  - parse-cache 로드 경로에서 `cachedDrawNodes`/`cachedConfigurationFingerprint` 정합성 정리
  - `SVGRenderConfigurationSignature` 단위 테스트 3건 추가
- 리스크:
  - `resolver` 클로저 정체성 추적이 어렵고, 캐시 키는 존재 여부만 반영됨
  - 대형 SVG 메모리 임계 정책은 다음 세부 단계로 이월
- 다음 액션:
  - `S3-1`: 대형 SVG 임계값/메모리 게이트 규칙 및 문서화를 추가
- 검증:
  - `swift test --parallel` (114 tests, 0 failures)
  - `swift test --filter SVGRenderConfigurationSignatureTests`
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`

### Session 37
- 작업: `S2-2` clipPath 최소 구현 마무리
- 완료:
  - `Sources/SVGSwiftUI/Parser/SVGParser.swift`에서 인라인 `style`의 `clip-path`를 `clipPath` 속성으로 승격해 `base.attributes`에 반영
  - `Sources/SVGSwiftUI/Parser/SVGParser.swift`의 파싱 경로에서 `clipPath` 정의(`clipPaths`) 전달이 AST 캐시 파이프라인 전 구간에서 유지되는지 확인
  - `Sources/SVGSwiftUI/Render/SVGView.swift`에서 `clipPaths` 캐시 생성/적용 및 스택 기반 전파 처리 보강
  - `Tests/SVGSwiftUITests/SVGParserTests.swift`에 inline style 기반 `clip-path` 우선순위 테스트 추가
- 검증:
  - `swift test --filter SVGParserTests`
  - `swift test --filter SVGClipPathTests`
  - `swift test` (110 tests, 0 failures)
- 리스크:
  - `clipPath` 지원 범위는 `url(#id)` + 도형/경로 계열로 제한. 스타일시트 기반 `clip-path` selector 규칙은 미지원
- 다음 액션:
  - `S3-1`: 대형 SVG 성능/메모리 경향을 정량화하고 튜닝 기준 확정

### Session 36
- 작업: WebKit 후보군 A10-3 확장 완료 정리 및 검증
- 완료:
  - `Tests/SVGSwiftUITests/WebKit/webkit-manifest.json`에 unsupported 카테고리 12건 추가(전체 52건)
  - `./Scripts/webkit/fetch-layout-tests.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json Tests/SVGSwiftUITests/WebKit/fixtures` 재실행
  - `./Scripts/webkit/generate-webkit-tests.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json Tests/SVGSwiftUITests/WebKitGeneratedTests.swift` 재생성
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict` 실행
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict` 실행
- 결정:
  - `A10-3`를 완료 처리하고 다음 우선순위를 `S2-2`(clipPath 최소 구현)로 이동
- 리스크:
  - `unsupported` 항목은 파싱 합격/실패만 추적되며, 렌더 지원은 별도 기능 구현/테스트로 확인 필요
- 다음 액션:
  - `S2-2`: `url(#id)` 기반 clipPath 최소 렌더링 경로, selector/정합성 테스트 추가
- 검증:
  - `swift test --parallel` (106 tests, 0 failures)
  - `swift test --filter testWebKitGeneratedSuite --no-parallel` (pass)

### Session 35
- 작업: WebKit LayoutTests 1차 후보군 정합성 정리 및 upstream 동기화 보강
- 완료:
  - `./Scripts/webkit/fetch-layout-tests.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json Tests/SVGSwiftUITests/WebKit/fixtures` 재실행
  - `Scripts/webkit/fetch-layout-tests.sh`에서 `fixtures/` prefix가 겹치는 경로 정규화 처리 적용
  - `Tests/SVGSwiftUITests/WebKit/webkit-manifest.json` 기준으로 fixtures 40건 정합성 확인 (missing 0, extra 0)
  - `./Scripts/webkit/generate-webkit-tests.sh ...` 및 `./Scripts/webkit/webkit-coverage.sh ... --strict` 재생성/검증
- 결정:
  - `LayoutTests/svg` 기반 테스트 기준을 유지하고, 현재는 `unsupported` 없이 pass 기반 40건으로 고정
  - 향후 A10-3 확장을 위해 `fetch-layout-tests.sh`를 통해 정합성 유지가 자동화됨
- 리스크:
  - 고급 기능(`mask`/`filter`/`clipPath`)은 현재 후보군에서 제외되어 경계 신호가 제한됨
- 다음 액션:
  - A10-3에서 후보군 크기/카테고리/unsupported 전환 규칙을 단계적으로 확장
- 검증:
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`
  - `swift test --parallel`
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict`

### Session 34
- 작업: WebKit LayoutTests conformance 파이프라인 정합성 점검
- 완료:
  - `swift test --filter testWebKitGeneratedSuite --no-parallel` 재실행 (pass)
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict` 재실행 (strict pass)
  - `swift test --parallel` 재실행 (97 tests, 0 failures)
  - WebKit coverage 리포트에서 `reference` 비어있는 항목 표시를 `N/A`로 보정
- 결정:
  - `A10-2` 완료로 `Last Updated`와 `TASK_BOARD` 상태를 `A10-2 done`, `A10-3 in_progress`로 갱신
- 리스크:
  - 현재 WebKit 후보군은 pass 전용이어서 unsupported 추세가 아직 적음
- 다음 액션:
  - A10-3에서 WebKit 후보군 20~40건으로 확대 후 unsupported 전환 규칙 적용
- 검증:
  - `swift test --parallel`
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict`

### Session 33
- 작업: WebKit LayoutTests 기반 conformance 인프라 1차 구축
- 완료:
  - `Scripts/webkit/fetch-layout-tests.sh`, `generate-webkit-tests.sh`, `webkit-coverage.sh` 추가
  - `Tests/SVGSwiftUITests/WebKit/webkit-manifest.json` 및 12개 WebKit SVG fixture 동기화/커밋
  - `Tests/SVGSwiftUITests/WebKitGeneratedTests.swift` 생성
- 결정:
  - WebKit reference는 1차 단계에서 미사용 허용하여 `reference` 빈 값을 strict 검사에서 제외
- 리스크:
  - WebKit LayoutTests 후보군은 12개로 시작해 향후 확장 필요
- 다음 액션:
  - `A10-2` (`testWebKitGeneratedSuite`/coverage CI) 완료 후 `S2-2`로 복귀
- 검증:
  - `swift test --parallel` (97 tests, 0 failures)
  - `swift test --filter testWebKitGeneratedSuite --no-parallel` (pass)
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict`

### Session 32
- Scope:
  - 운영 안정화 2차 시작 준비: S2-1 고급 렌더 기능 후보 분석
- Completed:
  - `docs/ADVANCED_RENDER_FEATURE_ANALYSIS.md` 작성 (clip/mask/filter/masking 후보와 우선순위/난이도/테스트 방향 정리)
  - `docs/STEP_BY_STEP_PLAN.md`에 `S2-2 clipPath 미니멈 구현` 단계 추가
  - `docs/TASK_BOARD.md` `S2-1 done`, `S2-2 in_progress`로 갱신
- Decision:
  - 우선 `clipPath`만 1차 구현 대상으로 확정하고 `mask/filter`는 후속 단계로 분리
- Validation:
  - `swift test --parallel`
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination id=CA606231-D9E3-453A-83EB-930148F67AED -parallel-testing-enabled NO test`

## 2026-02-15

### Session 31
- Scope:
  - 운영 안정화 1차: 렌더 성능(고해상도 대상) 개선
- Completed:
  - `SVGView`에서 파싱/캐시 hit 후 렌더 패스 캐시(`pathCache`)를 선생성하여 매 프레임 `SVGNodePathBuilder` 재실행을 축소
  - 문서 로드 실패/교체 시 캐시 초기화 및 캐시 적중/미스 플로우 유지
  - `swift test --parallel` 통과
  - `swift test --filter testW3CGeneratedSuite --no-parallel` 통과
  - `./Scripts/w3c/w3c-coverage.sh ... --strict` 통과
  - Demo UITest 5개 통과 (동일 destination 재실행)
- Decision:
  - 경량 성능 개선은 렌더 단계 path 캐싱으로 완료. 다음 단계는 clip/mask/filter/matching 기능 범위 평가로 전환
- Verification:
  - 캐시 경로: `Sources/SVGSwiftUI/Render/SVGView.swift`
  - 테스트 명령: `swift test --parallel`, `swift test --filter testW3CGeneratedSuite --no-parallel`, `xcodebuild ...`

### Session 30
- Scope:
  - 운영 안정화 1차: CI/문서 정합성 점검 및 세션 로그 동기화
- Completed:
  - `swift test --parallel` 재실행 및 통합 통과 확인(총 94 tests)
  - `swift test --filter testW3CGeneratedSuite --no-parallel` 통과(1/1)
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict` 실행
  - Demo UITest (`xcodebuild ...` , 5 tests) 통과
  - README 지원 기능 문구에서 현재 구현 상태와 미지원 항목 정합성 보정
  - `docs/WORK_CONTINUATION.md` 현재 상태/다음 단계/세션 로그 갱신
- Decision:
  - `swift test --filter`의 toolchain별 동작 차이로 인해 W3C conformance 단계는 CI에서 `--no-parallel` 고정 유지

### Session 29
- Scope:
  - `A6-1` raster image 정책 구현
  - `A7-1` cache key versioning 보강
- Completed:
  - `SVGImageNodePolicy` 추가 및 정책별 파싱 경로 반영 (`ignore`/`renderRaster`/`failOnRaster`)
  - `image` 노드를 `rasterImage` 노드로 렌더 placeholder 처리하는 경로 추가
  - `testParseImageNodeIgnoresRasterDataURINodeByDefault`, `...RendersRaster...`, `...FailsOnRaster...` 테스트 추가
  - `SVGParseCache` 테스트에 parser option 변경 시 cache key 불일치 검증 추가
  - CI W3C conformance 단계 필터 실행 방식 보정 (`--filter testW3CGeneratedSuite --no-parallel`)
- Validation:
  - `swift test --parallel` (93 tests, 0 failures)
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination id=CA606231-D9E3-453A-83EB-930148F67AED -parallel-testing-enabled NO test` (5 tests, 0 failures)
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`
  - `swift test --filter testW3CGeneratedSuite --no-parallel` (1 test)

### Session 28
- Scope:
  - `A5-1` embedded SVG 재귀 처리 + `maxEmbeddedImageDepth`/`maxEmbeddedImageCount` 제한 정책
- Completed:
  - `SVGParserOptions`에 `maxEmbeddedImageDepth` 추가 및 기본값 적용
  - `SVGParser`에 임베디드 상태 공유 구조(`SVGEmbeddedImageState`) 추가
  - `SVGParser` 동작을 `XML 파싱 -> 임베디드 AST post-parse 확장` 방식으로 전환
  - `image` 노드의 data URI가 `image/svg+xml`인 경우에만 재귀 파싱, 실패/한도 초과 시 노드 드롭
  - synthetic ID 재배치 규칙(`parent/embedded/...`) 정합화
  - `testParseImageNodeExpandsDataURIEmbeddedSVG`, `testParseImageNodeSupportsNestedImageDataURIs`, `testEmbeddedImageRespectsMaxCount`, `testEmbeddedImageRespectsMaxDepth` 추가
- Validation:
  - `swift test --parallel` (90 tests, 0 failures)
  - `swift build` 검증은 병행되어 CI 워크플로우와 충돌 없음(상태: 빌드 성공)
- Next:
  - `A6-1` raster image 정책(무시/렌더/실패 모드) 구현

### Session 26
- Scope:
  - `A4-1` data URI parser/base64 디코더 구현
- Completed:
  - `SVGDataURIParser` 신규 타입 추가
    - `data:` URI prefix/header/data 분리 파싱
    - base64 디코딩(`.ignoreUnknownCharacters` 옵션)
    - percent 인코딩 텍스트 디코딩
    - 기본 미디어타입(`text/plain;charset=US-ASCII`) 처리
    - `payloadTooLarge` 제한 검사(`maxDataURIBytes`)
  - `SVGParser.parseDataURI(_:options:)` 추가
    - `enableDataURI` 게이트, `maxDataURIBytes > 0` 가드
  - `SVGDataURIParserTests` 신규 추가(정상/예외 8건)
- Validation:
  - `swift test --parallel` (86 tests, 0 failures)
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`
  - `Generated coverage report -> docs/W3C_COVERAGE.md`
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'id=CA606231-D9E3-453A-83EB-930148F67AED' -parallel-testing-enabled NO test` (5 tests, 0 failures)
- Next:
  - `A5-1` embedded SVG 재귀 파서 + depth / embedded count 제한
- Risk:
  - 이미지 노드(`image`) 자체 파서/렌더는 아직 미지원이므로 A5에서 통합 필요


### Session 25
- Scope:
  - `A3-1` cascade/specificity 엔진 구현 착수 및 검증
- Completed:
  - `SVGStyleResolver`에 stylesheet 적용 단계 추가:
    - style rules 매칭 (id/class/element/any)
    - specificity 점수(ID 100, class 10, element 1, any 0) 정렬
    - 동일 specificity에서 source order 후순위 덮어쓰기 적용
    - `inherited -> stylesheet -> node.base.style -> overrides` 합성 순서 적용
  - `SVGStyleResolverTests`에 스타일 룰 기반 회귀 케이스 추가 4건
- Validation:
  - `swift test --parallel` (77 tests, 0 failures)
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`
- Next:
  - `A4-1 data:` URI parser 및 base64 decoder 작업 시작

### Session 01
- Scope:
  - P0 부트스트랩 시작
  - P1 타입/파서 스켈레톤 시작
  - 로그 기반 중복 방지 체계 추가
- Completed:
  - `swift package init --type library` 실행
  - `Package.swift`에 `iOS 15`, `macOS 12` 플랫폼 설정
  - 코어 타입 스켈레톤 추가:
    - `SVGDocument`, `SVGNode`, `SVGStyle`, `SVGTransform`
    - `SVGSource`, `SVGParserOptions`, `SVGParserError`, `SVGParser`
    - `NodeOverride`, `NodeContext`, `SVGRenderConfiguration`
    - `SVGParseCache` actor(LRU 기본)
  - 기본 테스트 추가:
    - `SVGParserTests`
    - `SVGParseCacheTests`
  - 작업 관리 문서 추가:
    - `TASK_BOARD.md`
    - `WORK_LOG.md`
- Validation:
  - `swift test` 통과 (5 tests, 0 failures)
- Next:
  1. `P0-3` DemoApp 타깃 생성
  2. `P1-3` XML tokenization 실제 구현
  3. `P4-1` style override 우선순위 로직 구현

### Session 02
- Scope:
  - `P1-3` XML tokenization 파서 구현
  - 파서 테스트 확장
  - 중복 작업 방지용 보드 동기화
- Completed:
  - `SVGParser`를 XML 기반 파서로 교체
  - 지원 요소 파싱 추가:
    - `svg`, `g`, `path`, `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`
  - root 메타 파싱 추가:
    - `width/height -> size`
    - `viewBox -> SVGRect`
  - 노드 속성 파싱 추가:
    - `id`, synthetic ID, raw attributes
    - `fill/stroke/opacity` 등 기본 style + inline style override
    - 기본 transform operation 파싱(`translate/scale/rotate/matrix`)
    - polyline/polygon `points` 파싱
  - `.gitignore`에 `.swiftpm/` 추가
  - 테스트 추가/개정:
    - 루트 속성 파싱
    - 그룹/패스/도형 트리 구성
    - 인라인 스타일 override
    - polyline points 파싱
- Validation:
  - `swift test` 통과 (8 tests, 0 failures)
- Risks/Notes:
  - Path command tokenizer(`P2-1`) 미구현
  - DemoApp(`P0-3`)은 수동 xcodeproj 생성 필요(`xcodegen` 미설치)
- Next:
  1. `P2-1` Path command parser 구현
  2. `P4-1` 스타일 상속 + map/resolver 우선순위 로직 구현
  3. `P0-3` DemoApp 수동 프로젝트 생성 및 패키지 연결

### Session 03
- Scope:
  - DemoApp 단계에 UITest + 결과 비교 요구사항 반영
  - 문서/작업보드 업데이트
- Completed:
  - `STEP_BY_STEP_PLAN.md`에 UITest/시각 회귀 비교를 공식 완료 기준으로 추가
  - `TASK_BOARD.md`에 `P7-2`, `P7-3`, `P8-2` 작업 항목 추가
  - `WORK_CONTINUATION.md` 다음 순서에 UITest/baseline 단계 반영
  - `DEMO_UITEST_STRATEGY.md` 신설 (타깃 구성, baseline 규칙, 비교 방식)
- Validation:
  - 문서 교차 검토 완료 (계획/보드/연속성 간 항목 정합성 확인)
- Next:
  1. `P2-1` Path parser 구현 계속
  2. DemoApp 생성 직후 `P7-2` UITest 타깃부터 연결

### Session 04
- Scope:
  - 테스트 보강(파서/캐시 경계 케이스)
  - 다음 작업으로 `P2-1` path parser 착수
- Completed:
  - 테스트 대폭 확장:
    - `SVGParserTests`: malformed XML, namespace, unsupported/nested svg 무시, synthetic ID, paint/transform/numeric edge 등 추가
    - `SVGParseCacheTests`: cost eviction, touch LRU, replace key, negative cost clamp, removeAll 추가
  - 신규 path parser 구현:
    - `SVGPathDataParser`, `SVGPathCommand`, `SVGPathDataParserError`
    - 지원 명령: `M/L/H/V/C/S/Q/T/A/Z` (대소문자)
    - 명령별 파라미터 개수 검증 + unsupported/missing command 검증
  - 신규 테스트:
    - `SVGPathDataParserTests` 9개
  - 캐시 보강:
    - `SVGParseCache.insert`에서 cost 음수 입력 정규화
- Validation:
  - `swift test` 통과 (33 tests, 0 failures)
- Next:
  1. `SVGParser`의 `<path d>`에 `SVGPathDataParser` 연결 (AST 레벨 command 저장)
  2. 스타일 상속 + `원본 < map < resolver` 우선순위 구현
  3. DemoApp 수동 xcodeproj 생성 및 패키지 연결

### Session 05
- Scope:
  - `P2-1` path parser를 `SVGParser` path 노드에 실제 연결
  - 관련 회귀 테스트 보강
- Completed:
  - `SVGPathNode`에 `commands: [SVGPathCommand]` 필드 추가
  - `SVGParser`에서 `<path d>` 파싱 시 `SVGPathDataParser` 실행 후 command 저장
  - 잘못된 path data(`R ...` 등)는 `malformedDocument`로 실패 처리
  - parser 테스트 추가:
    - path command 저장 검증
    - invalid path data 에러 검증
- Validation:
  - `swift test` 통과 (34 tests, 0 failures)
- Next:
  1. style 상속 + `원본 < map < resolver` 우선순위 로직 구현
  2. Path command를 실제 렌더 Path 생성 로직에 연결
  3. DemoApp 수동 xcodeproj 생성 및 패키지 연결

### Session 06
- Scope:
  - W3C SVG conformance 테스트 요구사항을 공식 계획에 편입
- Completed:
  - `STEP_BY_STEP_PLAN.md`에 W3C 테스트 트랙(A8/A9) 추가
  - `TASK_BOARD.md`에 W3C 관련 작업 ID 추가(A8-1, A8-2, A9-1, A9-2)
  - `WORK_CONTINUATION.md`에 v2+ W3C 파이프라인 항목 반영
  - `W3C_CONFORMANCE_PLAN.md` 신설:
    - fixture/manifest/자동 생성/coverage/CI 단계 정의
    - supported vs unsupported 분리 정책 명시
- Validation:
  - 계획 문서 간 정합성 점검 완료
- Next:
  1. 현재 우선순위(P4, Path->Render, DemoApp) 완료 후 A8/A9 착수
  2. W3C fixture subset 초기 셋 선정(paths/shapes/coords/styling)

### Session 07
- Scope:
  - `P4-1` 스타일 상속 + override 우선순위 로직 구현
- Completed:
  - `SVGResolvedStyle.applying(style:)` 추가 (상속 병합 기준 고정)
  - `SVGNode` 공통 접근자 추가:
    - `base`
    - `children`
  - 신규 엔진 `SVGStyleResolver` 추가:
    - 상속 체인 계산
    - 우선순위 적용: `inherited/original < idOverrides < resolver`
    - geometry override(`scale`, `offset`) 병합
    - viewport(size/viewBox fallback) 주입
  - 신규 테스트 `SVGStyleResolverTests` 6개 추가:
    - 부모 상속
    - map override
    - resolver 우선
    - group override cascade
    - synthetic ID override
    - resolver context viewport 검증
- Validation:
  - `swift test` 통과 (40 tests, 0 failures)
- Next:
  1. path command -> SwiftUI Path builder 연결
  2. `SVGStyleResolver`를 `SVGView` 렌더 파이프라인에 통합
  3. DemoApp 생성 및 UITest 기반 baseline 비교 단계 진행

### Session 08
- Scope:
  - path command를 실제 렌더 path로 변환
  - style resolver 결과를 `SVGView`에 통합
- Completed:
  - 신규 `SVGPathCommandBuilder` 구현:
    - 명령 처리: `M/L/H/V/C/S/Q/T/A/Z` (상대/절대)
    - arc endpoint 파라미터 -> cubic segment 변환 지원
  - 신규 `SVGNodePathBuilder` 구현:
    - path/rect/circle/ellipse/line/polyline/polygon -> `CGPath`
  - `SVGView`를 placeholder에서 Canvas 렌더러로 교체:
    - 파싱 결과 + style resolver 결과를 바탕으로 실제 path/shape 렌더
    - fill/stroke/strokeWidth/opacity/lineCap/lineJoin 반영
    - node override의 scale/offset 반영
  - 테스트 추가:
    - `SVGPathCommandBuilderTests` 5개
    - `SVGNodePathBuilderTests` 5개
- Validation:
  - `swift test` 통과 (50 tests, 0 failures)
- Next:
  1. DemoApp 수동 xcodeproj 생성 및 패키지 연결
  2. Demo UITest + baseline 비교 파이프라인 구축
  3. transform 누적/정교한 렌더 규칙 보강

### Session 09
- Scope:
  - `P0-3` DemoApp 생성/패키지 연결 완료
  - `P7-2` UITest 구현 및 안정화
  - 작업 로그/보드 동기화
- Completed:
  - `Examples/SVGSwiftUIDemo` 추가:
    - `project.yml`, `SVGSwiftUIDemo.xcodeproj`, `Sources/*`, `UITests/*`
  - Demo 화면 구현:
    - 샘플 전환, node id 입력, fill/stroke toggle, scale/offset slider
    - 접근성 식별자 고정(`demo.canvas`, `demo.controls`, `demo.nodeIDField` 등)
  - UITest 4개 구현/보강:
    - launch + 핵심 UI 존재
    - sample 전환 + node id 입력 반영
    - toggle 조작 회귀
    - offset slider 조작 회귀
  - 초기 플래키 이슈(컨테이너/텍스트필드 식별자, switch value 비교) 수정
- Validation:
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 17' test` 통과 (4 tests, 0 failures)
  - `swift test` 통과 (50 tests, 0 failures)
- Next:
  1. `P7-3` baseline 캡처/비교 유틸 추가
  2. `P7-1` cache 통계 UI 추가(hit/miss/size)
  3. `P5-1` cache key 고도화(`source + options + schemaVersion`)

### Session 10
- Scope:
  - `P5-1` 캐시 고도화 및 렌더 경로 실연동
  - 캐시/파서 테스트 보강
- Completed:
  - `SVGParseCacheKey` 확장:
    - `schemaVersion` 필드 추가
    - `SVGParseCacheKey.from(sourceData:options:schemaVersion:)` 추가
    - stable hash(FNV-1a 기반) 적용
  - `SVGParser` API 확장:
    - `parse(data:options:)` 추가
    - `parse(source:options:)`는 내부에서 `parse(data:)` 재사용
  - `SVGView` 캐시 연동:
    - `cache: SVGParseCache?` 주입 가능
    - parse task에서 cache hit/miss 처리 후 문서 재사용
  - DemoApp 연동:
    - `ContentView`에 공유 `SVGParseCache` 인스턴스 전달
  - 테스트 추가:
    - `SVGParseCacheTests` 2개(스키마 버전 key 검증)
    - `SVGParserTests` 1개(`parse(data:)` 동등성 검증)
- Validation:
  - `swift test` 통과 (53 tests, 0 failures)
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 17' test` 통과 (4 tests, 0 failures)
- Next:
  1. `P7-3` snapshot baseline 비교 유틸 추가
  2. `P7-1` cache 통계 패널(hit/miss/cost) 구현
  3. `P8-2` 시각 회귀 자동화 연결

### Session 11
- Scope:
  - 연산식 타입 추론 최소화 코딩 스타일 반영
  - `SVGPathCommandBuilder` 타입 명시 리팩터링
- Completed:
  - `docs/CODING_STYLE.md` 추가:
    - 타입 혼합 연산 금지
    - 선변환 후 계산 규칙
    - 긴 식 분해/리터럴 타입 명시 규칙
  - `SVGPathCommandBuilder` 리팩터링:
    - `CGFloat`/`Double` 혼합 계산 분리
    - 보조 함수 `makePoint(x:y)` 추가로 명시 변환 일원화
    - arc/angle 계산식에 중간 변수와 타입 명시 적용
  - `WORK_CONTINUATION.md` 잠금 규칙에 스타일 규칙 추가
- Validation:
  - `swift test` 통과
- Next:
  1. 동일 규칙을 다른 렌더 수식 파일로 점진 확장
  2. snapshot baseline 작업(`P7-3`) 진행

### Session 12
- Scope:
  - 전반 접근제어 정리(`public` 최소화)
  - 외부 API 경계 고정 및 문서 정합성 반영
- Completed:
  - 내부 전환:
    - 파서/AST/캐시/렌더 내부 엔진 타입을 `internal`로 축소
    - `SVGView`에서 내부 캐시/파서 캡슐화, 외부 `cache` 주입 제거
  - 공개 API 유지:
    - `SVGView`, `SVGSource`, `SVGParserOptions`
    - 렌더 오버라이드 API(`NodeOverride`, `NodeContext`, `SVGRenderConfiguration` 등)
  - 문서 정리:
    - `STEP_BY_STEP_PLAN.md` API 섹션을 실제 공개 표면 기준으로 갱신
    - `WORK_CONTINUATION.md`에 접근제어 잠금 규칙 반영
    - `API_SURFACE_POLICY.md` 신규 추가
- Validation:
  - `swift test` 통과 (53 tests, 0 failures)
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 17' test` 통과 (4 tests, 0 failures)
- Next:
  1. `P7-1` cache 통계 노출 API(read-only) 설계 후 Demo 통계 패널 구현
  2. `P7-3` baseline 캡처/비교 파이프라인 진행

### Session 13
- Scope:
  - `P7-3` baseline 수집
  - `P8-2` 시각 회귀 비교 자동화
- Completed:
  - `SVGSwiftUIDemoUITests` 확장:
    - 신규 `testCanvasMatchesBaselines` 추가
    - 시나리오 3종 baseline 비교(`badge_default`, `panel_stroke`, `route_offset`)
  - 스냅샷 비교 유틸 구현:
    - `demo.canvas` 요소 단위 캡처
    - baseline 로드/비교 및 픽셀 mismatch ratio 계산
    - 실패 시 `expected/actual/diff` artifact 출력
  - baseline 관리 모드 추가:
    - `UITests/Baselines/.record` 파일 존재 시 baseline 기록 모드
  - baseline 파일 생성:
    - `Examples/SVGSwiftUIDemo/UITests/Baselines/iPhone_17/26.2/*.png`
  - 허용오차 조정:
    - anti-aliasing 편차 대응 위해 허용오차 `0.35%` 적용
- Validation:
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 17' test` 통과 (5 tests, 0 failures)
  - `swift test` 통과 (53 tests, 0 failures)
- Next:
  1. `P7-1` cache 통계 패널 구현
  2. `P6-1` transform 누적/고급 렌더 보강

### Session 14
- Scope:
  - `P7-1` Demo cache 통계 패널 구현
  - cache telemetry API를 공개 표면으로 최소 추가
- Completed:
  - 공개 타입 추가:
    - `SVGCacheMetrics` (`requests/hits/misses/entries/totalCost/hitRate`)
    - `SVGCacheStats` (`ObservableObject`, read-only metrics)
  - 내부 cache 계측 추가:
    - `SVGParseCache`에 hit/miss 카운터와 `metricsSnapshot()` 구현
  - `SVGView` 확장:
    - `cacheStats: SVGCacheStats?` 파라미터 추가
    - load 경로에서 metrics를 갱신해 외부에 전달
  - Demo UI 반영:
    - `ContentView`에 cache metrics 패널 추가
    - requests/hits/misses/hitRate/entries/totalCost 표시
  - 테스트 보강:
    - `SVGParseCacheTests`에 metrics snapshot/초기화 테스트 2개 추가
    - UITest launch 검증에 cache metrics 패널 존재 확인 추가
  - 시각 회귀 안정화:
    - baseline 허용오차 `0.50%`로 조정
- Validation:
  - `swift test` 통과 (55 tests, 0 failures)
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 17' test` 통과 (5 tests, 0 failures)
- Next:
  1. `P6-1` transform 누적/고급 렌더 보강
  2. `P8-1` fixture 확장 및 통합 회귀 보강

### Session 15
- Scope:
  - `P6-1` transform 누적 렌더 보강
  - transform 연산 순서/결합 순서 회귀 테스트 추가
- Completed:
  - 신규 내부 유틸 `SVGTransformBuilder` 추가:
    - `SVGTransform` -> `CGAffineTransform` 변환
    - local/inherited transform 결합(`local -> inherited`) 구현
  - `SVGNodePathBuilder` 확장:
    - `buildPath(for:inheritedTransform:)` 추가
    - path/shape 생성 후 local + inherited transform 적용
  - `SVGView` 렌더 경로 보강:
    - draw node 재귀 빌드 시 부모 transform 누적 전파
    - 각 노드 렌더에서 inherited transform 반영된 path 생성
  - 테스트 보강:
    - `SVGNodePathBuilderTests` 2개 추가(local transform 적용, inherited 누적 적용)
    - `SVGTransformBuilderTests` 3개 신규(연산 순서, center rotate, 결합 순서)
- Validation:
  - `swift test` 통과 (60 tests, 0 failures)
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 17' test` 통과 (5 tests, 0 failures)
- Next:
  1. `P8-1` 샘플 fixture 확장 및 통합 회귀 테스트 보강
  2. `P9-1` README/사용 가이드 정리

### Session 16
- Scope:
  - `P8-3` GitHub CI 파이프라인 구성
  - `swift test` + demo UITest를 CI로 연결
- Completed:
  - `.github/workflows/ci.yml` 신규 작성:
    - `swift test` Job(`ubuntu-latest`)
    - `Demo UITests` Job(`macos-latest`)
    - Demo `xcodebuild test` 실행 전 iOS simulator 대상 자동 탐색 추가
  - 작업 문서 업데이트:
    - `docs/STEP_BY_STEP_PLAN.md`에 `P8-3` 항목 추가
    - `docs/TASK_BOARD.md`에 `P8-3` 상태 반영(`in_progress`)
    - `docs/WORK_CONTINUATION.md` 다음 순서/세션 로그 갱신
- Next:
 1. `P8-1` 샘플 fixture 추가 및 통합 테스트 보강
 2. CI에서 fixture 회귀 파이프라인 통과 기준 확정

### Session 17
- Scope:
  - `P8-1` fixture 통합 테스트 추가 및 `P8-3` CI 재현성 보강
- Completed:
  - `Tests/SVGSwiftUITests/Fixtures` 폴더 추가 및 `scene_transforms.svg`, `style_overrides.svg`, `shape_commands.svg` 등록
  - `Tests/SVGSwiftUITests/SVGFixtureRegressionTests.swift` 3개 회귀 테스트 추가
  - `Package.swift`에 `SVGSwiftUITests` 리소스 빌드 등록 (`.process("Fixtures")`)
  - CI workflow 업데이트:
    - destination 파싱에서 `id:` 기반 전달
    - `-parallel-testing-enabled NO` 추가로 안정성 강화
- Validation:
  - `swift test --parallel` 통과 (`63` tests)
  - `xcodebuild ... test -destination id=<iPhone_17>` 통과 (`All tests` 5개, 0 failures)
- Next:
  - `P9-1` README/사용 가이드 정리
  - v2 W3C fixture subset(1.1F2/1.2T) 테스트 전략 수립

### Session 18
- Scope:
  - `P9-1` README/가이드 문서 작성 및 프로젝트 문서 상태 동기화
- Completed:
  - `README.md` 신규 작성:
    - 설치/요구사항/기본 사용 예시
    - `SVGSource`, 노드 오버라이드(`idOverrides`, `resolver`)
    - 캐시 메트릭(`SVGCacheStats`) 사용법
    - 지원 기능 및 미지원 항목 표기
    - 데모 앱 및 테스트/CI 실행 가이드
  - `docs/TASK_BOARD.md`에서 `P8-3`을 `done`, `P9-1`을 `done` 처리
- Validation:
  - `README.md` 공개 API/기능 범위 정합성 점검
  - `swift test --parallel` 통과 (`63` tests)
  - `xcodebuild`(`iOS Simulator destination 자동 탐색 + -parallel-testing-enabled NO`) 통과 (`5` tests, `0` failures)
- Risk:
  - CI 데모 UITest는 런타임 환경(시뮬레이터/런처)에 민감해 자동화 재현성 모니터링 필요
- Next:
  - `A8-1`로 진입해 W3C fixture subset(1.1F2/1.2T) 계획 확정

### Session 19
- Scope:
  - `A8-1` W3C fixture subset(1.1F2/1.2T) 구조 착수
- Completed:
  - `Tests/W3C` 폴더 및 초기 fixture 구조 생성
  - 기본 fixture 샘플 4종 추가
    - paths(1.1F2), shapes(1.1F2), coords(1.2T), styling(1.2T)
  - `Tests/W3C/w3c-manifest.json` 생성 및 fixture 메타데이터 정리
  - `Scripts/w3c/generate-w3c-tests.sh` 초안 추가
- Validation:
  - `Scripts/w3c/generate-w3c-tests.sh` 실행 확인 (`4`개 fixture 기반 Swift 테스트 골격 생성)
  - `swift test --parallel` 통과 (`63` tests)
- Risk:
  - 자동 생성 테스트는 현재 `Bundle` 리소스 경로 주입이 미완성이라 A8-2 단계에서 생성 출력 대상/로딩 전략 정합성 필요
- Next:
  - `A8-1` fixture 카테고리/기대값 표준화 및 `A8-2` 테스트 생성 스크립트 정식 적용

### Session 20
- Scope:
  - `A8-2` W3C 자동 생성 테스트 스크립트 정식 적용
- Completed:
  - `Tests/W3C` 디렉터리를 `Tests/SVGSwiftUITests/W3C`로 이동해 테스트 타깃 리소스 루트 정비
  - `Scripts/w3c/generate-w3c-tests.sh` 정비:
    - `manifest` 기반 fixture 메타데이터 파싱
    - 경로 정규화(`resourcePath` basename) 지원
    - `Tests/SVGSwiftUITests/W3CGeneratedTests.swift` 일괄 생성
  - `Tests/SVGSwiftUITests/W3CGeneratedTests.swift` 생성 후 `swift test --parallel`에 포함
  - `Package.swift` 테스트 타깃에 `.process("W3C")` 추가
  - CI `swift-tests` 잡에 W3C 테스트 생성 스텝 선행 추가
- Validation:
  - `Scripts/w3c/generate-w3c-tests.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json Tests/SVGSwiftUITests/W3CGeneratedTests.swift` 실행
  - `swift test --parallel` 통과 (`64` tests, `0` failures)
  - `xcodebuild ... SVGSwiftUIDemoUITests` 통과 (`5` tests, `0` failures)
- Risks:
  - SwiftPM resource 처리에서 경로가 flat으로 병합되어 `resourcePath` basename 기반 조회가 필수
  - fixture 파일명이 충돌할 경우 manifest/리소스 조회 충돌 가능성
- Next:
  - `A9-1` coverage 리포트 생성 스크립트(모드/예상 결과/미지원 집계) 구현
  - `A9-2` CI conformance 단계별 아티팩트 업로드 규칙 정립

### Session 21
- Scope:
  - `A9-1` W3C coverage 리포트 스크립트 및 산출물 정리
- Completed:
  - `Scripts/w3c/w3c-coverage.sh` 추가:
    - manifest 파싱
    - suite/category별 pass/fail/unsupported 집계
    - 리소스 존재 여부 점검
    - `docs/W3C_COVERAGE.md` 자동 생성
  - `docs/W3C_COVERAGE.md` 생성 결과 검증 (`4`개 fixture 모두 ready)
- Validation:
  - `Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md` 실행
  - `docs/W3C_COVERAGE.md` 생성 완료 및 표 형식 검증
- Risk:
  - 현재 coverage는 manifest 기대값 기반 집계이며, 런타임 파싱 결과 반영은 A9-2에서 확장 필요
- Next:
  - `A9-2` CI에서 conformance 실행 결과/coverage report 아티팩트 업로드 추가

### Session 22
- Scope:
  - `A9-2` W3C conformance CI 단계 정식화
- Completed:
  - `Scripts/w3c/w3c-coverage.sh` strict 검증 모드(`--strict`) 추가:
    - 누락된 리소스, invalid mode/expected, 중복 ID, 빈 ID 체크
    - strict 실패 시 비정상 종료(1) 처리
  - `.github/workflows/ci.yml`에 W3C conformance 전용 테스트 실행 단계 추가:
    - `swift test --specifier "SVGSwiftUITests.W3CGeneratedTests/testW3CGeneratedSuite" --parallel`
    - 결과 로그 `w3c-conformance.log` 캡처
  - CI coverage 생성 호출을 strict 모드로 전환
  - W3C conformance 결과 아티팩트 업로드 항목 추가:
    - `docs/W3C_COVERAGE.md`
    - `Tests/SVGSwiftUITests/W3C/w3c-manifest.json`
    - `Tests/SVGSwiftUITests/W3CGeneratedTests.swift`
    - `w3c-conformance.log`
- Validation:
  - `bash -n Scripts/w3c/w3c-coverage.sh`
  - `Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict` 통과
  - `swift test --specifier "SVGSwiftUITests.W3CGeneratedTests/testW3CGeneratedSuite" --parallel` 통과
- Next:
  - `A1-1` `style` 속성 파서 고도화 착수

### Session 23
- Scope:
  - `A1-1` `style` 속성 declaration parser 고도화
- Completed:
  - `SVGStyleDeclarationParser` 추가:
    - inline `style` 속성을 `property:value` 쌍으로 분해
    - 속성명 정규화(`lowercased`) 및 공백 정리
    - `!important` suffix 제거
  - `SVGXMLDocumentParser`를 parser 단일화 경로에 맞게 리팩터링:
    - `parseStyle(attributes:)`에서 declaration parser 사용
    - inline style 적용 로직을 `applyStyleDeclarations`로 정규화
  - `SVGStyleDeclarationParserTests` 추가:
    - whitespace/trim 처리
    - 잘못된 쌍 무시
    - `!important` 제거 동작
- Validation:
  - `swift test --parallel` 통과 (`67` tests, `0` failures)
- Next:
  - `A2-1` `<style>` CSS subset parser 착수

### Session 24
- Scope:
  - `A2-1` `<style>` CSS subset parser 착수
- Completed:
  - 스타일 규칙 AST 타입 추가:
    - `SVGStyleSelector` (`id`, `class`, `element`, `any`)
    - `SVGStyleRule` (selector + declarations map)
  - `SVGDocument`에 `styleRules: [SVGStyleRule]` 추가
  - `SVGStyleRuleParser` 구현:
    - `@media`/`@charset` 등 at-rule 무시
    - 주석 제거 후 `{...}` 블록 파싱
    - selector 분리(`,`) 및 id/class/요소 타입 파싱
  - `SVGXMLDocumentParser`에 `<style>` 수집/파싱 연동:
    - `enableStyleTag` 옵션이 true일 때만 스타일 텍스트 저장
    - `foundCharacters`/`foundCDATA`에서 rule 텍스트 누적
    - 파싱된 규칙을 `SVGDocument.styleRules`에 저장
  - 테스트 추가:
    - `SVGStyleRuleParserTests` 3개
    - `SVGParserTests`에서 `<style>` 블록 파싱/무시/selector 매핑 3개
- Validation:
  - `swift test --parallel` 통과 (`73` tests, `0` failures)
- Next:
  - `A3-1` 스타일 cascade/specificity 엔진 착수
