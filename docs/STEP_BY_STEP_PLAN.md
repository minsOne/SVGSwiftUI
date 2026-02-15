# SVGSwiftUI 단계별 실행 계획표

## 1. 프로젝트 목표
- iOS 15+ 환경에서 SVG를 파싱해 SwiftUI `Path` 기반으로 렌더링한다.
- 노드 단위 제어(색상/크기/offset)를 제공한다.
- 파싱 결과(AST) 캐시를 통해 성능을 개선한다.
- Demo 앱과 테스트 코드를 포함해 개발/검증 루프를 완성한다.
- Demo 앱에 UITest를 추가해 실제 렌더 결과를 기준 이미지와 비교 검증한다.

## 2. 확정된 기본 결정
- 프로젝트 형태: `Swift Package + iOS DemoApp`
- v1 지원 범위: `svg/g/path/rect/circle/ellipse/line/polyline/polygon`
- 노드 제어 방식: `NodeID map` 기본 + 선택적 `resolver closure`
- 캐시 정책: 파싱 결과(AST)만 메모리 LRU 캐시
- v2 확장 범위: `style` 고급 처리 + `data:`(base64) URI 지원
- v2 이후 확장: W3C SVG 테스트 스위트 기반 준수 테스트 트랙 추가

## 3. 단계별 계획 (v1)

| Phase | 작업 | 주요 산출물 | 완료 기준 |
|---|---|---|---|
| P0 | 부트스트랩 | SPM 타깃, DemoApp 연결 구조 | 패키지/앱 빌드 기본 통과 |
| P1 | 모델/파서 골격 | `SVGDocument`, `SVGNode`, 기본 XML 파서 | 샘플 SVG 기본 노드 파싱 성공 |
| P2 | Path 파서 | `M/L/H/V/C/S/Q/T/A/Z` 지원 | path 명령 단위 테스트 통과 |
| P3 | 도형 파서 | rect/circle/ellipse/line/polyline/polygon -> `Path` | 도형별 렌더 테스트 통과 |
| P4 | 스타일/노드 제어 | 상속 스타일 + override(`map/resolver`) | 우선순위 테스트 통과 (`원본 < map < resolver`) |
| P5 | 캐시 | `SVGParseCache` actor, LRU 정책 | hit/miss/eviction 테스트 통과 |
| P6 | 렌더러 | `SVGView` + transform 적용 | 샘플 SVG 시각 확인 가능 |
| P7 | Demo 앱 | 노드 제어 UI + 캐시 통계 화면 + UITest 타깃 | 인터랙션 반영 + 샘플 화면 UITest 실행 가능 |
| P8 | 테스트 강화 | 파서/렌더/캐시/통합 테스트 + 시각 회귀 비교 | `swift test` 통과 + UITest 기준 비교 통과 |
| P8-3 | CI 파이프라인 | GitHub Actions | `swift test` + Demo UITest가 CI에서 통과 |
| P9 | 문서화 | README, 지원 범위, 제한 사항 | 신규 사용자가 예제로 실행 가능 |

## 4. 단계별 계획 (v2 고급 기능)

| Phase | 작업 | 주요 산출물 | 완료 기준 |
|---|---|---|---|
| A1 | `style` attribute 파서 | declaration parser | 인라인 style 파싱 테스트 통과 |
| A2 | `<style>` CSS subset | selector/rule AST | id/class/element selector 테스트 통과 |
| A3 | cascade/specificity | style resolver v2 | 우선순위 일치 (`presentation < stylesheet < inline < override`) |
| A4 | `data:` URI 파서 | media type + base64 decoder | 정상/오류 케이스 테스트 통과 |
| A5 | embedded SVG 처리 | `data:image/svg+xml` 재귀 파싱 | depth 제한 포함 통합 테스트 통과 |
| A6 | raster 정책 | `.ignore/.renderRaster/.failOnRaster` | 정책별 동작 테스트 통과 |
| A7 | 캐시 확장 | v2 키 버전 포함 | 옵션/버전 변경 시 stale hit 없음 |
| A8 | W3C 테스트 도입(1차) | W3C fixture subset + 자동 테스트 생성 | 지원 범위 카테고리(paths/shapes/coords/styling) 기준 비교 테스트 통과 |
| A9 | W3C 커버리지 리포트 | coverage markdown + CI 아티팩트 | 현재 지원 범위 대비 pass/fail/unsupported 지표 자동 생성 |
| A10-1 | WebKit LayoutTests 1차 반영 | WebKit manifest/fetch/generate 파이프라인 | 8~12개 테스트 케이스 선별 및 소스 정합성 확인 |
| A10-2 | WebKit conformance CI | `testWebKitGeneratedSuite` + coverage 리포트 | CI에서 pass/fail/unsupported 자동 추적 |
| A10-3 | WebKit 후보군 확대 및 상태 전이 | unsupported 정책, manifest 갱신 규칙, 후보군 20~40건 확장 | pass/fail/unsupported 분포 추적이 운영 지표로 반영 |
| A11-1 | filter 파싱/스타일 전달 | `<filter>` 정의 및 `filter` 속성/스타일 전달 | `filter` AST/스타일 경로 보존 테스트 통과 |
| A11-2 | filter 렌더 패스 연동 | blur/offset 최소 필터 렌더 체인 구축 | `filter` primitive 참조 및 렌더 적용 회귀 테스트 통과 |

