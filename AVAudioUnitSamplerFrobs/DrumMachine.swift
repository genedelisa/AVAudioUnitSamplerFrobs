//
//  SamplerSequence.swift
//  AVAudioUnitSamplerFrobs
//
//  Created by Gene De Lisa on 1/13/16.
//  Copyright © 2016 Gene De Lisa. All rights reserved.
//

import Foundation
import AVFoundation

class DrumMachine: NSObject {
    
    var engine: AVAudioEngine!
    
    var sampler: AVAudioUnitSampler!
    
    var sequencer: AVAudioSequencer!
    
    override init() {
        super.init()
        
        engine = AVAudioEngine()
        
        sampler = AVAudioUnitSampler()
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        setupSequencer()
        
        loadPreset()
        
        addObservers()
        
        startEngine()
        
        print(self.engine)
        
        setSessionPlayback()
    }
    
    
    func setupSequencer() {
        
        self.sequencer = AVAudioSequencer(audioEngine: self.engine)
        
        let options = AVMusicSequenceLoadOptions()
        if let fileURL = Bundle.main.url(forResource: "chromatic", withExtension: "mid") {
            do {
                try sequencer.load(from: fileURL, options: options)
                print("loaded \(fileURL)")
            } catch {
                print("something screwed up \(error)")
                return
            }
        }
        
        sequencer.prepareToPlay()
        print(sequencer)
    }
    
    func play() {
        if sequencer.isPlaying {
            stop()
        }
        
        sequencer.currentPositionInBeats = TimeInterval(0)
        
        do {
            try sequencer.start()
        } catch {
            print("cannot start \(error)")
        }
    }
    
    func stop() {
        sequencer.stop()
    }
    
    // load from the bundle or documents directory only
    // https://forums.developer.apple.com/message/20748#20643
    func loadPreset() {
        
        guard let preset = Bundle.main.url(forResource: "Drums", withExtension: "aupreset") else {
            print("could not load aupreset")
            return
        }
        print("loaded preset \(preset)")
        
        do {
            try sampler.loadInstrument(at: preset)
        } catch {
            print("error loading preset \(error)")
        }
    }
    
    
    func setSessionPlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try
                audioSession.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
        } catch {
            print("couldn't set category \(error)")
            return
        }
        
        do {
            try audioSession.setActive(true)
        } catch {
            print("couldn't set category active \(error)")
            return
        }
    }
    
    func startEngine() {
        
        if engine.isRunning {
            print("audio engine already started")
            return
        }
        
        do {
            try engine.start()
            print("audio engine started")
        } catch {
            print("oops \(error)")
            print("could not start audio engine")
        }
    }
    
    // MARK: - Notifications
    
    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(DrumMachine.engineConfigurationChange(_:)),
                                               name: NSNotification.Name.AVAudioEngineConfigurationChange,
                                               object: engine)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(DrumMachine.sessionInterrupted(_:)),
                                               name: NSNotification.Name.AVAudioSessionInterruption,
                                               object: engine)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(DrumMachine.sessionRouteChange(_:)),
                                               name: NSNotification.Name.AVAudioSessionRouteChange,
                                               object: engine)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVAudioEngineConfigurationChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVAudioSessionInterruption,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVAudioSessionRouteChange,
                                                  object: nil)
    }
    
    
    // MARK: notification callbacks
    @objc func engineConfigurationChange(_ notification: Notification) {
        print("engineConfigurationChange")
    }
    
    @objc func sessionInterrupted(_ notification: Notification) {
        print("audio session interrupted")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = notification.userInfo as? [String: Any?] {
            if let reason = userInfo[AVAudioSessionInterruptionTypeKey] as? AVAudioSessionInterruptionType {
                switch reason {
                case .began:
                    print("began")
                case .ended:
                    print("ended")
                }
            }
        }
    }
    
    @objc func sessionRouteChange(_ notification: Notification) {
        print("sessionRouteChange")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = notification.userInfo as? [String: Any?] {
            
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSessionRouteChangeReason {
                
                print("audio session route change reason \(reason)")
                
                switch reason {
                case .categoryChange: print("CategoryChange")
                case .newDeviceAvailable:print("NewDeviceAvailable")
                case .noSuitableRouteForCategory:print("NoSuitableRouteForCategory")
                case .oldDeviceUnavailable:print("OldDeviceUnavailable")
                case .override: print("Override")
                case .wakeFromSleep:print("WakeFromSleep")
                case .unknown:print("Unknown")
                case .routeConfigurationChange:print("RouteConfigurationChange")
                }
            }
            
            if let previous = userInfo[AVAudioSessionRouteChangePreviousRouteKey] {
                print("audio session route change previous \(String(describing: previous))")
            }
        }
    }
    
    
    func createMusicSequence() -> MusicSequence? {
        
        var s: MusicSequence?
        var status = NewMusicSequence(&s)
        if status != noErr {
            print("\(#line) bad status \(status) creating sequence")
        }
        
        if let musicSequence = s {
            
            // add a track
            var t: MusicTrack?
            status = MusicSequenceNewTrack(musicSequence, &t)
            if status != noErr {
                print("error creating track \(status)")
            }
            
            if let track = t {
                // bank select msb
                var chanmess = MIDIChannelMessage(status: 0xB0, data1: 0, data2: 0, reserved: 0)
                status = MusicTrackNewMIDIChannelEvent(track, 0, &chanmess)
                if status != noErr {
                    print("creating bank select event \(status)")
                }
                // bank select lsb
                chanmess = MIDIChannelMessage(status: 0xB0, data1: 32, data2: 0, reserved: 0)
                status = MusicTrackNewMIDIChannelEvent(track, 0, &chanmess)
                if status != noErr {
                    print("creating bank select event \(status)")
                }
                
                // program change. first data byte is the patch, the second data byte is unused for program change messages.
                chanmess = MIDIChannelMessage(status: 0xC0, data1: 0, data2: 0, reserved: 0)
                status = MusicTrackNewMIDIChannelEvent(track, 0, &chanmess)
                if status != noErr {
                    print("creating program change event \(status)")
                }
                
                // now make some notes and put them on the track
                var beat = MusicTimeStamp(0.0)
                for i: UInt8 in 60...72 {
                    var mess = MIDINoteMessage(channel: 0,
                                               note: i,
                                               velocity: 64,
                                               releaseVelocity: 0,
                                               duration: 1.0 )
                    status = MusicTrackNewMIDINoteEvent(track, beat, &mess)
                    if status != noErr {
                        print("creating new midi note event \(status)")
                    }
                    beat += 1
                }
            }
            // associate the AUGraph with the sequence.
            //        MusicSequenceSetAUGraph(musicSequence, self.processingGraph)
            
            // Let's see it
            CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence))
            
            return musicSequence
        }
        
        return nil
    }
    
}
