# SVGSwiftUI Coding Style

## 목적
- Swift 컴파일러 타입 추론 부담을 줄여 빌드 시간을 안정화한다.
- 연산식 가독성을 높여 리뷰 시 타입 오류를 빠르게 찾는다.

## 타입/연산 규칙
1. 서로 다른 타입(`Double`, `CGFloat`, `Int` 등)을 한 식에서 바로 계산하지 않는다.
2. 계산 전에 공통 타입으로 명시 변환하고, 변환 이후에만 연산한다.
3. 긴 수식은 단계별 지역 변수로 분해하고 각 변수 타입을 명시한다.
4. 숫자 리터럴은 필요한 타입을 명시한다 (`2.0`, `0.0`, `let two: CGFloat = 2`).
5. `CGPoint`, `CGSize` 생성 시 암묵 변환에 기대지 않고 명시 변환을 사용한다.

## 권장 패턴
```swift
let startX: Double = Double(start.x)
let endX: Double = Double(end.x)
let dx: Double = (startX - endX) / 2.0
```

```swift
private func makePoint(x: Double, y: Double) -> CGPoint {
    CGPoint(x: CGFloat(x), y: CGFloat(y))
}
```

## 금지 패턴
```swift
let dx = Double(start.x - end.x) / 2
return CGPoint(x: transformedX, y: transformedY)
```
