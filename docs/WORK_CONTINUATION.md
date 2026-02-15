# 작업 연속성 문서

## 현재 상태 (2026-02-16)
- 저장소 상태: Swift Package + DemoApp(`Examples/SVGSwiftUIDemo`) 생성 완료
- 계획 문서: `/Users/minsone/Developer/SVGSwiftUI/docs/STEP_BY_STEP_PLAN.md`
- 구현 상태: P0/P1/P2/P3/P4/P5/P6/P7-1 완료, P8 파이프라인/회귀 검증 완료, P9-1 문서 정리 완료, A10-3 완료, A11-2 완료, A12 완료, A13-1 완료, A13-2 완료, A14-1/A14-2/A14-3 완료, A15-1/A15-2 완료, A16-1 완료, A16-2 완료
- 다음 단계: `A16-3` 진행 (`feComposite` 경계/시각 회귀 확장)
- API 상태: 공개 표면 최소화 적용 완료(파서/AST/캐시/렌더 내부 엔진은 `internal`)
- 안정화 상태: v2 고급 기능(A1~A9) 동작 검증 및 CI/문서 정합성 동기화 완료(운영 단계로 이동), `S2-2` 완료, `S3-1` 완료, `A11-2` 완료

## 잠금된 의사결정
- 대상 플랫폼: iOS 15+
- 기본 렌더 방식: SwiftUI `Path`
- 기본 업데이트 방식: 상태 기반 갱신(필요 시에만 `TimelineView`)
- 노드 제어: `NodeID map` 기본 + 선택적 closure
- 캐시: 파싱 결과(AST) 전용
- v2 확장: style/CSS subset + base64 `data:` URI
- DemoApp 단계에서 UITest + 기준 이미지 비교를 포함
- v2+ 확장: W3C SVG conformance 테스트(coverage 리포트 포함) 도입
- 연산식 코딩 규칙: 타입 혼합 연산 금지, 선변환 후 계산(`docs/CODING_STYLE.md`)
- 접근제어 규칙: 기본 `internal`, 외부 계약(API)으로 필요한 심볼만 `public` (`docs/API_SURFACE_POLICY.md`)

## 바로 다음 실행 순서
1. `A16-3` `feComposite` 경계 및 `unsupported` fallback 조합 2~3건 추가

## 작업 진행 루프(재작업 방지)
- Task 시작 시 `TASK_BOARD` 상태를 `in_progress`로 전환
- 구현 후 `WORK_LOG.md`에 검증/리스크를 즉시 기록
- 테스트/검증을 통과하면 변경사항을 정리해 `git add`/`git commit` 진행
- 커밋 메시지에 세션 번호, 처리 Task, 변경 범위를 반영
- 커밋 후 `git push`로 원격 저장소 동기화
- 다음 작업 전 `TASK_BOARD`, `WORK_CONTINUATION`, `STEP_BY_STEP_PLAN`의 상태를 동기화

## 체크리스트 (진행 시 갱신)
- [x] P0 부트스트랩 완료
- [x] P1 모델/파서 골격 완료 (XML tokenization 포함)
- [x] P2 Path 파서 완료
- [x] P3 도형 파서 완료
- [x] P4 스타일/노드 제어 완료
- [x] P5 캐시 완료
- [x] P6 렌더러 완료
- [x] P7 Demo 앱 완료
- [x] P8 테스트 강화 완료
- [x] P9 문서화 완료
- [x] A8-1 W3C fixture subset 기초 골격
- [x] A8-2 W3C 자동 생성 테스트 적용
- [x] A9-1 W3C coverage 리포트 스크립트 산출
- [x] A9-2 W3C conformance CI 단계 및 strict artifact 업로드
- [x] S1-1 렌더 path 캐시(prebuild)로 프레임별 재빌드 비용 감소
- [x] S2-1 고급 렌더 후보 분석 문서화 (`clipPath/mask/filter`)
- [x] A1-1 `style` 속성 parser 고도화
- [x] A2-1 `<style>` CSS subset parser
- [x] A3-1 cascade/specificity engine
- [x] A4-1 `data:` URI parser/base64 decoder
- [x] A5-1 embedded SVG 재귀 제한 처리(depth/count)
- [x] A6-1 raster 정책
- [x] A7-1 cache key versioning
- [x] A10-1 WebKit LayoutTests 동기화/매니페스트 정리
- [x] A10-2 WebKit conformance suite/coverage 정합성 검증
- [x] A10-3 WebKit 후보군 확장 및 unsupported 정책 정리
- [x] S2-2 `clipPath` 미니멈 구현
- [x] S3-1 렌더 경로 캐시 및 대형 SVG 임계치 정리
- [x] S3-2 `S3-1` 실측 근거 수집 및 임계치 보강 근거화
- [x] A11-1 `filter` 정의 파싱/스타일 전달 기초
- [x] A11-2 `filter` 렌더 패스 연동
- [x] A12 `filter` 고급 primitive 분류 정책 정리
- [x] A13-1 `feBlend`/`feColorMatrix` 지원으로 분류/렌더 경로 확장
- [x] A13-2 WebKit/W3C conformance 수치 및 fixture 정렬
- [x] A14-1 `in`/`in2`/`result` 파싱/저장 보강
- [x] A14-2 체인 렌더 가드 적용
- [x] A14-3 chain 회귀 검증 강화
- [x] A15-1 필터 체인 실행 그래프 추상화 적용
- [x] A15-2 오프스크린 블렌드/컬러매트릭스 정밀도 보강
- [x] A16-1 `feComposite` 지원
- [x] A16-2 `feComposite` arithmetic 지원

