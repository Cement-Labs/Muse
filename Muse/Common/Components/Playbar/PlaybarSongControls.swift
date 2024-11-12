//
//  PlaybarSongControls.swift
//  Muse
//
//  Created by Tamerlan Satualdypov on 28.12.2023.
//

import SwiftUI

extension Playbar {
    struct SongControls: View {
        @EnvironmentObject private var musicPlayer: MusicPlayer
        
        @State private var isSliderHovered: Bool = false
        @State private var playbackTimePercentage: CGFloat = 0.0
        
        var body: some View {
            VStack(spacing: 4.0) {
                self.controls
                self.slider
            }
            .onChange(of: self.musicPlayer.playbackTime) { _, value in
                guard let duration = self.musicPlayer.currentSong?.duration else { return }
                self.playbackTimePercentage = value / duration
            }
        }
        
        // MARK: - Components
        
        private var controls: some View {
            HStack(spacing: 8.0) {
                Image(systemName: "shuffle")
                    .font(.system(size: 10.0, weight: .medium))
                    .foregroundStyle(self.musicPlayer.shuffleMode == .songs ? Color.pinkAccent : Color.secondaryText)
                    .tappable {
                        self.musicPlayer.shuffleMode.toggle()
                    }
                
                Group {
                    Image(systemName: "backward.fill")
                        .foregroundStyle(Color.secondaryText)
                        .tappable {
                            self.musicPlayer.skip(.backward)
                        }
                    
                    Group {
                        if self.musicPlayer.playbackState == .loading {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Color.secondaryText)
                                .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeating)
                        } else {
                            Image(systemName: self.musicPlayer.playbackState == .playing ? "pause.fill" : "play.fill")
                                .foregroundStyle(Color.secondaryText)
                                .tappable {
                                    Task {
                                        if self.musicPlayer.playbackState == .playing {
                                            self.musicPlayer.pause()
                                        } else {
                                            await self.musicPlayer.play()
                                        }
                                    }
                                }
                        }
                    }
                    .frame(width: 20.0)
                    
                    Image(systemName: "forward.fill")
                        .foregroundStyle(Color.secondaryText)
                        .tappable {
                            self.musicPlayer.skip(.forward)
                        }
                }
                .font(.system(size: 14.0, weight: .medium))
                
