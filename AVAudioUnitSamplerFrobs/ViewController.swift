//
//  ViewController.swift
//  AVAudioUnitSamplerFrobs
//
//  Created by Gene De Lisa on 1/13/16.
//  Copyright © 2016 Gene De Lisa. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var sampler1:Sampler1!
    
    var samplerSequence:SamplerSequence!
    
    var samplerSequenceOTF:SamplerSequenceOTF!
    
    var drumMachine:DrumMachine!
    
    var duet:Duet!

    override func viewDidLoad() {
        super.viewDidLoad()

        sampler1 = Sampler1()
        
        samplerSequence = SamplerSequence()
        
        samplerSequenceOTF = SamplerSequenceOTF()
        
        drumMachine = DrumMachine()
        
        duet = Duet()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func sampler1Down(sender: UIButton) {
        sampler1.play()
    }
    
    @IBAction func sampler1Up(sender: UIButton) {
        sampler1.stop()
    }
    
    @IBAction func samplerSequence(sender: UIButton) {
        samplerSequence.play()
    }
    
    @IBAction func samplerSequenceOTF(sender: UIButton) {
        samplerSequenceOTF.play()
    }

    
    @IBAction func drumMachinePlay(sender: UIButton) {
        drumMachine.play()
    }

    @IBAction func duetDown(sender: UIButton) {
        duet.play()
    }
    @IBAction func duetUp(sender: UIButton) {
        duet.stop()
    }

    
}

