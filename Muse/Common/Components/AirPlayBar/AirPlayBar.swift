//
//  AirPlayBar.swift
//  Muse
//
//  Created by Xinshao_Air on 2024/11/8.
//

import SwiftUI

struct AirPlayBar: View {
    @EnvironmentObject private var musicPlayer: MusicPlayer
    @State var selectedDevice: String = "Default"
    @State var availableDevices: [String] = []
    @Binding var isAirPlayBarPresented: Bool
    
    var body: some View {
        VStack(spacing: 0.0) {
            ScrollView {
                LazyVStack(spacing: 8.0) {
                    ForEach(self.availableDevices, id: \.self) { device in
                        Item(
                            selectedDevice: $selectedDevice,
                            isAirPlayBarPresented: $isAirPlayBarPresented,
                            device: device
                        )
                    }
                }
                .padding(.all, 16.0)
            }
        }
        .frame(width: 256.0, height: 450.0)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 12.0))
        .border(style: .quinaryFill, cornerRadius: 12.0)
        .onAppear {
            availableDevices = musicPlayer.getAudioOutputDevices()
        }
    }
}

extension AirPlayBar {
    struct Item: View {
        
        @EnvironmentObject private var musicPlayer: MusicPlayer
        @State private var isHovered: Bool = false
        
        @Binding var selectedDevice: String
        @Binding var isAirPlayBarPresented: Bool
        var device: String
        
        var body: some View {
            HStack {
                HStack(spacing: 12.0) {
                    ZStack {
                        Color.secondary.opacity(0.2)
                        
                        Image(systemName: "speaker.wave.2.fill")
                    }
                    .transition(.opacity)
                    .frame(width: 40.0, height: 40.0)
                    .clipShape(.rect(cornerRadius: 8.0))
                    .border(style: .quinaryFill, cornerRadius: 8.0)
                    
                    Text(self.device)
                        .lineLimit(1)
                        .font(.system(size: 12.0))
                        .foregroundStyle(Color.primary)
                        .opacity(self.device == selectedDevice ? 1.0 : 0.4)
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeIn(duration: 0.2), value: self.isHovered)
            }
            .onHover { hovering in
                self.isHovered = hovering
            }
            .tappable {
                selectedDevice = device
                changeAudioOutputDevice(to: self.device)
                isAirPlayBarPresented = false
            }
        }
        
        func changeAudioOutputDevice(to device: String) {
            guard let deviceID = musicPlayer.getDeviceID(for: device) else {
                print("Failed to get device ID for \(device)")
                return
            }
            musicPlayer.setAudioOutputDevice(deviceID: deviceID)
        }
    }
}
