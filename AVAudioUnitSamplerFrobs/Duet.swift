//
//  Duet.swift
//  AVAudioUnitSamplerFrobs
//
//  Created by Gene De Lisa on 1/14/16.
//  Copyright © 2016 Gene De Lisa. All rights reserved.
//


import Foundation
import AVFoundation

class Duet {

    var engine: AVAudioEngine!

    var sampler: AVAudioUnitSampler!

    var sampler2: AVAudioUnitSampler!

    init() {

        engine = AVAudioEngine()

        sampler = AVAudioUnitSampler()
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        sampler2 = AVAudioUnitSampler()
        engine.attach(sampler2)
        engine.connect(sampler2, to: engine.mainMixerNode, format: nil)

        loadSF2PresetIntoSampler(0)
        loadSF2PresetIntoSampler2(12)

        addObservers()

        startEngine()

        print("Duet")
        print(self.engine)

        setSessionPlayback()
    }

    deinit {
        removeObservers()
    }


    func play() {
        sampler.startNote(60, withVelocity: 64, onChannel: 0)
        sampler2.startNote(64, withVelocity: 120, onChannel: 1)
    }

    func stop() {
        sampler.stopNote(60, onChannel: 0)
        sampler2.stopNote(64, onChannel: 1)
    }

    func loadSF2PresetIntoSampler(_ preset: UInt8) {

        guard let bankURL = Bundle.main.url(forResource: "FluidR3 GM2-2", withExtension: "SF2") else {
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

    func loadSF2PresetIntoSampler2(_ preset: UInt8) {

        guard let bankURL = Bundle.main.url(forResource: "FluidR3 GM2-2", withExtension: "SF2") else {
            print("could not load sound font")
            return
        }

        do {
            try self.sampler2.loadSoundBankInstrument(at: bankURL,
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
                audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
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

}