                Image(systemName: self.musicPlayer.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 10.0, weight: .medium))
                    .foregroundStyle(self.musicPlayer.repeatMode != .none ? Color.pinkAccent : Color.secondaryText)
                    .tappable {
                        self.musicPlayer.repeatMode.next()
                    }
            }
            .frame(height: 24.0)
        }
        
        private var slider: some View {
            HStack(spacing: 8.0) {
                Group {
                    if let duration = self.musicPlayer.currentSong?.duration, self.isSliderHovered {
                        Text((self.playbackTimePercentage * duration).minutesAndSeconds)
                            .font(.system(size: 10.0))
                            .foregroundStyle(Color.secondaryText)
                            .contentTransition(.numericText(value: duration))
                            .animation(.spring(), value: duration)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 24.0, height: 12.0)
                
                CustomSliderView(
                    value: Binding(
                        get: { playbackTimePercentage * (self.musicPlayer.currentSong?.duration ?? 0) },
                        set: { requestedTime in
                            guard let duration = self.musicPlayer.currentSong?.duration else { return }
                            playbackTimePercentage = requestedTime / duration
                            print("Slider value: \(requestedTime)")
                        }
                    ),
                    range: 0...(self.musicPlayer.currentSong?.duration ?? 1),
                    realTime: false,
                    onEditingChanged: { isEditing in
                        if isEditing {
                            self.musicPlayer.pause()
                        } else {
                            if let duration = self.musicPlayer.currentSong?.duration {
                                self.musicPlayer.seek(to: playbackTimePercentage * duration)
                            }
                            Task {
                                await self.musicPlayer.play()
                            }
                        }
                    }
                )
                .animation(.smooth(), value: self.musicPlayer.currentSong?.duration)
                .frame(width: 320)
                .onHover { hovered in
                    self.isSliderHovered = hovered
                }
                
                Group {
                    if let duration = self.musicPlayer.currentSong?.duration, self.isSliderHovered {
                        Text(duration.minutesAndSeconds)
                            .font(.system(size: 10.0))
                            .foregroundStyle(Color.secondaryText)
                            .contentTransition(.numericText(value: duration))
                            .animation(.spring(), value: duration)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 24.0, height: 12.0)
            }
            .frame(height: 12.0)
            .animation(.easeIn(duration: 0.2), value: self.isSliderHovered)
        }
    }
    
    struct FullSongControls: View {
        @EnvironmentObject private var musicPlayer: MusicPlayer
        
        @State private var isSliderHovered: Bool = false
        @State private var playbackTimePercentage: CGFloat = 0.0
        
        var body: some View {
            VStack(spacing: 18.0) {
                self.slider
                self.controls
            }
            .frame(width: 300, alignment: .center)
            .onChange(of: self.musicPlayer.playbackTime) { _, value in
                guard let duration = self.musicPlayer.currentSong?.duration else { return }
                self.playbackTimePercentage = value / duration
            }
        }
        
        // MARK: - Components
        
        private var controls: some View {
            HStack(spacing: 8.0) {
                Image(systemName: "shuffle")
                    .font(.system(size: 12.0, weight: .medium))
                    .foregroundStyle(self.musicPlayer.shuffleMode == .songs ? Color.pinkAccent : Color.white)
                    .tappable {
                        self.musicPlayer.shuffleMode.toggle()
                    }
                
                Spacer()
                
                Group {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 18.0, weight: .medium))
                        .foregroundStyle(Color.white)
                        .tappable {
                            self.musicPlayer.skip(.backward)
                        }
                    
                    Group {
                        if self.musicPlayer.playbackState == .loading {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20.0, weight: .medium))
                                .foregroundStyle(Color.white)
                                .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeating)
                        } else {
                            Image(systemName: self.musicPlayer.playbackState == .playing ? "pause.fill" : "play.fill")
                                .font(.system(size: 20.0, weight: .medium))
                                .foregroundStyle(Color.white)
                                .tappable {
                                    Task {
                                        if self.musicPlayer.playbackState == .playing {
                                            self.musicPlayer.pause()
                                        } else {
                                            await self.musicPlayer.play()
                                        }
                                    }
                                }
                        }
                    }
                    .frame(width: 20.0)
                    
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18.0, weight: .medium))
                        .foregroundStyle(Color.white)
                        .tappable {
                            self.musicPlayer.skip(.forward)
                        }
                }
                
                Spacer()
                
                Image(systemName: self.musicPlayer.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 12.0, weight: .medium))
                    .foregroundStyle(self.musicPlayer.repeatMode != .none ? Color.pinkAccent : Color.white)
                    .tappable {
                        self.musicPlayer.repeatMode.next()
                    }
            }
            .frame(width: 300, height: 24.0, alignment: .center)
        }
        
        private var slider: some View {
            HStack(spacing: .zero) {
                MusicProgressSlider(
                    value: Binding(
                        get: { playbackTimePercentage * (self.musicPlayer.currentSong?.duration ?? 0) },
                        set: { requestedTime in
                            guard let duration = self.musicPlayer.currentSong?.duration else { return }
                            playbackTimePercentage = requestedTime / duration
                        }
                    ),
                    current: (self.playbackTimePercentage * (self.musicPlayer.currentSong?.duration ?? 0)).minutesAndSeconds,
                    duration: self.musicPlayer.currentSong?.duration?.minutesAndSeconds ?? "-0:00",
                    inRange: 0...(self.musicPlayer.currentSong?.duration ?? 1),
                    activeFillColor: Color.white,
                    fillColor: Color.white.opacity(0.5),
                    emptyColor: Color.white.opacity(0.3),
                    height: 32
                ) { isEditing in
                    if isEditing {
                        if let duration = self.musicPlayer.currentSong?.duration {
                            self.musicPlayer.seek(to: playbackTimePercentage * duration)
                        }
                        Task {
                            await self.musicPlayer.play()
                        }
                    } else {
                        self.musicPlayer.pause()
                    }
                }
            }
            .frame(width: 300, height: 40, alignment: .center)
            .animation(.easeIn(duration: 0.2), value: self.isSliderHovered)
        }
    }
}
