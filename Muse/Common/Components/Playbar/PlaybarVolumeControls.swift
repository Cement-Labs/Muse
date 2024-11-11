//
//  PlaybarVolumeControls.swift
//  Muse
//
//  Created by Tamerlan Satualdypov on 29.12.2023.
//

import SwiftUI

extension Playbar {
    struct VolumeControls: View {
        @EnvironmentObject private var musicPlayer: MusicPlayer
        
        var body: some View {
            Group {
                if let volume = self.musicPlayer.volume {
                    self.slider(volume: volume)
                } else {
                    self.unavailable
                }
            }
        }
        
        // MARK: - Components
        
        private var unavailable: some View {
            Image(systemName: "speaker.slash.fill")
                .font(.system(size: 16.0, weight: .medium))
                .foregroundStyle(Color.secondaryText)
        }
        
        private func slider(volume: Float) -> some View {
            HStack(spacing: 8.0) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10.0, weight: .medium))
                    .foregroundStyle(Color.primaryText)
                
                CustomSliderView(
                    value: Binding(
                        get: { CGFloat(volume) },
                        set: { newVolume in
                            self.musicPlayer.volume = Float(newVolume)
                        }
                    ),
                    range: 0...1,
                    realTime: true
                )
                .frame(width: 64)
                .animation(.smooth(), value: volume)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10.0, weight: .medium))
                    .foregroundStyle(Color.primaryText)
            }
        }
    }
    
    struct FullVolumeControls: View {
        @EnvironmentObject private var musicPlayer: MusicPlayer
        
        var body: some View {
            Group {
                if let volume = self.musicPlayer.volume {
                    self.slider(volume: volume)
                } else {
                    self.unavailable
                }
            }
            .frame(width: 300, alignment: .center)
        }
        
        // MARK: - Components
        
        private var unavailable: some View {
            Image(systemName: "speaker.slash.fill")
                .font(.system(size: 12.0, weight: .medium))
                .foregroundStyle(Color.white)
        }
        
        private func slider(volume: Float) -> some View {
            HStack(spacing: 8.0) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 12.0, weight: .medium))
                    .foregroundStyle(Color.white)
                
                CustomSliderView(
                    value: Binding(
                        get: { CGFloat(volume) },
                        set: { newVolume in
                            self.musicPlayer.volume = Float(newVolume)
                        }
                    ),
                    range: 0...1,
                    realTime: true
                )
                .frame(width: 230)
                .animation(.smooth(), value: volume)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12.0, weight: .medium))
                    .foregroundStyle(Color.white)
            }
        }
    }
}