### 2026-02-16 (Session 48)
- 작업: `A14-1/A14-2` filter 체인 메타데이터 파싱 + 렌더 체인 가드 구현
- 완료:
  - `SVGFilterPrimitive`에 `in`/`in2`/`result`를 반영한 채 필터 파싱 경로 기본값(`in`=`SourceGraphic`) 적용
  - `SVGView`에서 `applyFilterPrimitives`를 체인 소스 가용성(`SourceGraphic`, `SourceAlpha`, `result`) 중심으로 개선
  - 기존 filter 회귀 45개 케이스에 `in`/`in2`/`result` 반영 검증 테스트 추가
- 리스크:
  - `blend`/`colorMatrix`는 현재 `Color` 렌더 체인으로 완전 복원되지 않아 시각 정확도 제한
  - 지원되지 않는 primitive가 결과를 생성한 경우 체인 추적 시 시각적 누락 가능
- 다음 액션:
  - `A14-3`로 WebKit/W3C의 `in`/`result` 체인 기반 fixture를 선별 추가하고 coverage 정책 정리
- 검증:
  - `swift test --no-parallel` (135 tests, 0 failures)
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict`

### 2026-02-16 (Session 49)
- 작업: `A14-3` filter chain 회귀 테스트 강화
- 완료:
  - W3C chain fixture(`w3c-1.1F2-filters-chain-01-b-min`) 추가 및 reference metadata 정렬
  - WebKit chain fixture(`webkit-filters-chain-01-b.svg`) 추가 및 WebKit manifest 등록
  - `testParseReadsFilterChainSourcesWithWhitespaceTrimmed`/`testParseRetainsChainResultNamesForRendererInputs` 추가
  - W3C/WebKit generated tests 및 coverage 문서 재생성
- 리스크:
  - conformance suite는 parse 기반이므로 체인 시각 일치성까지는 검증되지 않음
  - `SourceAlpha` 소스 경로는 현재 파서 메타데이터/가드 동작 관점에서만 보장되며 blend 결과 합성의 완전성은 추후 과제
- 검증:
  - `swift test --no-parallel` (137 tests, 0 failures)
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict`

### 2026-02-16 (Session 50)
- 작업: `A15-1` 필터 체인 실행 그래프 분리
- 완료:
  - `SVGFilterGraphExecutor` 추가: `canExecute`/`requiredSourceNames`/`resolvedResultName`를 중앙화
  - `SVGView.applyFilterPrimitives`가 공용 executor를 통해 source/result 정책을 동일하게 적용
  - `SVGFilterGraphExecutionTests` 추가로 필터 체인 실행 규칙 단위 검증
- 리스크:
  - `feBlend`/`feColorMatrix`의 픽셀 합성 정밀도는 여전히 기존 `GraphicsContext` 경로로만 처리됨
- 다음 액션:
  - `A15-2`에서 오프스크린 합성 그래프를 도입해 `blend`/`colorMatrix` 정확도 강화
- 검증:
  - `swift test --no-parallel` (138 tests, 0 failures)

### 2026-02-16 (Session 51)
- 작업: `A15-1` 후속 안정화 (오프스크린 체인 실결합 버그 수정)
- 완료:
  - `CIAffineTransform` 적용에서 `CIVector(cgAffineTransform:)` 대신 `CGAffineTransform` 직접 전달로 변경
  - `result` 지정 `offset` + 후속 `colorMatrix` 체인에서 `Source` 보존이 정상적으로 되는지 회귀 테스트 추가/통과
  - 임시 디버그 테스트는 삭제하고 디버그 로그를 제거해 깨끗한 테스트 집합으로 정리
- 리스크:
  - 현재는 `feBlend`는 오프스크린 합성 경로에서 일부 BlendMode만 지원되어, 일부 blend 모드의 정밀도는 A15-2에서 강화 필요
  - 오프스크린 렌더는 여전히 `SourceAlpha` 경로를 포함한 정밀한 사전 처리 여지가 남아 있음
- 다음 액션:
  - `A15-2`: `blend`/`colorMatrix` 오프스크린 경로 정합성 강화를 위한 픽셀 비교 중심 테스트 확장
