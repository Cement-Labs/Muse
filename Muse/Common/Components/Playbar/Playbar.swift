//
//  Playbar.swift
//  Muse
//
//  Created by Tamerlan Satualdypov on 28.12.2023.
//

import SwiftUI
import simd

struct Playbar: View {
    static let height: CGFloat = 70.0
    
    @EnvironmentObject private var musicPlayer: MusicPlayer
    @EnvironmentObject private var router: Router
    
    @Binding var showPlayView: Bool
    @State var isQueueBarPresented: Bool = false
    @State var isAirPlayBarPresented: Bool = false
    @State var ishowLy: Bool = false
    @State var dominantColors: [Color] = [.white, .white, .white]

    @Namespace private var animation
    
    var parentGeometry: GeometryProxy
    
    var body: some View {
        ZStack {
            if showPlayView {
                backMeshGradient(dominantColors: dominantColors)
                AdjustableBlurView(blurRadius: ishowLy ? 0 : 20)
            }
            HStack(alignment: .center, spacing: 10) {
                VStack(spacing: 20.0) {
                    Group {
                        if let currentSong = self.musicPlayer.currentSong {
                            MusicArtworkImage(
                                artwork: currentSong.artwork,
                                width: showPlayView ? (self.musicPlayer.playbackState == .playing ? 300 : 250) : 36.0,
                                height: showPlayView ? (self.musicPlayer.playbackState == .playing ? 300 : 250) : 36.0,
                                dominantColors: Binding($dominantColors)
                            )
                            .border(style: .quinaryFill, cornerRadius: 8.0)
                            .clipShape(RoundedRectangle(cornerRadius: showPlayView ? 12.5 : 8.0))
                        } else {
                            RoundedRectangle(cornerRadius: 12.5)
                                .frame(width: showPlayView ? 300 : 36.0, height: showPlayView ? 300 : 36.0)
                                .clipShape(RoundedRectangle(cornerRadius: showPlayView ? 12.5 : 8.0))
                        }
                    }
                    .frame(width: showPlayView ? 300 : 36.0, height: showPlayView ? 300 : 36.0, alignment: .center)
                    .shadow(
                        color: showPlayView ? .black.opacity(0.35) : Color.clear,
                        radius: self.musicPlayer.playbackState == .playing ? 25 : 10,
                        x:0, y: 5
                    )
                    .animation(.spring(duration: 0.65, bounce: 0.45, blendDuration: 0.75), value: self.musicPlayer.playbackState == .playing)
                    .onTapGesture {
                        withAnimation(.smooth(duration: 0.45)) {
                            showPlayView.toggle()
                        }
                    }
                    
                    if showPlayView {
                        FullSongPreview(
                            showPlayView: $showPlayView,
                            animationNamespace: animation
                        )
                        
                        FullSongControls()
                            .matchedGeometryEffect(id: "SongControls", in: animation)
                        
                        FullVolumeControls()
                            .matchedGeometryEffect(id: "VolumeControls", in: animation)
                    }
                }
                
                if !showPlayView {
                    SongPreview(
                        showPlayView: $showPlayView,
                        animationNamespace: animation
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: showPlayView ? .center :.leading)
            
            if !showPlayView {
                SongControls()
                    .matchedGeometryEffect(id: "SongControls", in: animation)
            }
            
            if showPlayView {
                Group {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 18.0))
                        .foregroundStyle(showPlayView ? Color.white : Color.secondaryText)
                        .tappable {
                            ishowLy.toggle()
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: showPlayView ? .bottomLeading : .leading)
                .padding([.bottom, .horizontal], showPlayView ? 16 : 0)
            }
            
            HStack(spacing: 18)  {
                if !showPlayView {
                    VolumeControls()
                        .matchedGeometryEffect(id: "VolumeControls", in: animation)
                }
                
                Image(systemName: "list.bullet")
                    .font(.system(size: 18.0))
                    .foregroundStyle(showPlayView ? Color.white : Color.secondaryText)
                    .tappable {
                        self.isQueueBarPresented.toggle()
                    }
                    .popover(isPresented: $isQueueBarPresented) {
                        QueueBar()
                    }
                
                Image(systemName: "airplay.audio")
                    .font(.system(size: 18.0))
                    .foregroundStyle(showPlayView ? Color.white : Color.secondaryText)
                    .tappable {
                        self.isAirPlayBarPresented.toggle()
                    }
                    .popover(isPresented: $isAirPlayBarPresented) {
                        AirPlayBar(isAirPlayBarPresented: $isAirPlayBarPresented)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: showPlayView ? .bottomTrailing : .trailing)
            .padding([.bottom, .horizontal], showPlayView ? 16 : 0)
        }
        .padding(.horizontal, showPlayView ? 0 : 16)
        .frame(height: showPlayView ? parentGeometry.size.height : Self.height)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.ultraThickMaterial)
        .clipShape(.rect(cornerRadius: 12.0))
        .border(style: .quinaryFill, cornerRadius: 12.0)
    }
}

struct Playbar_Preview: PreviewProvider {
    @State static var showPlayView = true
    
    static var previews: some View {
        GeometryReader { geometry in
            Playbar(showPlayView: $showPlayView, parentGeometry: geometry)
                .environmentObject(MusicPlayer())
        }
        .frame(minWidth: 1080.0, minHeight: 600.0)
    }
}


