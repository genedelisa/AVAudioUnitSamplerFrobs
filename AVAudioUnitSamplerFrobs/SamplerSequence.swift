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
        engine.attachNode(sampler)
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
        
        if let urls = NSBundle.mainBundle().URLsForResourcesWithExtension("wav", subdirectory: "wavs") {
            do {
                try sampler.loadAudioFilesAtURLs(urls)
                
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
                audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
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
    
    
    func createMusicSequence() -> MusicSequence {
        
        var musicSequence = MusicSequence()
        var status = NewMusicSequence(&musicSequence)
        if status != OSStatus(noErr) {
            print("\(__LINE__) bad status \(status) creating sequence")
        }
        
        // add a track
        var track = MusicTrack()
        status = MusicSequenceNewTrack(musicSequence, &track)
        if status != OSStatus(noErr) {
            print("error creating track \(status)")
        }
        
        // bank select msb
        var chanmess = MIDIChannelMessage(status: 0xB0, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track, 0, &chanmess)
        if status != OSStatus(noErr) {
            print("creating bank select event \(status)")
        }
        // bank select lsb
        chanmess = MIDIChannelMessage(status: 0xB0, data1: 32, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track, 0, &chanmess)
        if status != OSStatus(noErr) {
            print("creating bank select event \(status)")
        }
        
        // program change. first data byte is the patch, the second data byte is unused for program change messages.
        chanmess = MIDIChannelMessage(status: 0xC0, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track, 0, &chanmess)
        if status != OSStatus(noErr) {
            print("creating program change event \(status)")
        }
        
        // now make some notes and put them on the track
        var beat = MusicTimeStamp(0.0)
        for i:UInt8 in 60...72 {
            var mess = MIDINoteMessage(channel: 0,
                note: i,
                velocity: 64,
                releaseVelocity: 0,
                duration: 1.0 )
            status = MusicTrackNewMIDINoteEvent(track, beat, &mess)
            if status != OSStatus(noErr) {
                print("creating new midi note event \(status)")
            }
            beat++
        }
        
        // associate the AUGraph with the sequence.
        //        MusicSequenceSetAUGraph(musicSequence, self.processingGraph)
        
        // Let's see it
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence))
        
        return musicSequence
    }
    
    func sequenceData(musicSequence:MusicSequence) -> NSData? {
        var status = OSStatus(noErr)
        
        var data:Unmanaged<CFData>?
        // var data:UnsafeMutablePointer<Unmanaged<CFData>?>
        
        status = MusicSequenceFileCreateData(musicSequence,
            MusicSequenceFileTypeID.MIDIType,
            MusicSequenceFileFlags.EraseFile,
            480, &data)
        if status != noErr {
            return nil
        }
        
//        let ns:NSData = data!.takeUnretainedValue()
        let ns:NSData = data!.takeRetainedValue()
        data?.release()
        return ns
    }

}
