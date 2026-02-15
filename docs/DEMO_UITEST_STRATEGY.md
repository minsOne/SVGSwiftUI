# Demo UITest Strategy

## 목적
- DemoApp 렌더 결과가 기대 결과와 일치하는지 자동 검증한다.
- 수동 눈검사를 줄이고 회귀를 조기에 탐지한다.

## 현재 구현 상태 (2026-02-15)
- `Examples/SVGSwiftUIDemo/UITests/SVGSwiftUIDemoUITests.swift` 구현 완료
- 현재 자동화 범위:
  - launch + 핵심 접근성 요소 존재 확인
  - sample 전환 + node id 입력 반영 확인
  - fill/stroke toggle 조작
  - offset slider 조작
  - canvas baseline 시각 회귀 비교(`testCanvasMatchesBaselines`)
- 검증 커맨드:
  - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 17' test`

## 범위
1. DemoApp launch 및 샘플 SVG 화면 진입 테스트
2. 노드 제어 UI 변경 후 렌더 결과 반영 검증
3. 기준 이미지(snapshot baseline) 비교

## 구현 단계
1. DemoApp에 `SVGSwiftUIDemoUITests` 타깃 추가
2. 접근성 식별자 고정
   - Canvas: `demo.canvas`
   - 샘플 선택 리스트: `demo.sampleList`
   - 노드 제어 패널: `demo.controls`
3. 화면 캡처 유틸 작성
   - `demo.canvas` 요소 스크린샷 사용(화면 전체 crop 불필요)
4. baseline 저장 규칙
   - 경로: `Examples/SVGSwiftUIDemo/UITests/Baselines/<device>/<runtime>/<name>.png`
   - 현재 baseline: `iPhone_17/26.2/{badge_default,panel_stroke,route_offset}.png`
5. 비교 방식
   - 픽셀 mismatch ratio 계산 후 허용오차 비교
   - 현재 허용오차: `0.50%` (`0.005`)
6. 실패 시 산출물
   - actual, expected, diff 이미지 저장
   - 로그에 mismatch 비율 + artifact 경로 출력

## Baseline 갱신 절차
1. `touch Examples/SVGSwiftUIDemo/UITests/Baselines/.record`
2. UITest 실행:
   - `xcodebuild -project Examples/SVGSwiftUIDemo/SVGSwiftUIDemo.xcodeproj -scheme SVGSwiftUIDemo -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 17' test`
3. `.record` 파일 삭제 후 재실행해 compare 모드 통과 확인

## 중복 작업 방지 규칙
1. baseline 갱신은 UI 변경 PR에서만 수행
2. baseline 변경 시 `WORK_LOG.md`에 이유 기록
3. 테스트 실패 시 먼저 렌더 로직 변경 여부를 확인하고 baseline을 바로 갱신하지 않는다

## 초기 테스트 케이스
1. `testCanvasMatchesBaselines`
2. `testLaunchShowsCanvasAndControls`
3. `testSampleSwitcherAndNodeFieldAreAccessible`
4. `testTogglesCanBeChanged`
5. `testOffsetSlidersExist`

## 리스크/주의사항
- 안티앨리어싱 차이로 기기별 픽셀 오차가 발생할 수 있음
- CI에서 시뮬레이터/폰트/스케일을 고정해야 오탐을 줄일 수 있음
- 초기에는 핵심 2~4개 샘플만 baseline 대상으로 제한
