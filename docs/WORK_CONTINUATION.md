# 작업 연속성 문서

## 현재 상태 (2026-02-15)
- 저장소 상태: Swift Package + DemoApp(`Examples/SVGSwiftUIDemo`) 생성 완료
- 계획 문서: `/Users/minsone/Developer/SVGSwiftUI/docs/STEP_BY_STEP_PLAN.md`
- 구현 상태: P0/P1/P2/P3/P4/P5 핵심 완료, `SVGView` 캐시 연동 렌더까지 완료, 패키지 테스트 53개 + Demo UITest 4개 통과
- API 상태: 공개 표면 최소화 적용 완료(파서/AST/캐시/렌더 내부 엔진은 `internal`)

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
1. baseline 이미지 저장 및 시각 회귀 비교 유틸 추가(`P7-3`, `P8-2`)
2. Demo UI에 cache 통계 패널 추가(`P7-1`)
3. transform/고급 렌더 보강(`P6-1`)
4. 샘플 SVG fixture 추가 후 렌더/파서 통합 테스트 보강
5. v2 진입 시 W3C fixture subset + coverage 리포트 파이프라인 추가

## 체크리스트 (진행 시 갱신)
- [x] P0 부트스트랩 완료
- [x] P1 모델/파서 골격 완료 (XML tokenization 포함)
- [x] P2 Path 파서 완료
- [x] P3 도형 파서 완료
- [x] P4 스타일/노드 제어 완료
- [x] P5 캐시 완료
- [ ] P6 렌더러 완료
- [ ] P7 Demo 앱 완료
- [ ] P8 테스트 강화 완료
- [ ] P9 문서화 완료
- [ ] A1~A7 v2 고급 기능 완료

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
