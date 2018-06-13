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

class SamplerSequenceOTF {

    let engine: AVAudioEngine

    let sampler: AVAudioUnitSampler

    var sequencer: AVAudioSequencer!

    init() {

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

    deinit {
        removeObservers()
    }


    func setupSequencer() {
        self.sequencer = AVAudioSequencer(audioEngine: self.engine)

        let musicSequence = createMusicSequence()
        if let data = sequenceData(musicSequence) {
            do {
                try sequencer.load(from: data, options: [])
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

        sequencer.currentPositionInBeats = 0

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
                audioSession.setCategory(AVAudioSessionCategoryPlayback,
                                         with: .mixWithOthers)
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
                                               selector: #selector(engineConfigurationChange),
                                               name: .AVAudioEngineConfigurationChange,
                                               object: engine)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterrupted),
                                               name: .AVAudioSessionInterruption,
                                               object: engine)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRouteChange),
                                               name: .AVAudioSessionRouteChange,
                                               object: engine)
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVAudioEngineConfigurationChange,
                                                  object: nil)

        NotificationCenter.default.removeObserver(self,
                                                  name: .AVAudioSessionInterruption,
                                                  object: nil)

        NotificationCenter.default.removeObserver(self,
                                                  name: .AVAudioSessionRouteChange,
                                                  object: nil)
    }


    // MARK: notification callbacks

    @objc
    func engineConfigurationChange(_ notification: Notification) {
        print("engineConfigurationChange")
    }

    @objc
    func sessionInterrupted(_ notification: Notification) {
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

    @objc
    func sessionRouteChange(_ notification: Notification) {
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



    func createMusicSequence() -> MusicSequence {

        var musicSequence: MusicSequence? = nil
        var status = NewMusicSequence(&musicSequence)
        if status != noErr {
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
        for i: UInt8 in 60...72 {
            var mess = MIDINoteMessage(channel: 0,
                                       note: i,
                                       velocity: 64,
                                       releaseVelocity: 0,
                                       duration: 1.0 )
            status = MusicTrackNewMIDINoteEvent(track!, beat, &mess)
            if status != noErr {
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
    func sequenceData(_ musicSequence: MusicSequence) -> Data? {
        var status = noErr

        var data: Unmanaged<CFData>?
        status = MusicSequenceFileCreateData(musicSequence,
                                             .midiType,
                                             .eraseFile,
                                             480, &data)
        if status != noErr {
            print("error turning MusicSequence into NSData")
            return nil
        }

        let ns: Data = data!.takeUnretainedValue() as Data
        data?.release()
        return ns
    }

}
