//
//  AirPlayBar.swift
//  Muse
//
//  Created by 屈志健 on 2024/11/8.
//

import SwiftUI

struct AirPlayBar: View {
    @EnvironmentObject private var musicPlayer: MusicPlayer
    @State var selectedDevice: String = "Default"
    @State var availableDevices: [String] = []
    @Binding var isAirPlayBarPresented: Bool
    
    var body: some View {
        List(availableDevices, id: \.self) { device in
            Button(action: {
                selectedDevice = device
                changeAudioOutputDevice(to: device)
                isAirPlayBarPresented = false // 选择后关闭弹出框
            }) {
                HStack {
                    Text(device)
                    if device == selectedDevice {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            .buttonStyle(.borderless)
        }
        .listStyle(.plain)
        .onAppear {
            availableDevices = musicPlayer.getAudioOutputDevices()
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

