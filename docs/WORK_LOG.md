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
