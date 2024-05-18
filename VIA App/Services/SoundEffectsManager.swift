//
//  SoundEffectsManager.swift
//  VIA App
//
//  Created by Matheus Oliveira on 4/12/23.
//

import Foundation
import AVFoundation

class SoundEffectsManager {
    
    static var sharedSoundEffectsManager = SoundEffectsManager()
    var audioPlayer: AVAudioPlayer?
    
    func playSoundLoop(sound: String, audioType: String, volume: Float) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: audioType) else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = audioPlayer else { return }
            
            player.volume = volume
            player.numberOfLoops = -1
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playSound(sound: String, audioType: String, volume: Float) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: audioType) else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = audioPlayer else { return }
            
            player.volume = volume
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopSound() {
        guard let player = audioPlayer else { return }
        
        player.stop()
    }
}
