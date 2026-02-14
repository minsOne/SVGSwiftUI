# 작업 연속성 문서

## 현재 상태 (2026-02-15)
- 저장소 상태: Swift Package 초기화 완료
- 계획 문서: `/Users/minsone/Developer/SVGSwiftUI/docs/STEP_BY_STEP_PLAN.md`
- 구현 상태: P1 XML tokenization 완료, P2/P4 진행 대기

## 잠금된 의사결정
- 대상 플랫폼: iOS 15+
- 기본 렌더 방식: SwiftUI `Path`
- 기본 업데이트 방식: 상태 기반 갱신(필요 시에만 `TimelineView`)
- 노드 제어: `NodeID map` 기본 + 선택적 closure
- 캐시: 파싱 결과(AST) 전용
- v2 확장: style/CSS subset + base64 `data:` URI

## 바로 다음 실행 순서
1. Path 파서 명령(`M/L/H/V/C/S/Q/T/A/Z`) tokenizer/AST 구현
2. 스타일 상속 + override 우선순위 로직 구현 (`원본 < map < resolver`)
3. DemoApp 수동 xcodeproj 생성 및 로컬 패키지 연결
4. 샘플 SVG fixture 추가 후 렌더/파서 통합 테스트 보강
5. 캐시 키(`source + options + schemaVersion`) 해시 고도화

## 체크리스트 (진행 시 갱신)
- [ ] P0 부트스트랩 완료 (DemoApp 남음)
- [x] P1 모델/파서 골격 완료 (XML tokenization 포함)
- [ ] P2 Path 파서 완료
- [ ] P3 도형 파서 완료
- [ ] P4 스타일/노드 제어 완료
- [ ] P5 캐시 완료
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