## 5. API 설계 고정안
- 공개 API(외부 사용 대상):
  - `SVGView`
  - `SVGSource`: `.string`, `.data`, `.fileURL`
  - `SVGParserOptions`
  - `SVGCacheMetrics`, `SVGCacheStats`
  - `SVGRenderConfiguration`: `idOverrides`, `resolver`
  - `NodeOverrideMap`: `[String: NodeOverride]`
  - `NodeStyleResolver`: `(NodeContext) -> NodeOverride?`
  - 렌더 override 타입: `NodeOverride`, `NodeContext`, `SVGPaint`, `SVGColor`, `SVGSize`, `SVGPoint`, `SVGElementKind`
- 내부 API(패키지 내부 전용):
  - 파서/AST 모델(`SVGDocument`, `SVGNode*`, `SVGStyle*`, `SVGTransform`)
  - 렌더 내부 엔진(`SVGStyleResolver`, `SVGNodePathBuilder`, `SVGPathCommandBuilder`)
  - 캐시 구현(`SVGParseCache`, `SVGParseCacheKey`)
- v2 옵션:
  - `enableStyleTag`
  - `enableDataURI`
  - `maxDataURIBytes`
  - `maxEmbeddedImageCount`
- `imageNodePolicy`

## 6. 반복 작업 규칙
- 각 Task 완료 시 `WORK_LOG.md`에 세션 정리 항목을 우선 반영
- 변경사항 검증 완료 후 `git add`, `git commit`, `git push`를 동일 실행 단위로 처리
- 커밋 메시지에 Task ID와 변경 범위를 반영
- 다음 단계 진입 전 `TASK_BOARD`와 `WORK_CONTINUATION`을 동기화

## 7. 운영 안정화

| Phase | 작업 | 주요 산출물 | 완료 기준 |
|---|---|---|---|
| S1 | 렌더 성능 개선 | `SVGView` path 캐시 | 파서/리졸버 결과 변경 없이 draw pass에서 경로 재생성 지표가 감소 |
| S2 | 고급 렌더 기능 후보 분석 | `docs/ADVANCED_RENDER_FEATURE_ANALYSIS.md` | clip/mask/filter/masking 처리 정책/우선순위 확정 |
| S2-2 | `clipPath` 미니멈 구현 | clipPath 참조 해석 + 기본 경로 클리핑 지원 | W3C 하위 카테고리/샘플 테스트 1차 통과 |
| S3 | 메모리/고해상도 튜닝 | `docs/S3_PERFORMANCE_TUNING.md` | 대형 SVG에서 캐시 hit율/메모리 안정성 기준 정리 |
| S3-2 | 경계 성능 프로파일 정합성 | `SVGRenderPerformanceProfileTests`, `Scripts/performance/run-s3-profile.sh` | 경계 임계치(2000/2001 노드, 300_000/300_001 bytes) 측정 로그 보존 및 CI 아티팩트 연동 |

## 8. 위험요소와 대응
- `id` 없는 노드 제어 공백: synthetic key 생성(`auto:/...`)로 보완
- 캐시 오염: `parser/options/schemaVersion` 포함 키로 방지
- arc 정밀도 문제: 허용오차 기반 회귀 테스트로 관리
- base64 메모리 폭증: payload/개수/depth 제한 강제
- CSS 과범위 확장: v2는 subset으로 제한하고 미지원은 로그 처리

## 9. 최종 완료 기준
- v1: iOS 15+에서 샘플 SVG 렌더 + 노드 제어 + 캐시 + 단위/UITest 통과
- v2: style/data URI 고급 기능이 정책 기반으로 안정 동작
- v2+: W3C 준수 테스트 리포트가 생성되고, 지원 범위 내 회귀가 CI에서 차단됨
- 문서: 지원/미지원/제약이 명확하게 명시됨
