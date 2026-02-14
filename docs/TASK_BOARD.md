# SVGSwiftUI Task Board

Last Updated: 2026-02-15 (DemoApp + UITest implemented)

## Status Legend
- `todo`: not started
- `in_progress`: currently active
- `done`: completed and verified
- `blocked`: waiting on dependency/decision

## v1 Milestones
| ID | Phase | Task | Status | Notes |
|---|---|---|---|---|
| P0-1 | P0 | Swift Package bootstrap | done | `swift package init --type library` 완료 |
| P0-2 | P0 | iOS 15+ package platform 설정 | done | `Package.swift` 플랫폼 지정 완료 |
| P0-3 | P0 | DemoApp 타깃 생성/연결 | done | `Examples/SVGSwiftUIDemo` 생성 + xcodebuild build/test 검증 완료 |
| P1-1 | P1 | 모델 타입 정의(`SVGDocument`, `SVGNode`, style/transform) | done | 스켈레톤 구현 |
| P1-2 | P1 | 파서 옵션/에러/인터페이스 정의 | done | 스켈레톤 구현 |
| P1-3 | P1 | 실제 XML tokenization 파서 구현 | done | 지원 요소 트리 파싱 + root/style 기본 파싱 완료 |
| P2-1 | P2 | Path command parser 구현 | done | parser/AST 연결 + `SVGPathCommandBuilder` 완료 |
| P3-1 | P3 | 도형 요소 파싱/Path 변환 | done | `SVGNodePathBuilder`로 rect/circle/ellipse/line/polyline/polygon -> `CGPath` 변환 완료 |
| P4-1 | P4 | 스타일 상속 + override 우선순위 구현 | done | `SVGStyleResolver` 엔진 구현 및 `SVGView` 연동 완료 |
| P5-1 | P5 | AST LRU 캐시 구현/테스트 | in_progress | actor LRU + 테스트 완료, key/hash/schemaVersion 고도화 남음 |
| P6-1 | P6 | SwiftUI 렌더러 구현 | in_progress | Canvas 렌더/스타일 적용 완료, transform 누적/고급 렌더 보강 필요 |
| P7-1 | P7 | Demo 앱 UI(노드 제어/캐시 통계) | in_progress | 노드 제어 UI 완료, cache 통계 패널 미구현 |
| P7-2 | P7 | Demo UITest 타깃 구성 | done | UITest 4개 작성 및 `xcodebuild test` 통과 |
| P7-3 | P7 | 기준 이미지(snapshot baseline) 수집 | todo | 샘플 SVG별 baseline 확정 |
| P8-1 | P8 | 테스트 확장/회귀 fixture | in_progress | parser/cache/path/style/view 지원 로직 테스트 50개 통과 |
| P8-2 | P8 | UITest 결과 비교(시각 회귀) | todo | baseline 대비 픽셀/허용오차 비교 |
| P9-1 | P9 | README/가이드 문서 | todo | 미시작 |

## v2 Milestones
| ID | Phase | Task | Status | Notes |
|---|---|---|---|---|
| A1-1 | A1 | `style` attribute parser | todo |  |
| A2-1 | A2 | `<style>` CSS subset parser | todo |  |
| A3-1 | A3 | cascade/specificity engine | todo |  |
| A4-1 | A4 | `data:` URI parser/base64 decoder | todo |  |
| A5-1 | A5 | embedded SVG recursion 제한 처리 | todo |  |
| A6-1 | A6 | raster image policy 처리 | todo |  |
| A7-1 | A7 | v2 cache key versioning | todo |  |
| A8-1 | A8 | W3C fixture subset 도입(1.1F2/1.2T) | todo | 지원 요소 기준(paths/shapes/coords/styling 우선) |
| A8-2 | A8 | W3C 테스트케이스 자동 생성 스크립트 | todo | fixture manifest -> XCTest 코드 생성 |
| A9-1 | A9 | W3C coverage 리포트 생성 스크립트 | todo | pass/fail/unsupported 카테고리별 집계 |
| A9-2 | A9 | CI에 W3C conformance 단계 추가 | todo | 회귀 시 fail, 리포트 아티팩트 업로드 |

## Anti-Duplication Rules
1. 작업 시작 전 해당 Task ID를 `in_progress`로 먼저 바꾼다.
2. 구현 후 테스트/검증 커맨드와 결과를 `WORK_LOG.md`에 기록한다.
3. 완료 조건을 모두 충족한 경우에만 `done`으로 변경한다.
4. 동일 Task ID는 재사용하지 않는다(하위 작업은 `-1`, `-2` 증가).
