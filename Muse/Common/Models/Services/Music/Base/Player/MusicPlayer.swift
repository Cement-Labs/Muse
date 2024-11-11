//
//  MusicPlayer.swift
//  Muse
//
//  Created by Tamerlan Satualdypov on 19.02.2024.
//

import Foundation
import Combine
import MusicKit
import LyricsService
import AVFoundation

@MainActor
final class MusicPlayer: ObservableObject {
    typealias PlaybackStatus = MusicKit.MusicPlayer.PlaybackStatus
    typealias ShuffleMode = MusicKit.MusicPlayer.ShuffleMode
    typealias RepeatMode = MusicKit.MusicPlayer.RepeatMode
    
    enum ActionDirection {
        case forward
        case backward
    }
    
    enum PlaybackState {
        case playing
        case loading
        case paused
        case stopped
        
        init(playbackStatus: PlaybackStatus) {
            self = switch playbackStatus {
            case .playing: .playing
            case .paused: .paused
            case .stopped: .stopped
            default: .stopped
            }
        }
    }
    
    private let manager: MusicManager = .shared
    private let player: ApplicationMusicPlayer = .shared
    private let audio: Audio = .init()
    
    private var playerState: MusicKit.MusicPlayer.State?
    private var playerQueue: MusicKit.MusicPlayer.Queue?
    
    private var volumeCancellable: AnyCancellable?
    private var playbackTimeCancellable: AnyCancellable?
    private var playerStateCancellable: AnyCancellable?
    private var playerQueueCancellable: AnyCancellable?
    
    @Published var queue: [Song] = []
    @Published var playbackTime: TimeInterval = 0.0
    @Published var deviceIDMapping: [String: AudioDeviceID] = [:]
    @Published var lyricsDir = "/"+NSHomeDirectory().split(separator: "/")[0 ... 1].joined(separator: "/")+"/Music/Muse/Lyrics" // ~/Music
    
    @Published var currentSong: Song? = nil {
        didSet {
            self.playbackTime = 0.0
        }
    }
    
    @Published var volume: Float? = nil {
        didSet {
            self.audio.setVolume(self.volume)
        }
    }
    
    @Published private(set) var playbackState: PlaybackState = .stopped {
        didSet {
            self.updatePlaybackTimeObservation()
        }
    }
    
    @Published var shuffleMode: ShuffleMode = .off {
        didSet {
            self.player.state.shuffleMode = self.shuffleMode
        }
    }
    
    @Published var repeatMode: RepeatMode = .none {
        didSet {
            self.player.state.repeatMode = self.repeatMode
        }
    }
    
    init() {
        self.volumeCancellable = self.audio.volume
            .receive(on: DispatchQueue.main)
            .assign(to: \.volume, on: self)
        
        self.playerStateCancellable = self.player.state.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.updateState()
            }
        