- 검증:
  - `swift test --filter SVGFilterImageRendererTests --no-parallel`
  - `swift test --no-parallel`

### 2026-02-16 (Session 53)
- 작업: `A16-1` `feComposite` 지원
- 완료:
  - `SVGFilterPrimitive`에 `.composite` 케이스를 추가해 `operator`, `in`, `in2`, `k1~k4`, `result`를 모델링
  - `SVGParser`에서 `feComposite` 파서 및 속성 기본값(`operator=over`) 처리 추가
  - `SVGFilterGraphExecutor`에 `requiredSourceNames`/`resolvedResultName` 규칙을 중앙화
  - 오프스크린 `SVGFilterImageRenderer`에 `feComposite` 정합도 경로 추가(`over/in/out/atop/xor/lighter` 등 매핑)
  - 체인/파서/렌더 테스트를 3개 추가
- 리스크:
  - `arithmetic` 모드(`k1~k4`)는 현재 `CISourceOverCompositing` 폴백 처리되어 수식 기반 합성은 미지원
- 다음 액션:
  - `A16-2`: `feComposite` arithmetic 모드 정확도 지원 또는 대체 정책 정리 후 fixture로 정합도 보강
- 검증:
  - `swift test --filter testParseTracksSupportedCompositePrimitive --no-parallel`
  - `swift test --filter testFilterGraphCanExecuteCompositePrimitiveWithResult --no-parallel`
  - `swift test --filter testRenderFilteredImageAppliesCompositeInOperator --no-parallel`
  - `swift test --filter testRequiresOffscreenProcessingForCompositePrimitive --no-parallel`
  - `swift test --no-parallel`

### 2026-02-16 (Session 54)
- 작업: `A16-2` `feComposite arithmetic` 지원
- 완료:
  - `arithmetic` 모드에 대해 `CIColorKernel` 계산식(`k1*in*in2 + k2*in + k3*in2 + k4`)을 정밀 적용
  - `compositeFilterName`에서 `arithmetic` 분기 처리해 기존 `CISourceOverCompositing` 폴백 경로와 분리
  - 파서/체인 실행/렌더 테스트에 `arithmetic` 회귀 케이스 추가
- 리스크:
  - `arithmetic` 계산식이 미리곱/클램핑 방식으로 구현되어 `feComposite`의 일부 엔진별 엣지 케이스와 수치 오차 가능성 잔류
- 다음 액션:
  - `WebKit`/`W3C` 후보군에서 `feComposite` `arithmetic` 샘플 fixture를 수집해 시각 회귀 체크 대상 반영
- 검증:
  - `swift test --filter testParseTracksCompositeArithmeticPrimitive --no-parallel`
  - `swift test --filter testFilterGraphCanExecuteArithmeticCompositePrimitiveWithResult --no-parallel`
  - `swift test --filter testRenderFilteredImageAppliesCompositeArithmeticOperator --no-parallel`
  - `swift test --no-parallel`

### 2026-02-16 (Session 55)
- 작업: `A16-2` conformance fixture 확장
- 완료:
  - W3C arithmetic fixture 1건 추가 및 reference 메타데이터 정렬
  - WebKit `filters-composite-02-b` fixture 수집/동기화 및 expected 분류(unsupported) 반영
  - W3C/WebKit generated suite 재생성 및 coverage 문서 strict 재생성
- 리스크:
  - `arithmetic` 시각 정합성은 `unsupported` 경로의 경계 사례가 있어 fixture 종류별 분류 정책을 계속 정교화해야 함
- 다음 액션:
  - `A16-3`에서 `in`/`in2` 기본/비정상 조합과 fallback 동작을 fixture로 정량화
