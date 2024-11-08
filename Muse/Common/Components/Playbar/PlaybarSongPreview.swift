//
//  PlaybarSongPreview.swift
//  Muse
//
//  Created by Tamerlan Satualdypov on 28.12.2023.
//

import SwiftUI
import MusicKit

extension Playbar {
    struct SongPreview: View {
        @EnvironmentObject private var musicPlayer: MusicPlayer
        @EnvironmentObject private var router: Router
        
        @Binding var showPlayView: Bool
        
        var animationNamespace: Namespace.ID
        
        var body: some View {
            Group {
                if let currentSong = self.musicPlayer.currentSong {
                    self.content(currentSong)
                } else {
                    self.emptyContent
                }
            }
        }
        
        // MARK: - Components
        
        private var emptyContent: some View {
            VStack(alignment: .leading, spacing: 0.0) {
                Text("No song to play")
                    .font(.system(size: 12.0, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
            }
        }
        
        private func content(_ song: Song) -> some View {
            VStack(alignment: .leading, spacing: 0.0) {
                Text(song.title)
                    .font(.system(size: 12.0, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
                
                Text(song.artistName)
                    .font(.system(size: 10.0, weight: .medium))
                    .foregroundStyle(Color.secondaryText)
            }
            .matchedGeometryEffect(id: "SongInfo", in: animationNamespace)
        }
    }
    
    struct FullSongPreview: View {
        @EnvironmentObject private var musicPlayer: MusicPlayer
        @EnvironmentObject private var router: Router
        
        @Binding var showPlayView: Bool
        
        var animationNamespace: Namespace.ID
        
        var body: some View {
            Group {
                if let currentSong = self.musicPlayer.currentSong {
                    self.content(currentSong)
                } else {
                    self.emptyContent
                }
            }
            .frame(minWidth: 240.0)
        }
        
        // MARK: - Components
        
        private var emptyContent: some View {
            VStack(alignment: .leading, spacing: 0.0) {
                Text("No song to play")
                    .font(.system(size: 12.0, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
            }
        }
        
        private func content(_ song: Song) -> some View {
            
            VStack(alignment: .leading, spacing: .zero) {
                Text(song.title)
                    .font(.system(size: 20.0, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
                
                Text(song.artistName)
                    .font(.system(size: 12.0, weight: .medium))
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(width: 300, alignment: .leading)
            .matchedGeometryEffect(id: "SongInfo", in: animationNamespace)
        }
    }
}
