import SwiftUI

public struct AnimatedEyeView: View {
    public let size: CGFloat
    public let isAwake: Bool
    public let isScanning: Bool
    
    @State private var pupilOffset: CGFloat = -0.35
    
    public init(size: CGFloat = 64, isAwake: Bool = true, isScanning: Bool = true) {
        self.size = size
        self.isAwake = isAwake
        self.isScanning = isScanning
    }
    
    public var body: some View {
        let width = size
        let height = size * 0.58
        let irisSize = height * 0.56
        let maxHorizontalShift = (width - irisSize) * 0.25
        
        ZStack {
            // Subtle monochrome glass luminance (inside fixed frame, never changes layout bounds)
            EyeShape()
                .fill(
                    LinearGradient(
                        colors: isAwake
                            ? [Color.white, Color(white: 0.86)]
                            : [Color.white.opacity(0.14), Color.white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)
                .overlay(
                    EyeShape()
                        .stroke(
                            LinearGradient(
                                colors: isAwake
                                    ? [Color.white.opacity(0.9), Color.white.opacity(0.25)]
                                    : [Color.white.opacity(0.32), Color.white.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.0, size * 0.025)
                        )
                )
                .shadow(
                    color: isAwake ? Color.white.opacity(0.22) : Color.clear,
                    radius: 10,
                    x: 0,
                    y: 0
                )
                .clipShape(EyeShape())
                .overlay(
                    ZStack {
                        if isAwake {
                            // Monochrome obsidian iris + pupil + crisp glass specular reflection
                            Circle()
                                .fill(Color(white: 0.08))
                                .frame(width: irisSize, height: irisSize)
                            
                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                .frame(width: irisSize * 0.82, height: irisSize * 0.82)
                            
                            Circle()
                                .fill(Color.black)
                                .frame(width: irisSize * 0.46, height: irisSize * 0.46)
                            
                            Circle()
                                .fill(Color.white.opacity(0.92))
                                .frame(width: irisSize * 0.22, height: irisSize * 0.22)
                                .offset(x: -irisSize * 0.16, y: -irisSize * 0.16)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.22))
                                .frame(width: irisSize * 0.54, height: irisSize * 0.54)
                        }
                    }
                    .offset(x: isAwake && isScanning ? pupilOffset * maxHorizontalShift : 0, y: 0)
                )
            
            // Minimal monochrome slash when standby (contained within fixed bounds)
            if !isAwake {
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: width * 0.88, height: max(1.75, size * 0.036))
                    .rotationEffect(.degrees(-28))
            }
        }
        .frame(width: width, height: height)
        .animation(.easeInOut(duration: 0.25), value: isAwake)
        .onAppear {
            if isAwake && isScanning {
                startScanningAnimation()
            }
        }
        .onChange(of: isAwake) { awake in
            if awake && isScanning {
                startScanningAnimation()
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    pupilOffset = 0
                }
            }
        }
    }
    
    private func startScanningAnimation() {
        pupilOffset = -0.85
        withAnimation(
            Animation
                .easeInOut(duration: 2.2)
                .repeatForever(autoreverses: true)
        ) {
            pupilOffset = 0.85
        }
    }
}

/// Precise almond eye shape with bezier curves
public struct EyeShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        let startPoint = CGPoint(x: 0, y: height * 0.5)
        let endPoint = CGPoint(x: width, y: height * 0.5)
        
        path.move(to: startPoint)
        path.addCurve(
            to: endPoint,
            control1: CGPoint(x: width * 0.28, y: -height * 0.16),
            control2: CGPoint(x: width * 0.72, y: -height * 0.16)
        )
        path.addCurve(
            to: startPoint,
            control1: CGPoint(x: width * 0.72, y: height * 1.16),
            control2: CGPoint(x: width * 0.28, y: height * 1.16)
        )
        path.closeSubpath()
        return path
    }
}