- 검증:
  - `swift test --filter testW3CGeneratedSuite --filter testWebKitGeneratedSuite --no-parallel`
  - `swift test --filter testParseTracksCompositeArithmeticPrimitive --filter testFilterGraphCanExecuteArithmeticCompositePrimitiveWithResult --filter testRenderFilteredImageAppliesCompositeArithmeticOperator --no-parallel`
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict`

## 구현 중 준수 규칙
- 파서/모델 계층은 UI 타입(`Color`) 의존을 피하고 값 타입 중심으로 유지
- override 우선순위는 항상 `원본 < map < resolver`
- 캐시 키는 입력 + 파서 옵션 + 스키마 버전을 모두 포함
- 미지원 SVG 기능은 크래시 없이 무시하고 진단 로그 남김

## 세션 로그 템플릿
### YYYY-MM-DD
- 작업:
- 결정:
- 리스크:
- 다음 액션:

### 2026-02-15 (Session 44)
- 작업: `A11-2 filter` 렌더 패스 연동
- 완료:
  - `<filter>` 프레임에서 `feGaussianBlur`/`feOffset` 파싱을 AST에 축적해 `SVGFilterDefinition.primitives`로 전달
  - `filter` 참조 문자열에서 `url(#id)`를 역참조해 `GraphicsContext` 렌더 노드에 primitive 목록 적용
  - `SVGView`에 `GraphicsContext.drawLayer`를 통한 blur/offset 최소 구현 반영 (`max(stdDeviationX,stdDeviationY)` blur 반경, 오프셋 translate)
  - `SVGParserTests`에 단일 stdDeviation + 미지원 primitive 무시 케이스 추가
  - `SVGStyleResolverTests`에 stylesheet 필터 규칙 반영 테스트 추가
- 리스크:
  - blur/offset 이외 `filter` 기능(merge/comp/colormatrix 등)은 미지원 상태로, 지원 범위/예상치 정책 미정의
  - 렌더 합성의 정밀도는 iOS simulator에서 확인되었으며 W3C/WebKit 고급 filter fixture에 대한 회귀 데이터는 추가 필요
- 다음 액션:
  - `filter` 미지원 항목의 기대값을 conformance manifest에 `unsupported`로 정리하고, 지원 범위 커버리지 문서에 반영
- 검증:
  - `swift test --filter SVGParserTests --no-parallel` (132 tests, 0 failures)
  - `swift test --parallel` (132 tests, 0 failures)
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination id=CA606231-D9E3-453A-83EB-930148F67AED -parallel-testing-enabled NO test`

### 2026-02-15 (Session 41)
- 작업: `S3-2` 성능 실측 근거 수집
- 완료:
  - `SVGRenderPerformanceProfileTests` 3개 시나리오 추가 (2000/2001 nodes, 300000/300001 bytes)
  - `Scripts/performance/run-s3-profile.sh` 추가 및 `s3-profile.log` 산출 경로 연결
  - CI에 S3 프로파일 스텝/아티팩트 업로드 단계 추가
  - `docs/S3_PERFORMANCE_TUNING.md`에 성능 프로파일 기준 수집 항목 추가
- 리스크:
  - `measure` 값은 CI 머신/부하에 따라 흔들릴 수 있어 임계치 고정치 결정 전 오프라인 비교 필요
- 다음 액션:
  - 측정 로그(`s3-profile.log`) 기반으로 `S3_PERFORMANCE_TUNING.md`에 운영 기준(평균 반복 수, 허용 편차)을 고정
- 검증:
  - `swift test --filter SVGRenderPerformanceProfileTests --no-parallel`
  - `./Scripts/performance/run-s3-profile.sh`
  - `swift test --parallel` (126 tests, 0 failures)
  - `swift test --filter testW3CGeneratedSuite --no-parallel` (pass)
  - `swift test --filter testWebKitGeneratedSuite --no-parallel` (pass)

### 2026-02-15 (Session 40)
- 작업: `S3-1` 경계값 재점검(정합성 보강)
- 완료:
  - `SVGRenderCachePolicy` 임계치 테스트를 `nodeCount == 2000`, `sourceBytes == 300_000` 경계까지 확장
  - `swift test --filter SVGRenderCachePolicyTests --parallel` 재실행(통과)
  - `swift test --parallel`(123) 및 W3C/WebKit conformance 단계 재확인
- 리스크:
  - 임계값 바로 위/아래 경계 구간은 런타임 프로파일 데이터가 없어 성능 정합성 추적 필요
- 다음 액션:
  - 대표 대형 SVG 기준 실측 프로파일을 수집해 임계값 조정 근거화
- 검증:
  - `swift test --filter SVGRenderCachePolicyTests --parallel`
  - `swift test --parallel` (123 tests, 0 failures)
  - `swift test --filter testW3CGeneratedSuite --no-parallel` (pass)
  - `swift test --filter testWebKitGeneratedSuite --no-parallel` (pass)

### 2026-02-15 (Session 38)
- 작업: `S3-1` render 캐시 기반 성능 개선 착수
- 완료:
  - `SVGStaticPlaceholderView`에 렌더 구성 캐시 키(`SVGRenderConfigurationSignature`) 도입
  - `resolver` 없는 정적 구성에서 `drawNodes` 계산 결과를 캐시해 반복 resolve/트리 순회 제거
  - `drawNodes` 캐시 적중 기준(`idOverrides` 정렬 키 + `resolver` 존재 여부) 반영
  - 리로드 경로에서 캐시 상태 정합성(`cachedConfigurationFingerprint`, `cachedDrawNodes`) 정리
  - 설정 캐시 키 안정성 단위 테스트 3건 추가
- 리스크:
  - `resolver`는 클로저 정체성 추적이 어려워 캐시 키에 존재 여부만 반영되어 resolver 동적 교체에 민감할 수 있음
  - 대형 SVG 메모리 임계값(`drawNodes` 적재 정책)은 이번 1차 단계에서 미반영
- 결정:
  - 동적 `resolver` 구성은 안정성 우선으로 매 렌더 단계 실시간 계산 유지
  - S3-1의 다음 단계에서 임계값과 메모리 게이트를 문서화
- 검증:
  - `swift test --parallel`
  - `swift test --filter SVGRenderConfigurationSignatureTests`
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`

### 2026-02-15 (Session 36)
- 작업: `A10-3` 후보군 확장 완료 및 테스트 산출물 재생성
- 완료:
  - `Tests/SVGSwiftUITests/WebKit/webkit-manifest.json`에 unsupported 후보 12건(`text`, `filter`, `mask`, `marker`, `image`) 추가
  - `./Scripts/webkit/fetch-layout-tests.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json Tests/SVGSwiftUITests/WebKit/fixtures` 재실행
  - `./Scripts/webkit/generate-webkit-tests.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json Tests/SVGSwiftUITests/WebKitGeneratedTests.swift` 재생성
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict` 재생성
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict` 실행
- 결정:
  - `A10-3`를 완료 처리하고 다음 단계인 `S2-2`(clipPath 최소 구현)로 전환
- 리스크:
  - `unsupported` 항목은 파싱 신호만 추적되며 렌더 경로 완전 지원은 다음 단계에서 분리 검증 필요
- 다음 액션:
  - `S2-2`: `url(#id)` 기준 `clipPath` 최소 렌더 경로 설계 및 테스트
- 검증:
  - `swift test --parallel` (106 tests, 0 failures)
  - `swift test --filter testWebKitGeneratedSuite --no-parallel` (pass)

### 2026-02-15 (Session 37)
- 작업: `S2-2` clipPath 최소 구현 마무리
- 완료:
  - `SVGXMLDocumentParser`에서 `<clipPath>` 정의를 수집해 `SVGDocument.clipPaths` 전달
  - `SVGView`에 `clipPath` 참조 해석 및 `GraphicsContext` 클리핑 적용
  - `SVGParser` 내 파싱 결과 전파 검증(클립 경로 캐시/구조 전달 일관성)
  - 인라인 스타일 `style=\"clip-path:...\"`도 `base.attributes["clip-path"]`로 반영되도록 파서 보강
- 결정:
  - `S2-2`를 완료 처리하고 `S3-1`의 성능/메모리 튜닝으로 이동
- 리스크:
  - `clipPath`는 현재 `url(#id)` 참조와 shape/path 중심 경로만 지원, 텍스트/필터/마스크 경유 경로 미지원
- 다음 액션:
  - `S3-1`: 대형 SVG에서 렌더링 타임/메모리 경향 수치화 및 임계값/메모리 정책 정리
- 검증:
  - `swift test --filter SVGParserTests`
  - `swift test --filter SVGClipPathTests`
  - `swift test`

### 2026-02-15 (Session 35)
- 작업: WebKit LayoutTests 정합성 정리 및 `fetch-layout-tests.sh` 경로 정규화 보정
- 완료:
  - `./Scripts/webkit/fetch-layout-tests.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json Tests/SVGSwiftUITests/WebKit/fixtures` 재실행
  - fixture 정합성 검사: manifest 40건, missing 0 / extra 0
  - `./Scripts/webkit/generate-webkit-tests.sh` 및 `./Scripts/webkit/webkit-coverage.sh ... --strict` 재생성
- 결정:
  - `LayoutTests/svg` 소스 기준을 고정하고, 현재 후보군은 pass 40건으로 운영
- 리스크:
  - mask/filter/canvas 고급 경로는 아직 후보군에 미포함
- 다음 액션:
  - `A10-3`에서 unsupported 후보 확장 계획을 별도 검증 항목으로 반영
- 검증:
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`
  - `swift test --parallel`
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict`


### 2026-02-15 (Session 34)
- 작업: A10-2 WebKit conformance 파이프라인 최종 정합성 점검
- 완료:
  - `swift test --parallel` 재실행 (97 tests, 0 failures)
  - `swift test --filter testWebKitGeneratedSuite --no-parallel` (pass)
  - `./Scripts/webkit/webkit-coverage.sh Tests/SVGSwiftUITests/WebKit/webkit-manifest.json docs/WEBKIT_COVERAGE.md --strict` (strict pass)
- 결정:
  - A10-2는 WebKit 테스트 생성, CI 실행 경로, strict 산출물 갱신까지 완료 처리
- 리스크:
  - 1차 WebKit 후보군은 모두 `pass` 기대치로, 미지원 시그널은 아직 제한적
- 다음 액션:
  - A10-3로 후보군을 20~40건으로 확장하고 `unsupported` 전환 규칙을 manifest와 체크리스트에 반영
- 검증:
  - `swift test --parallel`
  - `swift test --filter testWebKitGeneratedSuite --no-parallel`
  - `./Scripts/webkit/webkit-coverage.sh ... --strict`

### 2026-02-15 (Session 33)
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

### 2026-02-15 (Session 30)
- 작업: 운영 안정화 단계 1차 정합성 점검
- 완료:
  - `README.md` 지원/미지원 항목 문구 정합성 보정
  - CI/테스트 실행 로그 재확인
  - `docs/WORK_LOG.md`, `docs/WORK_CONTINUATION.md`에 현재 세션 기록 반영
- 결정:
  - W3C/CI 파이프라인은 동작이 검증되어 문서 반영만 선행
- 리스크:
  - 향후 `swift test --filter` 동작은 toolchain별 차이가 남아있어 CI는 `--no-parallel` 유지가 안정적
- 다음 액션:
  - 다음 마일스톤: 추가 고급 렌더 기능(clip/mask/filter/marker) 및 v2 fixture 확장 여부 판단
- 검증:
  - `swift test --parallel`
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination id=CA606231-D9E3-453A-83EB-930148F67AED -parallel-testing-enabled NO test`

### 2026-02-15 (Session 31)
- 작업: 운영 안정화 1차 성능 개선
- 완료:
  - `SVGView`에 패스 캐시(`pathCache`) 적용
  - `loadDocument` 시점에 `SVGNode` 경로를 선생성해 `drawNodes` 단계의 반복 파싱 제거
  - 렌더 실패 분기에서 캐시 초기화로 오염 상태 방지
- 결정:
  - 고급 렌더 기능(clip/mask/filter/masking)은 `운영 안정화` 2차로 분리
- 검증:
  - `swift test --parallel`
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination id=CA606231-D9E3-453A-83EB-930148F67AED -parallel-testing-enabled NO test`

### 2026-02-15 (Session 32)
- 작업: S2-1 고급 렌더 기능 후보 분석
- 완료:
  - `docs/ADVANCED_RENDER_FEATURE_ANALYSIS.md` 추가로 clip/mask/filter/masking 분석 및 우선순위 확정
  - `docs/STEP_BY_STEP_PLAN.md`에 `S2-2 clipPath 미니멈 구현` 단계 추가
- 결정:
  - 1차 렌더 확장은 `clipPath`만 분리 착수, `mask/filter`는 다음 단계로 이관
- 리스크:
  - 현재 파서가 `<clipPath>/<mask>/<filter>`를 지원하지 않아 먼저 분석/보존 규칙만 확정 필요
- 다음 액션:
  - `clipPath` 파서/렌더 최소 경로 분석을 코드로 구체화하고 지원 범위를 축소 정의
- 검증:
  - `swift test --parallel`
  - `swift test --filter testW3CGeneratedSuite --no-parallel`
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination id=CA606231-D9E3-453A-83EB-930148F67AED -parallel-testing-enabled NO test`

### 2026-02-15 (Session 29)
- 작업: `A6-1` raster image 정책 및 `A7-1` cache key 버전 관리 보강
- 완료:
  - `SVGParser`에 `SVGImageNodePolicy` 추가: `.ignore`, `.renderRaster`, `.failOnRaster`
  - `image` 노드의 data URI 처리 정책 적용, raster placeholder 렌더 경로 추가
  - `testParseImageNode*` 3건 추가(기본/렌더/실패 정책)
  - `SVGParseCache` key 회귀 방지용 테스트에 options 변화 케이스 추가
- 결정:
  - W3C conformance 실행은 `--specifier/--parallel` 조합이 테스트 선별 실행에서 동작하지 않는 환경 이슈가 있어, CI를 `--filter` + `--no-parallel`로 고정 변경
- 리스크:
  - `swift test --filter`는 현재 Swift 6.2 일부 조합에서 동작이 제한적이라 병렬 실행은 분리 단계에서 비활성화 필요
- 다음 액션:
  - `A1~A7` 완료 후 운영 로그 기준으로 다음 마일스톤(추가 v2/성능 안정화) 도출
- 검증:
  - `swift test --parallel` (93 tests, 0 failures)
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination id=CA606231-D9E3-453A-83EB-930148F67AED -parallel-testing-enabled NO test` (5 tests, 0 failures)
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`
  - `swift test --filter testW3CGeneratedSuite --no-parallel` (1/1 W3C conformance)

### 2026-02-15 (Session 28)
- 작업: `A5-1` embedded SVG 재귀 처리 + depth/count 제한 정책 구현 완료
- 결정:
  - XML 파서는 `image` 요소를 즉시 재귀 파싱하지 않고 `embeddedImageSourceAttribute` 마커만 보관
  - `SVGEmbeddedImageState`로 전체 파싱 공유 카운트와 깊이를 추적해 재귀 임계치 초과를 일괄 제어
  - 임베디드 파싱이 실패하거나 결과가 비어 있으면 해당 `image` 노드는 최종 AST에서 제거
- 리스크:
  - syntheticID 재바인딩은 내부 구현이므로 외부 의존이 없지만, 향후 경로 규칙 변경 시 테스트 동기화 필요
- 다음 액션: `A6-1` raster image 정책 적용
- 검증:
  - `swift test --parallel` (90 tests, 0 failures)

### 2026-02-15 (Session 21)
- 작업: A3-1 cascade/specificity 엔진 구현
- 결정:
  - stylesheet 규칙 적용 순서를 `inherited -> stylesheet -> node.style -> idOverrides -> resolver`로 고정
  - selector matching은 id/class/element/any 단일 selector만 지원
  - specificity 가중치는 id 100, class 10, element 1, any 0
  - 동일 specificity는 소스 순서(후순위 덮어쓰기) 적용
- 리스크:
  - CSS 상속/미지원 속성/`!important`는 v2 범위에서 축소 지원 상태로 유지
- 다음 액션:
  - A4-1 data URI 파서 및 base64 디코더 착수
- 검증:
  - `swift test --parallel` (77 tests, 0 failures)
  - `./Scripts/w3c/w3c-coverage.sh Tests/SVGSwiftUITests/W3C/w3c-manifest.json docs/W3C_COVERAGE.md --strict`

### 2026-02-15
- 작업: P0-1/P0-2, P1 타입 스켈레톤, 파서/캐시 기본 골격 작성
- 결정: 캐시는 AST only, 노드 제어는 map 기본 + resolver 옵션 유지
- 리스크: XML 실파서/arc 파서/데모앱은 아직 미구현
- 다음 액션: DemoApp 생성 및 P1-3 XML tokenization 착수

### 2026-02-15 (Session 02)
- 작업: P1-3 XML tokenization 파서 구현, 파서 테스트 확장, 로그 동기화
- 결정: DemoApp은 xcodegen 없이 수동 xcodeproj 방식으로 진행
- 리스크: path command 파서와 스타일 상속 우선순위는 다음 단계
- 다음 액션: P2-1 path parser 먼저 구현

### 2026-02-15 (Session 04)
- 작업: 테스트 보강 + path parser 독립 구현 + 캐시 음수 cost 보정
- 결정: P2는 parser 독립 구현 후 SVGParser AST 연결 순으로 진행
- 리스크: path command 결과가 아직 SVGNode에 연결되지 않음
- 다음 액션: path AST 연결 및 스타일 상속 로직 착수

### 2026-02-15 (Session 05)
- 작업: path parser를 SVGParser path 노드에 연결, invalid path 실패 처리 추가
- 결정: invalid path data는 조용히 무시하지 않고 malformedDocument로 명확히 실패
- 리스크: command 결과가 실제 렌더 Path 생성에는 아직 미연결
- 다음 액션: style 상속 우선순위 + render path builder 구현

### 2026-02-15 (Session 07)
- 작업: 스타일 상속/override 우선순위 엔진(`SVGStyleResolver`) 구현 및 테스트 추가
- 결정: 우선순위는 `원본(inheritance 포함) < idOverrides < resolver`로 고정
- 리스크: 현재 엔진 결과가 `SVGView` 실제 렌더에는 아직 미연결
- 다음 액션: path builder + style resolver를 `SVGView`에 통합

### 2026-02-15 (Session 08)
- 작업: `SVGPathCommandBuilder`/`SVGNodePathBuilder` 구현 및 `SVGView` 렌더 통합
- 결정: `SVGView`는 Canvas 기반으로 fill/stroke/opacity/linecap/linejoin을 적용
- 리스크: transform matrix 누적 및 일부 고급 SVG 렌더 규칙은 추가 보강 필요
- 다음 액션: DemoApp 생성 + UITest baseline 흐름 구축

### 2026-02-15 (Session 09)
- 작업: DemoApp 생성, 접근성 식별자 정리, UITest 4개 구현/안정화
- 결정: UITest는 플래키를 줄이기 위해 switch value 문자열 비교 대신 실제 조작 가능성 검증 중심으로 구성
- 리스크: snapshot baseline 비교/시각 diff 유틸은 아직 미구현
- 다음 액션: baseline 캡처/비교 파이프라인 추가 + cache 통계 UI 구현

### 2026-02-15 (Session 10)
- 작업: `SVGView` 파싱 경로에 `SVGParseCache` 실연동, cache key schemaVersion 반영, 관련 테스트 보강
- 결정: cache key는 `sourceData stable hash + options + schemaVersion` 조합으로 고정
- 리스크: cache hit/miss를 Demo UI에서 직접 확인하는 통계 패널은 아직 미구현
- 다음 액션: baseline 비교 유틸과 cache 통계 패널 구현

### 2026-02-15 (Session 12)
- 작업: 접근제어 일괄 정리(`public` 축소), Demo에서 내부 캐시 직접 주입 제거, 공개 API 경계 정책 문서화
- 결정: 외부 계약은 `SVGView` + 렌더 설정/오버라이드 타입 중심으로 제한하고 파서/AST/캐시 구현은 내부 캡슐화
- 리스크: Demo cache 통계 UI는 내부 캐시 접근 대신 별도 통계 노출 API 설계가 필요
- 다음 액션: `P7-1` 착수 시 cache metric read-only 노출 방식(예: snapshot struct) 추가

### 2026-02-15 (Session 13)
- 작업: `P7-3` baseline 캡처 + `P8-2` 시각 회귀 비교 유틸 구현
- 결정: baseline은 `UITests/Baselines/<device>/<runtime>/<name>.png` 구조로 저장하고, 캡처는 `demo.canvas` 요소 스크린샷 기준으로 비교
- 리스크: anti-aliasing 미세 오차로 완전일치가 불안정해 허용오차(0.50%)를 적용
- 다음 액션: `P7-1` cache 통계 패널 구현으로 이동

### 2026-02-15 (Session 14)
- 작업: `P7-1` cache 통계 패널 구현 + read-only telemetry API 추가
- 결정: 내부 `SVGParseCache`는 캡슐화 유지, 외부에는 `SVGCacheMetrics`/`SVGCacheStats`만 공개
- 리스크: 시각 회귀는 환경 편차가 있어 허용오차를 0.50%로 유지 필요
- 다음 액션: `P6-1` transform 누적/고급 렌더 보강 진행

### 2026-02-15 (Session 15)
- 작업: `P6-1` transform 누적 렌더 구현(`SVGTransformBuilder` + parent/local transform 전파)
- 결정: transform 결합 순서는 `local` 후 `inherited`로 고정하여 SVG 계층 transform 의미를 유지
- 리스크: clipPath/mask/filter 등 고급 렌더 규칙은 v1 범위 외라 이후 확장 단계에서 처리 필요
- 다음 액션: `P8-1` fixture 기반 통합 회귀 테스트 확장

### 2026-02-15 (Session 16)
- 작업: `P8-3` GitHub CI 기본 파이프라인 구성
- 결정: CI에서 `swift test`와 Demo UITest를 동일 워크플로우에서 병렬/의존 실행으로 분리
- 리스크: 시뮬레이터 이름 자동 선택 로직이 runner 환경별로 달라질 수 있어 실패 원인 로그를 남겨 추적 필요
- 다음 액션:
- 샘플 fixture 기반 P8-1 통합 테스트 보강
- CI에서 샘플 fixture 회귀 케이스 실행 보강

### 2026-02-15 (Session 17)
- 작업:
  - `P8-1` fixture 통합 테스트 3건 추가 및 실행 검증
  - `P8-3` 데모 UITest 안정화(동시 테스트 비활성화) 및 destination id 기반 고정
  - fixture 번들 리소스 등록 및 워크플로우 통합
- 결정:
  - CI에서 UITest는 재현성 보장을 위해 `-parallel-testing-enabled NO` 적용
  - destination은 `name:iPhone 17` 선호 + fallback 방식으로 `id` 지정
- 검증:
  - `swift test --parallel` 통과 (`63` tests)
  - `xcodebuild ... test` 통과 (`5` tests, `0` failures)
- 리스크: Runner별 iPhone 17 장치 미설치 시 fallback id에 따라 분산 실행될 수 있음
- 다음 액션:
  - `P9-1` README/사용 가이드 정리
  - W3C fixture subset 확장 계획 수립

### 2026-02-15 (Session 20)
- 작업:
  - W3C fixture를 `Tests/SVGSwiftUITests/W3C`로 이동해 테스트 타깃 리소스에 수집되도록 정리
  - `Scripts/w3c/generate-w3c-tests.sh`를 manifest 기반 다중 fixture 자동 생성기로 정식 구현
  - `Tests/SVGSwiftUITests/W3CGeneratedTests.swift`를 생성해 CI에서 `swift test --parallel` 경유로 회귀 검증
  - W3C 리소스 번들(`.process("W3C")`) 등록 및 CI 생성기 실행 단계 추가
- 결정:
  - W3C 경로는 flat 리소스 구조를 고려해 경로 파싱 시 basename 기반 조회로 처리
  - 생성 스텝을 CI `swift-tests` 잡에서 `swift test` 전에 선행 실행
- 검증:
  - `Scripts/w3c/generate-w3c-tests.sh` 실행으로 4개 fixture 테스트 코드 생성 확인
  - `swift test --parallel` 통과 (`64` tests)
  - `xcodebuild ... UITests` 통과 (`5` tests, `0` failures)
- 리스크:
  - 리소스가 플랫으로 복사되므로 manifest 경로는 정규화되어야 하며, 향후 중복 파일명 충돌 시 충돌 규칙이 필요
- 다음 액션:
  - `A9-1` W3C coverage 리포트 스크립트 추가
  - `A9-2` CI에서 W3C conformance 전용 아티팩트(리포트/이슈) 업로드 반영
