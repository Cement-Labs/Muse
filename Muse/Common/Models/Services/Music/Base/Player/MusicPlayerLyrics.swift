//
//  MusicPlayerLyrics.swift
//  Muse
//
//  Created by Xinshao_Air on 2024/11/10.
//

import LyricsService
import Foundation

extension MusicPlayer {
    
    func fileExists(atPath path: String) -> Bool {
        let fileManager = FileManager.default
        if let attributes = try? fileManager.attributesOfItem(atPath: path) {
            return attributes[.type] as? FileAttributeType == FileAttributeType.typeRegular
        }
        return false
    }
    
    func downloadLyrics(song: String, artist: String, timeout: Double) -> [Lyrics] {
        let searchReq = LyricsSearchRequest(searchTerm: .info(title: song, artist: artist), duration: timeout)
        let provider = LyricsProviders.Group()
        var list: [Lyrics] = []
        var count = 0
        let cancelable = provider.lyricsPublisher(request: searchReq).sink { doc in
            list.append(doc)
            count = count+1
        }
        var retry = 0
        while count < 1 {
            sleep(1)
            retry += 1
            if retry > 1 {
                count = 1
            }
        }
        cancelable.cancel()
        return list
    }
    
    func persist(_ lyricsData: String, to url: URL) {
        let fileManager = FileManager.default
        
        do {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: url.deletingLastPathComponent().path, isDirectory: &isDir) {
                if !isDir.boolValue {
                    return
                }
            } else {
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            }
            
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            try lyricsData.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func ReadFile(named name: String) throws -> String {
        guard let file = try FileHandle(forReadingAtPath: name)?.readToEnd() else {
            print("\(name) file not exist!")
            return ""
        }

        guard let data = String(data: file, encoding: .utf8) else {
            print("\(name) file context encode to utf8 failed!")
            return ""
        }
        return data
    }
}
