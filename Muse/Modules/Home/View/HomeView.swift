//
//  HomeView.swift
//  Muse
//
//  Created by Tamerlan Satualdypov on 27.12.2023.
//

import SwiftUI
import MusicKit

struct HomeView: View {
    private struct Value: Hashable {
        let recommendations: [MusicPersonalRecommendationItem]
        let charts: MusicChartsCompilation?
    }
    
    private let sectionProvider: HomeSectionProvider = .init()
    
    @EnvironmentObject private var musicManager: MusicManager
    @EnvironmentObject private var musicCatalog: MusicCatalog
    @EnvironmentObject private var router: Router
    
    @State private var value: LoadableValue<Value> = .init()
    
    var body: some View {
        NavigationStack(path: self.router.bindablePath(for: .home)) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: .s6) {
                    Text("Listen Now")
                        .font(.system(size: 32.0, weight: .bold))
                        .foregroundStyle(Color.primaryText)
                    
                    Group {
                        switch self.value.status {
                        case .idle, .loading, .error:
                            self.skeleton
                        case .loaded(let content):
                            self.content(content)
                        }
                    }
                }
                .padding(.all, 24.0)
            }
            .scrollDisabled(!self.value.status.isLoaded)
            .navigationDestination(for: Artist.self) { artist in
                ArtistDetailsView(artist: artist)
                    .id(artist.id)
            }
            .navigationDestination(for: Album.self) { album in
                AlbumDetailsView(album: album)
                    .id(album.id)
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailsView(playlist: playlist)
                    .id(playlist.id)
            }
        }
        .onAppear(perform: self.loadValue)
        .onChange(of: self.musicManager.authorization.status) { _, _ in
            self.loadValue()
        }
    }
    
    // MARK: - Content
    
    private func content(_ value: Value) -> some View {
        Group {
            self.sectionProvider.section(for: \.recommendations, value: value.recommendations)
            
            if let charts = value.charts {
                self.sectionProvider.section(for: \.charts, value: charts)
            }
        }
    }
    
    private var skeleton: some View {
        Group {
            self.sectionProvider.skeleton(for: \.recommendations)
            self.sectionProvider.skeleton(for: \.charts)
        }
    }
    
    // MARK: - Utility
    
    private func loadValue() {
        self.value.load {
            return .init(
                recommendations: try await self.musicCatalog.personal.recommendations,
                charts: try await self.musicCatalog.charts.compilation()
            )
        }
    }
}
