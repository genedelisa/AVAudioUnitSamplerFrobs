//
//  SamplerSequence.swift
//  AVAudioUnitSamplerFrobs
//
//  Created by Gene De Lisa on 1/13/16.
//  Copyright © 2016 Gene De Lisa. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox

class SamplerSequence : NSObject {
    
    var engine: AVAudioEngine!
    
    var sampler: AVAudioUnitSampler!
    
    var sequencer:AVAudioSequencer!
    
    override init() {
        super.init()
        
        engine = AVAudioEngine()
        
        sampler = AVAudioUnitSampler()
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        setupSequencer()
        
        loadSamples()
//        loadSF2PresetIntoSampler(0)
        
        addObservers()
        
        startEngine()
        
        print(self.engine)
        
        setSessionPlayback()
    }
    
    
    func setupSequencer() {
        
        self.sequencer = AVAudioSequencer(audioEngine: self.engine)
        
        let options = AVMusicSequenceLoadOptions()
        if let fileURL = Bundle.main.url(forResource: "chromatic2", withExtension: "mid") {
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
    
    
    //AUSampler - Controlling the Settings of the AUSampler in Real Time
    //https://developer.apple.com/library/ios/technotes/tn2331/_index.html
    
    //https://developer.apple.com/videos/play/wwdc2011-411/ video on creating aupreset
    
    //if you name your sample violinC4.wav, your sample will be assigned to note number 60.
    func loadSamples() {
        
        if let urls = Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: "wavs") {
            do {
                try sampler.loadAudioFiles(at: urls)
                
                for u in urls {
                    print("loaded wav \(u)")
                }
                
            } catch let error as NSError {
                print("\(error.localizedDescription)")
            }
        }
    }
    
    func loadSF2PresetIntoSampler(_ preset:UInt8)  {
        
        guard let bankURL = Bundle.main.url(forResource: "GeneralUser GS MuseScore v1.442", withExtension: "sf2") else {
            print("could not load sound font")
            return
        }
        
        do {
            try self.sampler.loadSoundBankInstrument(at: bankURL,
                program: preset,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB))
        } catch {
            print("error loading sound bank instrument")
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
    
    //MARK: - Notifications
    
    func addObservers() {
        NotificationCenter.default.addObserver(self,
            selector:#selector(SamplerSequence.engineConfigurationChange(_:)),
            name:NSNotification.Name.AVAudioEngineConfigurationChange,
            object:engine)
        
        NotificationCenter.default.addObserver(self,
            selector:#selector(SamplerSequence.sessionInterrupted(_:)),
            name:NSNotification.Name.AVAudioSessionInterruption,
            object:engine)
        
        NotificationCenter.default.addObserver(self,
            selector:#selector(SamplerSequence.sessionRouteChange(_:)),
            name:NSNotification.Name.AVAudioSessionRouteChange,
            object:engine)
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
    func engineConfigurationChange(_ notification:Notification) {
        print("engineConfigurationChange")
    }
    
    func sessionInterrupted(_ notification:Notification) {
        print("audio session interrupted")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = notification.userInfo as? Dictionary<String,AnyObject?> {
            let reason = userInfo[AVAudioSessionInterruptionTypeKey] as! AVAudioSessionInterruptionType
            switch reason {
            case .began:
                print("began")
            case .ended:
                print("ended")
            }
        }
    }
    
    func sessionRouteChange(_ notification:Notification) {
        print("sessionRouteChange")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = notification.userInfo as? Dictionary<String,AnyObject?> {
            
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
            
            let previous = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
            print("audio session route change previous \(previous)")
        }
    }
    
}
