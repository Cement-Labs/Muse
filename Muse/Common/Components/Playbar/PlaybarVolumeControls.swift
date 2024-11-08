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
                
                Slider(
                    width: .constant(64.0),
                    percentage: .init(
                        get: { CGFloat(volume) },
                        set: { self.musicPlayer.volume = Float($0) }
                    )
                )
                
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
                .foregroundStyle(Color.secondaryText)
        }
        
        private func slider(volume: Float) -> some View {
            HStack(spacing: 8.0) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 12.0, weight: .medium))
                    .foregroundStyle(Color.primaryText)
                
                Slider(
                    width: .constant(230),
                    percentage: .init(
                        get: { CGFloat(volume) },
                        set: { self.musicPlayer.volume = Float($0) }
                    )
                )
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12.0, weight: .medium))
                    .foregroundStyle(Color.primaryText)
            }
        }
    }
}
