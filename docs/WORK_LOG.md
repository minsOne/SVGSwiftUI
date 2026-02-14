# SVGSwiftUI Work Log

## 2026-02-15

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
