//
//  MusicArtworkImage.swift
//  Muse
//
//  Created by Tamerlan Satualdypov on 08.01.2024.
//

import SwiftUI
import MusicKit
import DominantColors

struct MusicArtworkImage: View {
    
    private let artwork: Artwork?
    private let width: CGFloat
    private let height: CGFloat
    private let imageWidth: CGFloat
    private let imageHeight: CGFloat
    
    @State private var nsImage: NSImage? = nil
    @State private var isLoading = false
    @Binding var dominantColors: [Color]?
    
    init(artwork: Artwork?, width: CGFloat, height: CGFloat, imageWidth: CGFloat, imageHeight: CGFloat, dominantColors: Binding<[Color]?> = .constant(nil)) {
        self.artwork = artwork
        self.width = width
        self.height = height
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self._dominantColors = dominantColors
    }
    
    var body: some View {
        if let artwork = self.artwork, let url = artwork.url(width: Int(self.imageWidth), height: Int(self.imageWidth)) {
            if let nsImage = nsImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: self.width, height: self.height)
                    .onAppear {
                        if dominantColors != nil {
                            extractDominantColors(from: nsImage)
                        }
                    }
                    .onChange(of: url) { oldValue, newValue in
                        self.nsImage = nil
                    }
            } else {
                placeholder
                    .onAppear {
                        if !isLoading {
                            isLoading = true
                            loadArtworkImage(from: url)
                        }
                    }
            }
        } else {
            placeholder
        }
    }
    
    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.2)
            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .padding(12)
                .frame(maxWidth: 64, maxHeight: 64)
        }
        .frame(width: self.width, height: self.height)
    }
    
    private func loadArtworkImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.nsImage = image
                }
            }
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }.resume()
    }
    
    func extractDominantColors(from image: NSImage) {
        do {
            let colors = try DominantColors.dominantColors(nsImage: image, quality: .low, maxCount: 3, options: [.excludeBlack], sorting: .frequency)
            
            let processedColors = colors.map { nsColor in
                Color(red: Double(nsColor.redComponent),
                      green: Double(nsColor.greenComponent),
                      blue: Double(nsColor.blueComponent))
            }
            DispatchQueue.main.async {
                self.dominantColors = processedColors
            }
        } catch {
            print("Failed to extract colors: \(error)")
        }
    }
}
