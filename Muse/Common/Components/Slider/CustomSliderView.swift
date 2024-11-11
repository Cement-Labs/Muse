//
//  CustomSliderView.swift
//  Muse
//
//  Created by Xinshao_Air on 2024/11/11.
//

import SwiftUI

struct CustomSliderView: View {
    
    @Binding var value: Double
    let range: ClosedRange<Double>
    var realTime: Bool
    var onEditingChanged: ((Bool) -> Void)?
    
    @State private var hovering = false
    @State private var isDragging = false
    @State private var temporaryValue: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Group {
                    Rectangle()
                        .foregroundColor(.secondary.opacity(0.5))
                    Rectangle()
                        .foregroundColor(.white)
                        .frame(width: geometry.size.width * CGFloat(normalizedValue()))
                }
                .frame(height: 4).cornerRadius(12)
                
                if hovering || isDragging {
                    Rectangle()
                        .foregroundColor(.white)
                        .blendMode(.destinationOut)
                        .frame(width: 6, height: 10)
                        .offset(x: geometry.size.width * CGFloat((self.isDragging ? self.temporaryValue : self.value - range.lowerBound) / (range.upperBound - range.lowerBound)) - 3)
                }
                
                Rectangle()
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .opacity(hovering || isDragging ? 1.0 : 0.00001)
                    .frame(width: 4, height: 12)
                    .offset(x: geometry.size.width * CGFloat((self.isDragging ? self.temporaryValue : self.value - range.lowerBound) / (range.upperBound - range.lowerBound)) - 2)
            }
            .onHover { hovering in
                withAnimation(.snappy(duration: 0.45)) {
                    self.hovering = hovering
                }
            }
            .compositingGroup()
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { gestureValue in
                    let newLocation = Double(gestureValue.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                    self.temporaryValue = min(max(range.lowerBound, newLocation), range.upperBound)
                    if realTime {
                        self.value = self.temporaryValue
                    }
                    self.isDragging = true
                    onEditingChanged?(true)
                }
                .onEnded { _ in
                    self.value = self.temporaryValue
                    self.isDragging = false
                    onEditingChanged?(false)
                }
            )
        }
        .frame(height: 15, alignment: .center)
    }
    
    func normalizedValue() -> Double {
        let delta = range.upperBound - range.lowerBound
        guard delta > 0 else { return 0.0 }
        
        let currentValue = self.isDragging ? self.temporaryValue : self.value
        return min(max((currentValue - range.lowerBound) / delta, 0), 1)
    }
}
