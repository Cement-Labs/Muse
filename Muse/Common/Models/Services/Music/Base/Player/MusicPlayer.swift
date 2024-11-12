//
//  MusicPlayer.swift
//  Muse
//
//  Created by Tamerlan Satualdypov on 19.02.2024.
//

import Foundation
import Combine
import MusicKit
import MusadoraKit
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
    
    // Using AvPlayer can solve some problems. For example, it can obtain audio information to achieve audio visualization.
    /*
    private var avPlayer: AVPlayer
    private var playerItem: AVPlayerItem?
    private var audioProcessingTap: MTAudioProcessingTap?
    private var playerShouldNextObserver: NSObjectProtocol?
    */
    
    private let manager: MusicManager = .shared
    private let player: ApplicationMusicPlayer = .shared
    private let audio: Audio = .init()
    
    private var playerState: MusicKit.MusicPlayer.State?
    private var playerQueue: MusicKit.MusicPlayer.Queue?
    
    private var volumeCancellable: AnyCancellable?
    private var playbackTimeCancellable: AnyCancellable?
    private var playerStateCancellable: AnyCancellable?
    private var playerQueueCancellable: AnyCancellable?
    
    // This part is used to try playing with AVPlayer.
    /*
    @Published var isPaused = false
    @Published var currentSongID: String?
    @Published var content = [(Track, URL)]()
    @Published var currentTrackIndex: Int = 0
     */
    
    @Published var queue: [Song] = []
    @Published var playbackTime: TimeInterval = 0.0
    @Published var deviceIDMapping: [String: AudioDeviceID] = [:]
    // @Published var lyricsDir = "/"+NSHomeDirectory().split(separator: "/")[0 ... 1].joined(separator: "/")+"/Music/Muse/Lyrics" // ~/Music
    
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
        // self.avPlayer = AVPlayer()
        
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
    
    // MARK: - AVPlayer Test
    /*
    func togglePlayback() {
        switch avPlayer.timeControlStatus {
            case .paused:
                self.avPlay()
                self.isPaused = false
                self.playbackState = .paused
            
            case .waitingToPlayAtSpecifiedRate:
                self.playbackState = .loading
            
            case .playing:
                self.avPause()
                self.isPaused = true
                self.playbackState = .playing
            
            @unknown default:
                break
        }
    }
    
    private func getTrackListing(from playlist: Playlist) async -> Tracks? {
        let detailedPlaylist = try? await playlist.with(.tracks)
        if let tracks = detailedPlaylist?.tracks {
            return tracks
        }
        return nil
    }
    
    func avPlay(song: Song) {
        let url = song.previewAssets?.first?.url
        
        avPlayer.replaceCurrentItem(with: nil)
        let playerItem = AVPlayerItem(url: url ?? URL(fileURLWithPath: Bundle.main.path(forResource: "SpaceWalker", ofType: "m4a")!))
        
        self.avPlay(playerItem: playerItem)
        self.playbackState = .playing
    }
    
    func avPlay(songs: [Song], shuffleMode: ShuffleMode? = nil) async {
        self.queue = songs
        if let firstSong = songs.first, let url = firstSong.previewAssets?.first?.url {
            let playerItem = AVPlayerItem(url: url)
            self.avPlay(playerItem: playerItem)
        }
        
       self.avPlay(shuffleMode: shuffleMode)
    }
    
    //TODO: Find a way to play PlayableMusicItem using AVPlayer.
    /*
    func avPlay(item: PlayableMusicItem, shuffleMode: ShuffleMode? = nil) async {
        if let url = item.previewAssets?.first?.url {
            let playerItem = AVPlayerItem(url: url)
            self.avPlay(playerItem: playerItem, shuffleMode: shuffleMode)
        }
    }
    */
    
    func avPlay(playerItem: AVPlayerItem, shuffleMode: ShuffleMode? = nil) {
        if let shuffleMode = shuffleMode {
            self.shuffleMode = shuffleMode
        }
        self.addAudioProcessingTap(to: playerItem)
        self.avPlayer.replaceCurrentItem(with: playerItem)
        self.avPlayer.play()
    }
    
    func avPlay(shuffleMode: ShuffleMode? = nil) {
        if let shuffleMode = shuffleMode {
            self.shuffleMode = shuffleMode
        }
        self.avPlay()
        self.playbackState = .playing
    }
    
    func avPlay(playerItem: AVPlayerItem) {
        self.addAudioProcessingTap(to: playerItem)
        self.avPlayer.replaceCurrentItem(with: playerItem)
        self.avPlayer.play()
    }
    
    func avPlay() {
        self.avPlayer.play()
    }
    
    func avPause() {
        self.avPlayer.pause()
    }
    
    // Method for obtaining audio information of AVPlayer.
    private func addAudioProcessingTap(to playerItem: AVPlayerItem) {
        guard let audioTrack = playerItem.asset.tracks(withMediaType: .audio).first else {
            print("Audio track not found")
            return
        }
        
        var callbacks = MTAudioProcessingTapCallbacks(
            //Only global objC callbacks can be used.
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: nil,
            init: tapInitCallback,
            finalize: tapFinalizeCallback,
            prepare: tapPrepareCallback,
            unprepare: tapUnprepareCallback,
            process: tapProcessCallback
        )
        
        var audioProcessingTap: Unmanaged<MTAudioProcessingTap>?
        let status = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &audioProcessingTap)
        
        if status == noErr, let tap = audioProcessingTap {
            let audioParams = AVMutableAudioMixInputParameters(track: audioTrack)
            audioParams.audioTapProcessor = tap.takeUnretainedValue()
            
            let audioMix = AVMutableAudioMix()
            audioMix.inputParameters = [audioParams]
            playerItem.audioMix = audioMix
        } else {
            print("Failed to create MTAudioProcessingTap")
        }
    }
    */
    // MARK: - TestED
    
    func play(shuffleMode: ShuffleMode? = nil) async {
        guard !self.manager.subscription.canOffer else {
            return self.manager.subscription.offer()
        }
        
        // Only testing.
        /*
        await downloadLyricsIfNeeded(for: song)
        */
        
        if let shuffleMode = shuffleMode {
            self.shuffleMode = shuffleMode
        }
        
        self.playbackState = .loading
        
        try? await self.player.prepareToPlay()
        try? await self.player.play()
        
        self.playbackState = .playing
    }
    
    // Search it, if need Change
    func play(item: PlayableMusicItem, shuffleMode: ShuffleMode? = nil) async {
        self.player.queue = [item]
        // Only testing.
        /*
        await downloadLyricsIfNeeded(for: song)
        */
        await self.play(shuffleMode: shuffleMode)
    }
    
    // Search it, if need Change
    func play(song: Song) async {
        self.player.queue = [song]
        // Only testing.
        /*
        await downloadLyricsIfNeeded(for: song)
        */
        await self.play()
    }
    
    func play(songs: [Song], shuffleMode: ShuffleMode? = nil) async {
        self.player.queue = .init(for: songs)
        // Only testing.
        /*
        await downloadLyricsIfNeeded(for: song)
        */
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

// MARK: - AVPlayer CalculatePower Extension
/*
var powerLevel: Float = -160

// The callback function must be a global C function.
func tapInitCallback(
    tap: MTAudioProcessingTap,
    clientInfo: UnsafeMutableRawPointer?,
    tapStorageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) {
    print("Tap Initialized")
}

func tapFinalizeCallback(tap: MTAudioProcessingTap) {
    print("Tap Finalized")
}

func tapPrepareCallback(
    tap: MTAudioProcessingTap,
    maxFrames: CMItemCount,
    processingFormat: UnsafePointer<AudioStreamBasicDescription>
) {
    print("Tap Prepared")
}

func tapUnprepareCallback(tap: MTAudioProcessingTap) {
    print("Tap Unprepared")
}

func tapProcessCallback(
    tap: MTAudioProcessingTap,
    numberFrames: CMItemCount,
    flags: MTAudioProcessingTapFlags,
    bufferListInOut: UnsafeMutablePointer<AudioBufferList>,
    frameCountOut: UnsafeMutablePointer<CMItemCount>,
    flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>
) {
    // Obtain audio samples
    let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, frameCountOut)
    
    if status != noErr {
        print("Error getting source audio: \(status)")
        return
    }

    // Directly access the mutable AudioBufferList through bufferListInOut.
    let audioBufferList = bufferListInOut.pointee
    let buffers = UnsafeBufferPointer(start: &bufferListInOut.pointee.mBuffers, count: Int(audioBufferList.mNumberBuffers))

    for buffer in buffers {
        let frameLength = Int(frameCountOut.pointee)
        guard let audioData = buffer.mData?.assumingMemoryBound(to: Float.self) else {
            continue
        }
        
        let power = calculatePower(from: audioData, frameLength: frameLength)
        powerLevel = power
    }
}

// Auxiliary function for calculating power
func calculatePower(from audioData: UnsafePointer<Float>, frameLength: Int) -> Float {
    var totalPower: Float = 0
    for i in 0..<frameLength {
        totalPower += audioData[i] * audioData[i]
    }
    
    let averagePower = totalPower / Float(frameLength)
    let powerInDb = 10 * log10(averagePower)
    
    return powerInDb
}
*/