        self.playerQueueCancellable = self.player.queue.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.updateQueue()
            }
    }
    
    func play(shuffleMode: ShuffleMode? = nil) async {
        guard !self.manager.subscription.canOffer else {
            return self.manager.subscription.offer()
        }
        
        // 下载歌词
        await downloadLyricsIfNeeded(for: self.player.queue.currentEntry?.item)
        
        if let shuffleMode = shuffleMode {
            self.shuffleMode = shuffleMode
        }
        
        self.playbackState = .loading
        
        try? await self.player.prepareToPlay()
        try? await self.player.play()
        
        self.playbackState = .playing
    }
    
    func play(item: PlayableMusicItem, shuffleMode: ShuffleMode? = nil) async {
        self.player.queue = [item]
        await downloadLyricsIfNeeded(for: item)
        await self.play(shuffleMode: shuffleMode)
    }
    
    func play(song: Song) async {
        self.player.queue = [song]
        await downloadLyricsIfNeeded(for: song)
        await self.play()
    }
    
    func play(songs: [Song], shuffleMode: ShuffleMode? = nil) async {
        self.player.queue = .init(for: songs)
        await downloadLyricsIfNeeded(for: songs.first)
        await self.play(shuffleMode: shuffleMode)
    }
    
    func skip(to song: Song) async {
        guard self.queue.contains(where: { $0.id == song.id }) else { return }
        
        self.player.queue = .init(self.player.queue.entries, startingAt: .init(song))
        await self.play()
    }
    
    func skip(_ direction: ActionDirection = .forward) {
        switch direction {
        case .forward:
            self.handleForwardSkipping()
        case .backward:
            self.handleBackwardSkipping()
        }
    }
    
    func seek(to time: TimeInterval) {
        self.playbackTime = time
        self.player.playbackTime = time
    }
    
    func pause() {
        guard self.playbackState != .paused else { return }
        self.player.pause()
    }
    
    func stop() {
        guard self.playbackState != .stopped else { return }
        self.player.stop()
    }
    
    func remove(song: Song) {
        self.player.queue.entries.removeAll { entry in
            guard case .song(let item) = entry.item else { return false }
            return item.id == song.id
        }
    }
    
    private func downloadLyricsIfNeeded(for song: PlayableMusicItem?) async {
        guard let song = song as? Song else {
            print("返回了")
            return
        }
        
        let lyricsFileName = "\(lyricsDir)/\(song.title) - \(song.artistName).lrcx"
        let fileURL = URL(fileURLWithPath: lyricsFileName)
        
        if !fileExists(atPath: lyricsFileName) {
            print("下载歌词: \(lyricsFileName)")
            
            let docs = downloadLyrics(song: song.title, artist: song.artistName, timeout: 225.2)
            
            if docs.count > 0 {
                let myData = docs[0].description
                
                persist(myData, to: fileURL)
                print("数据已成功写入文件")
            }
            
            let str = try? ReadFile(named: lyricsFileName)
            if let lrcx = str {
                print("\(lrcx)")
            } else {
                print("\(song.title) - \(song.artistName).lrcx 歌词文件不存在")
            }
        }
    }
    
    private func handleForwardSkipping() {
        Task {
            try await self.player.skipToNextEntry()
            
            if
                case .song(let song) = self.player.queue.entries.last?.item,
                song.id == self.currentSong?.id
            {
                self.player.queue.entries = []
            }
        }
    }
    
    private func handleBackwardSkipping() {
        if self.player.playbackTime >= 0.0 && self.player.playbackTime <= 1.0 {
            Task {
                try await self.player.skipToPreviousEntry()
            }
        } else {
            self.playbackTime = 0.0
            self.player.playbackTime = 0.0
        }
    }
    
    private func runPlaybackTimeObservation() {
        self.playbackTimeCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.playbackTime = self.player.playbackTime
            }
    }
    
    private func pausePlaybackTimeObservation() {
        self.playbackTimeCancellable = nil
    }
    
    private func stopPlaybackTimeObservation() {
        self.currentSong = nil
        self.playbackTimeCancellable = nil
    }
    
    private func updatePlaybackTimeObservation() {
        switch self.playbackState {
        case .playing:
            self.runPlaybackTimeObservation()
        case .paused:
            self.pausePlaybackTimeObservation()
        case .stopped:
            self.stopPlaybackTimeObservation()
        default:
            break
        }
    }
    
    private func updateState() {
        self.playbackState = .init(playbackStatus: self.player.state.playbackStatus)
        self.shuffleMode = self.player.state.shuffleMode ?? .off
        self.repeatMode = self.player.state.repeatMode ?? .none
    }
    
    private func updateQueue() {
        self.queue = self.player.queue.entries.compactMap { entry in
            guard
                let item = entry.item,
                case .song(let song) = item
            else { return nil }
            
            return song
        }
        
        if case .song(let song) = self.player.queue.currentEntry?.item {
            self.currentSong = song
        } else {
            self.currentSong = nil
        }
    }
    
    func getDeviceID(for device: String) -> AudioDeviceID? {
        return deviceIDMapping[device]
    }
    
    func getAudioOutputDevices() -> [String] {
        var deviceList: [String] = []
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                                    &propertyAddress,
                                                    0, nil,
                                                    &dataSize)
        
        if status != noErr {
            print("Error in getting device list")
            return deviceList
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var audioDevices = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                            &propertyAddress,
                                            0, nil,
                                            &dataSize,
                                            &audioDevices)
        
        if status != noErr {
            print("Error in getting device list")
            return deviceList
        }
        
        var deviceIDMapping: [String: AudioDeviceID] = [:]

        for device in audioDevices {
            var isOutputDevice: UInt32 = 0
            var size = UInt32(MemoryLayout<UInt32>.size)
            
            var outputPropertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            status = AudioObjectGetPropertyData(device,
                                                &outputPropertyAddress,
                                                0, nil,
                                                &size,
                                                &isOutputDevice)
            
            if status == noErr && isOutputDevice > 0 {
                var deviceName: CFString = "" as CFString
                var nameSize = UInt32(MemoryLayout<CFString>.size)
                
                var namePropertyAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioObjectPropertyName,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: kAudioObjectPropertyElementMain
                )
                
                status = AudioObjectGetPropertyData(device,
                                                    &namePropertyAddress,
                                                    0, nil,
                                                    &nameSize,
                                                    &deviceName)
                
                if status == noErr {
                    let deviceNameString = deviceName as String
                    deviceList.append(deviceNameString)
                    
                    deviceIDMapping[deviceNameString] = device
                }
            }
        }
        
        self.deviceIDMapping = deviceIDMapping
        
        return deviceList
    }
    
    func setAudioOutputDevice(deviceID: AudioDeviceID) {
        var outputDeviceID = deviceID
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                                &propertyAddress,
                                                0, nil,
                                                UInt32(MemoryLayout.size(ofValue: outputDeviceID)),
                                                &outputDeviceID)
        
        if status != noErr {
            print("Error in setting output device")
        }
    }
}

extension MusicKit.MusicPlayer.State: @retroactive Equatable {
    public static func == (lhs: MusicKit.MusicPlayer.State, rhs: MusicKit.MusicPlayer.State) -> Bool {
        return
            lhs.playbackStatus == rhs.playbackStatus &&
            lhs.playbackRate == rhs.playbackRate &&
            lhs.shuffleMode == rhs.shuffleMode &&
            lhs.repeatMode == rhs.repeatMode &&
            lhs.audioVariant == rhs.audioVariant
    }
}

