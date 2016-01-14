//
//  AudioMeta.swift
//  AVAudioUnitSamplerFrobs
//
//  Created by Gene De Lisa on 1/14/16.
//  Copyright © 2016 Gene De Lisa. All rights reserved.
//

import Foundation
import AudioToolbox

class AudioMeta {
    
    func show() {
        var status = OSStatus(noErr)
        
        if let urls = NSBundle.mainBundle().URLsForResourcesWithExtension("wav", subdirectory: "wavs") {
            
            for url in urls {
                print("reading meta for \(url)")
                
                var audioFile:AudioFileID = nil
                status = AudioFileOpenURL(url, AudioFilePermissions.ReadPermission, 0, &audioFile)
                if status != noErr {
                    print("opening audio url error \(status)")
                    continue
                }
                
                var size = UInt32(0)
                let inUserDataID = UInt32(0)
                let inIndex = UInt32(0)
                status = AudioFileGetUserDataSize(audioFile, inUserDataID, inIndex, &size)
                if status != noErr {
                    print("user data size error \(status)")
                    return
                }
                if size == 0 {
                    print("data size is 0")
                    continue
                }
                
                var data = ""
                status = AudioFileGetUserData(audioFile,
                    inUserDataID,
                    inIndex,
                    &size,
                    &data)
                if status != noErr {
                    print("user data error \(status)")
                    return
                }
                
                print("data \(data)")
            }
            
            
        }
        
    }
    
    func addInstrumentChunk () {
        if let sampleURL = NSBundle.mainBundle().URLForResource("sample01", withExtension: "caf", subdirectory: "Sounds") {
            var sampleFileID : AudioFileID = nil
            _ = AudioFileOpenURL(sampleURL, AudioFilePermissions.ReadPermission, 0, &sampleFileID)
            
            
            // define the chunk settings
            var chunkSettings = CAFInstrumentChunk(
                mBaseNote: Float32(41),
                mMIDILowNote: UInt8 (35),
                mMIDIHighNote: UInt8(47),
                mMIDILowVelocity: UInt8(0),
                mMIDIHighVelocity: UInt8(127),
                mdBGain: Float32(0.0),
                mStartRegionID: UInt32(0),
                mSustainRegionID: UInt32(0),
                mReleaseRegionID: UInt32(0),
                mInstrumentID: UInt32(0)
            )
            
            
            //make big endian
            chunkSettings.mBaseNote = Float32(Int(chunkSettings.mBaseNote).bigEndian)
            chunkSettings.mdBGain = Float32(Int(chunkSettings.mdBGain).bigEndian)
            chunkSettings.mStartRegionID = UInt32(chunkSettings.mStartRegionID.bigEndian)
            chunkSettings.mSustainRegionID = UInt32(chunkSettings.mSustainRegionID.bigEndian)
            chunkSettings.mReleaseRegionID = UInt32(chunkSettings.mReleaseRegionID.bigEndian)
            chunkSettings.mInstrumentID = UInt32(chunkSettings.mInstrumentID.bigEndian)
            
            
            //write the settings to the file
            AudioFileSetProperty(sampleFileID, UInt32(kCAF_InstrumentChunkID), UInt32 (sizeof(CAFInstrumentChunk)), &chunkSettings)
        }
    }
    
    
    
}
