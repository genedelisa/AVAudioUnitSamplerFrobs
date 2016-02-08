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
import CoreAudio


class SynthSequence : NSObject {
    
    var engine: AVAudioEngine!
    
    var sampler: AVAudioUnitMIDISynth!
    
    var sequencer:AVAudioSequencer!
    
    var midiSynth:AVAudioUnitMIDISynth!
    
    override init() {
        super.init()
        
        engine = AVAudioEngine()
        
        midiSynth = AVAudioUnitMIDISynth()
        midiSynth.loadMIDISynthSoundFont()
        var patches = [UInt32]()
        patches.append(UInt32(0))
        patches.append(46)
        midiSynth.loadPatches(patches)
        
        engine.attachNode(midiSynth)
        engine.connect(midiSynth, to: engine.mainMixerNode, format: nil)
        //        print("audio auaudiounit \(midiSynth.AUAudioUnit)")
        //        print("audio audiounit \(midiSynth.audioUnit)")
        print("audio descr \(midiSynth.audioComponentDescription)")
        
        
//        sampler = AVAudioUnitMIDISynth()
//        engine.attachNode(sampler)
//        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        setupSequencer()
        
//        loadSamples()
        
        addObservers()
        
        startEngine()
        
        print(self.engine)
        
        setSessionPlayback()
        
//        var synth = AUMIDISynth()
        

       


    }
    
    
    func setupSequencer() {
        
        self.sequencer = AVAudioSequencer(audioEngine: self.engine)
        
        let options = AVMusicSequenceLoadOptions.SMF_PreserveTracks
        if let fileURL = NSBundle.mainBundle().URLForResource("chromatic", withExtension: "mid") {
            do {
                try sequencer.loadFromURL(fileURL, options: options)
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
        if sequencer.playing {
            stop()
        }
        
        sequencer.currentPositionInBeats = NSTimeInterval(0)
        
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
        
//        if let urls = NSBundle.mainBundle().URLsForResourcesWithExtension("wav", subdirectory: "wavs") {
//            do {
//                try sampler.loadAudioFilesAtURLs(urls)
//                
//                for u in urls {
//                    print("loaded wav \(u)")
//                }
//                
//            } catch let error as NSError {
//                print("\(error.localizedDescription)")
//            }
//        }
    }
    
    
    func setSessionPlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try
                audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
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
        
        if engine.running {
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
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"engineConfigurationChange:",
            name:AVAudioEngineConfigurationChangeNotification,
            object:engine)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"sessionInterrupted:",
            name:AVAudioSessionInterruptionNotification,
            object:engine)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"sessionRouteChange:",
            name:AVAudioSessionRouteChangeNotification,
            object:engine)
    }
    
    func removeObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: AVAudioEngineConfigurationChangeNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: AVAudioSessionInterruptionNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: AVAudioSessionRouteChangeNotification,
            object: nil)
    }
    
    
    // MARK: notification callbacks
    func engineConfigurationChange(notification:NSNotification) {
        print("engineConfigurationChange")
    }
    
    func sessionInterrupted(notification:NSNotification) {
        print("audio session interrupted")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = notification.userInfo as? Dictionary<String,AnyObject!> {
            let reason = userInfo[AVAudioSessionInterruptionTypeKey] as! AVAudioSessionInterruptionType
            switch reason {
            case .Began:
                print("began")
            case .Ended:
                print("ended")
            }
        }
    }
    
    func sessionRouteChange(notification:NSNotification) {
        print("sessionRouteChange")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = notification.userInfo as? Dictionary<String,AnyObject!> {
            
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSessionRouteChangeReason {
                
                print("audio session route change reason \(reason)")
                
                switch reason {
                case .CategoryChange: print("CategoryChange")
                case .NewDeviceAvailable:print("NewDeviceAvailable")
                case .NoSuitableRouteForCategory:print("NoSuitableRouteForCategory")
                case .OldDeviceUnavailable:print("OldDeviceUnavailable")
                case .Override: print("Override")
                case .WakeFromSleep:print("WakeFromSleep")
                case .Unknown:print("Unknown")
                case .RouteConfigurationChange:print("RouteConfigurationChange")
                }
            }
            
            let previous = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
            print("audio session route change previous \(previous)")
        }
    }
    
}
