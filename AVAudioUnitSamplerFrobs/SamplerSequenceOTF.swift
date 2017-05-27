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

class SamplerSequenceOTF : NSObject {
    
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
        
        addObservers()
        
        startEngine()
        
        print(self.engine)
        
        setSessionPlayback()
    }
    
    
    func setupSequencer() {
        
        self.sequencer = AVAudioSequencer(audioEngine: self.engine)
        
        let options = AVMusicSequenceLoadOptions()
        let musicSequence = createMusicSequence()
        if let data = sequenceData(musicSequence) {
            do {
                try sequencer.load(from: data, options: options)
                print("loaded \(data)")
            } catch {
                print("something screwed up \(error)")
                return
            }
        } else {
            print("nil data")
            return
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
            selector:#selector(SamplerSequenceOTF.engineConfigurationChange(_:)),
            name:NSNotification.Name.AVAudioEngineConfigurationChange,
            object:engine)
        
        NotificationCenter.default.addObserver(self,
            selector:#selector(SamplerSequenceOTF.sessionInterrupted(_:)),
            name:NSNotification.Name.AVAudioSessionInterruption,
            object:engine)
        
        NotificationCenter.default.addObserver(self,
            selector:#selector(SamplerSequenceOTF.sessionRouteChange(_:)),
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
    
   
    
    func createMusicSequence() -> MusicSequence {
        
        var musicSequence: MusicSequence? = nil
        var status = NewMusicSequence(&musicSequence)
        if status != OSStatus(noErr) {
            print("\(#line) bad status \(status) creating sequence")
        }
        
        // add a track
        var track: MusicTrack? = nil
        status = MusicSequenceNewTrack(musicSequence!, &track)
        if status != OSStatus(noErr) {
            print("error creating track \(status)")
        }
        
        
        // now make some notes and put them on the track
        var beat = MusicTimeStamp(0.0)
        for i:UInt8 in 60...72 {
            var mess = MIDINoteMessage(channel: 0,
                note: i,
                velocity: 64,
                releaseVelocity: 0,
                duration: 1.0 )
            status = MusicTrackNewMIDINoteEvent(track!, beat, &mess)
            if status != OSStatus(noErr) {
                print("creating new midi note event \(status)")
            }
            beat += 1
        }
        
        // hi hat in eighth notes
        beat = MusicTimeStamp(0.0)
        for _ in 0...16 {
            var mess = MIDINoteMessage(channel: 0,
                note: 63, //D#4 - see the wav names
                velocity: 127,
                releaseVelocity: 0,
                duration: 0.5 )
            status = MusicTrackNewMIDINoteEvent(track!, beat, &mess)
            if status != OSStatus(noErr) {
                print("creating new midi note event \(status)")
            }
            beat += MusicTimeStamp(0.5)
        }
        
        // associate the AUGraph with the sequence.
        //        MusicSequenceSetAUGraph(musicSequence, self.processingGraph)
        
        // Let's see it
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence!))
        
        return musicSequence!
    }
    
    /**
     AVAudioSequencer will not load a MusicSequence, but it will load NSData.
     */
    func sequenceData(_ musicSequence:MusicSequence) -> Data? {
        var status = OSStatus(noErr)
        
        var data:Unmanaged<CFData>?
        status = MusicSequenceFileCreateData(musicSequence,
            MusicSequenceFileTypeID.midiType,
            MusicSequenceFileFlags.eraseFile,
            480, &data)
        if status != noErr {
            print("error turning MusicSequence into NSData")
            return nil
        }
        
        let ns:Data = data!.takeUnretainedValue() as Data
        data?.release()
        return ns
    }

}
