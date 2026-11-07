import SwiftUI

public struct AnimatedEyeView: View {
    public let size: CGFloat
    public let isAwake: Bool
    public let isScanning: Bool
    
    @State private var pupilOffset: CGFloat = -0.35
    @State private var eyeBlink: CGFloat = 1.0
    
    public init(size: CGFloat = 80, isAwake: Bool = true, isScanning: Bool = true) {
        self.size = size
        self.isAwake = isAwake
        self.isScanning = isScanning
    }
    
    public var body: some View {
        let width = size
        let height = size * 0.6
        let pupilSize = height * 0.52
        let maxHorizontalShift = (width - pupilSize) * 0.28
        
        ZStack {
            // Ambient Vigilance Glow (3D Depth)
            if isAwake {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: pupilSize * 0.5,
                            endRadius: width * 0.75
                        )
                    )
                    .frame(width: width * 1.5, height: height * 1.7)
                    .blur(radius: 6)
            }
            
            // Outer 3D Sclera / Eye Base
            EyeShape()
                .fill(
                    LinearGradient(
                        colors: isAwake ? [Color(white: 0.95), Color(white: 0.82)] : [Color(white: 0.35), Color(white: 0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)
                .overlay(
                    // Inner shadow and rim highlight
                    EyeShape()
                        .stroke(
                            LinearGradient(
                                colors: isAwake ? [Color.green.opacity(0.8), Color.green.opacity(0.3)] : [Color.gray.opacity(0.5), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.5, size * 0.04)
                        )
                )
                .shadow(color: isAwake ? Color.green.opacity(0.4) : Color.black.opacity(0.3), radius: 8, x: 0, y: 3)
                .clipShape(EyeShape())
                .overlay(
                    // Moving Eyeball / Iris / Pupil
                    ZStack {
                        if isAwake {
                            // Iris Outer Glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.green, Color.teal.opacity(0.85), Color(red: 0.05, green: 0.3, blue: 0.2)],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: pupilSize * 0.5
                                    )
                                )
                                .frame(width: pupilSize, height: pupilSize)
                                .shadow(color: Color.green.opacity(0.8), radius: 4)
                            
                            // Pupil
                            Circle()
                                .fill(Color.black)
                                .frame(width: pupilSize * 0.48, height: pupilSize * 0.48)
                            
                            // Specular Light Reflection (3D Glass Look)
                            Circle()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: pupilSize * 0.2, height: pupilSize * 0.2)
                                .offset(x: -pupilSize * 0.15, y: -pupilSize * 0.15)
                        } else {
                            // Asleep: Centered muted pupil
                            Circle()
                                .fill(Color.secondary.opacity(0.5))
                                .frame(width: pupilSize * 0.6, height: pupilSize * 0.6)
                            Circle()
                                .fill(Color.black.opacity(0.7))
                                .frame(width: pupilSize * 0.3, height: pupilSize * 0.3)
                        }
                    }
                    .offset(x: isAwake && isScanning ? pupilOffset * maxHorizontalShift : 0, y: 0)
                )
                .scaleEffect(y: eyeBlink, anchor: .center)
            
            // Slashed bar when asleep
            if !isAwake {
                Rectangle()
                    .fill(Color.red.opacity(0.85))
                    .frame(width: width * 1.15, height: max(2.5, size * 0.06))
                    .rotationEffect(.degrees(-35))
                    .shadow(color: Color.black.opacity(0.5), radius: 2)
            }
        }
        .onAppear {
            if isAwake && isScanning {
                startScanningAnimation()
            }
        }
        .onChange(of: isAwake) { awake in
            if awake && isScanning {
                startScanningAnimation()
            }
        }
    }
    
    private func startScanningAnimation() {
        pupilOffset = -1.0
        withAnimation(
            Animation
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
        ) {
            pupilOffset = 1.0
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
        // Upper lid curve
        path.addCurve(
            to: endPoint,
            control1: CGPoint(x: width * 0.28, y: -height * 0.18),
            control2: CGPoint(x: width * 0.72, y: -height * 0.18)
        )
        // Lower lid curve
        path.addCurve(
            to: startPoint,
            control1: CGPoint(x: width * 0.72, y: height * 1.18),
            control2: CGPoint(x: width * 0.28, y: height * 1.18)
        )
        path.closeSubpath()
        return path
    }
}
