//
//  PlaybarMeshGradient.swift
//  Muse
//
//  Created by Xinshao_Air on 2024/11/9.
//

import SwiftUI
import MeshGradient
import MeshGradientCHeaders

extension Playbar {
    typealias MeshColor = SIMD3<Float>

    struct backMeshGradient: View {
        
        var dominantColors: [Color]
        
        var meshColors: [simd_float3] {
            return dominantColors.map { $0.toSimdFloat3() }
        }
        
        var body: some View {
            
            MeshGradient(
                initialGrid: generatePlainGrid(),
                animatorConfiguration: .init(animationSpeedRange: 2 ... 3,
                meshRandomizer: MeshRandomizer(colorRandomizer: MeshRandomizer.arrayBasedColorRandomizer(availableColors: meshColors)))
            )
        }
        
        func generatePlainGrid(size: Int = 4) -> MeshGradientGrid<ControlPoint> {
            
            let preparationGrid = MeshGradientGrid<MeshColor>(repeating: .zero, width: size, height: size)
            
            var result = MeshGenerator.generate(colorDistribution: preparationGrid)
            
            for x in stride(from: 0, to: result.width, by: 1) {
                for y in stride(from: 0, to: result.height, by: 1) {
                    meshRandomizer.locationRandomizer(&result[x, y].location, x, y, result.width, result.height)
                    meshRandomizer.turbulencyRandomizer(&result[x, y].uTangent, x, y, result.width, result.height)
                    meshRandomizer.turbulencyRandomizer(&result[x, y].vTangent, x, y, result.width, result.height)
                    meshRandomizer.colorRandomizer(&result[x, y].color, result[x, y].color, x, y, result.width, result.height)
                }
            }
            return result
        }
    }
    
    struct AdjustableBlurView: NSViewRepresentable {
        var blurRadius: CGFloat

        func makeNSView(context: Context) -> NSVisualEffectView {
            let effectView = NSVisualEffectView()
            effectView.blendingMode = .withinWindow
            effectView.state = .active
            effectView.material = .hudWindow
            effectView.appearance = NSAppearance(named: .darkAqua)
            return effectView
        }

        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.75
                nsView.animator().alphaValue = min(max(blurRadius / 10.0, 0.0), 1.0)
            }
        }
    }
}

var meshColors: [simd_float3] {
    return [
        Color(hex: 0x808080).toSimdFloat3(),
        Color(hex: 0x808080).toSimdFloat3(),
        Color(hex: 0x808080).toSimdFloat3()
    ]
}

var meshRandomizer = MeshRandomizer(colorRandomizer: MeshRandomizer.arrayBasedColorRandomizer(availableColors: meshColors))

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

extension Color {
    // 将 SwiftUI 的 Color 转换为 simd_float3
    func toSimdFloat3() -> simd_float3 {
        // 将 Color 转换为 NSColor
        let nsColor = NSColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 转换为 simd_float3
        return simd_float3(Float(red), Float(green), Float(blue))
    }
}
