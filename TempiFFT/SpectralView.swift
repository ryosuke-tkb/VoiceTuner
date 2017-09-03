//
//  SpectralView.swift
//  TempiHarness
//
//  Created by John Scalo on 1/20/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import UIKit

class SpectralView: UIView {
    var fft: TempiFFT!
    var cepstrum: [Double]!
    var guessedFreq: Int?
    var noteImage: UIImage?
    var midiNN: Int?
    let notePositionX: Int = 180
    private var pitchDict: [String : Int] = [
        "C":0,
        "C#":1,
        "D":2,
        "D#":3,
        "E":4,
        "F":5,
        "F#":6,
        "G":7,
        "G#":8,
        "A":9,
        "A#":10,
        "B":11
    ]
    private var pitchArray: [String] = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    var isDebugMode = false
    
    func prepareNoteImage(){
        let noteRect = CGRect(x: 0, y: 0, width: 30, height: 30)
        let noteImageView = UIImageView(frame: noteRect)
        noteImageView.contentMode = .scaleAspectFill
        noteImageView.image = self.noteImage!
        noteImageView.tag = 20
        noteImageView.isHidden = true
        self.addSubview(noteImageView)
        
        let sharpRect = CGRect(x: 0, y: 0, width:30, height: 30)
        let sharpImageView = UIImageView(frame: sharpRect)
        sharpImageView.contentMode = .scaleAspectFit
        sharpImageView.image = UIImage(named: "sharp.png")
        sharpImageView.isHidden = true
        self.addSubview(sharpImageView)
    }
    
    override func draw(_ rect: CGRect) {
        if fft == nil {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()
        
        if (midiNN! < 47) {
            self.subviews[0].isHidden = true
            self.subviews[1].isHidden = true
        }else if (midiNN! > 61) {
            self.subviews[0].isHidden = true
            self.subviews[1].isHidden = true
        }else {
            self.subviews[0].isHidden = false
            
            switch midiNN! {
            case 48:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 225, width: 30, height: 30) // C3
                self.subviews[1].isHidden = true
            case 49:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 225, width: 30, height: 30) // C#3
                self.subviews[1].frame = CGRect(x: self.notePositionX - 30, y: 225, width: 30, height: 30)
                self.subviews[1].isHidden = false
            case 50:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 210, width: 30, height: 30) // D3
                self.subviews[1].isHidden = true
            case 51:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 210, width: 30, height: 30) // D#3
                self.subviews[1].frame = CGRect(x: self.notePositionX - 30, y: 210, width: 30, height: 30)
                self.subviews[1].isHidden = false
            case 52:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 195, width: 30, height: 30) // E3
                self.subviews[1].isHidden = true
            case 53:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 195, width: 30, height: 30) // E#3
                self.subviews[1].frame = CGRect(x: self.notePositionX - 30, y: 195, width: 30, height: 30)
                self.subviews[1].isHidden = false
            case 54:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 180, width: 30, height: 30) // F3
                self.subviews[1].isHidden = true
            case 55:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 165, width: 30, height: 30) // G3
                self.subviews[1].isHidden = true
            case 56:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 165, width: 30, height: 30) // G#3
                self.subviews[1].frame = CGRect(x: self.notePositionX - 30, y: 165, width: 30, height: 30)
                self.subviews[1].isHidden = false
            case 57:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 150, width: 30, height: 30) // A3
                self.subviews[1].isHidden = true
            case 58:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 150, width: 30, height: 30) // A#3
                self.subviews[1].frame = CGRect(x: self.notePositionX - 30, y: 150, width: 30, height: 30)
                self.subviews[1].isHidden = false
            case 60:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 135, width: 30, height: 30) // B3
                self.subviews[1].isHidden = true
            case 61:
                self.subviews[0].frame = CGRect(x: self.notePositionX, y: 135, width: 30, height: 30) //B#3
                self.subviews[1].frame = CGRect(x: self.notePositionX - 30, y: 135, width: 30, height: 30)
                self.subviews[1].isHidden = false
            default:
                self.subviews[0].isHidden = true
                self.subviews[1].isHidden = true
            }
        }

        if isDebugMode {
            self.drawSpectrum(context: context!)
            
            if let labelView = self.viewWithTag(100) {
                labelView.removeFromSuperview()
                
                let pitchInfoLabel: UILabel = UILabel(frame: CGRect(x: 10, y: 10, width: 200, height: 20))
                pitchInfoLabel.backgroundColor = UIColor.orange
                pitchInfoLabel.text = String(guessedFreq!) + "Hz:  " + String(midiNN!) + "  " + pitchArray[midiNN! % 12] + String(midiNN! / 12)
                pitchInfoLabel.textColor = UIColor.white
                pitchInfoLabel.tag = 100
                self.addSubview(pitchInfoLabel)
            }else {
                print("no view")
                
                let pitchInfoLabel: UILabel = UILabel(frame: CGRect(x: 10, y: 10, width: 200, height: 20))
                pitchInfoLabel.backgroundColor = UIColor.orange
                pitchInfoLabel.text = String(guessedFreq!) + "Hz:  " + String(midiNN!) + "  " + pitchArray[midiNN! % 12] + String(midiNN! / 12)
                pitchInfoLabel.textColor = UIColor.white
                pitchInfoLabel.tag = 100
                self.addSubview(pitchInfoLabel)
            }
        }
    }
    
    private func drawSpectrum(context: CGContext) {
        let viewHeight = self.bounds.size.height
        
        // Pushes a copy of the current graphics state onto the graphics state stack for the context.
        context.saveGState()
        // Changes the scale of the user coordinate system in a context
        context.scaleBy(x: 1, y: -1)
        // Changes the origins of the user coordinate system in a context
        context.translateBy(x: 0, y: -viewHeight)
        
        context.move(to: CGPoint(x: 5, y: 5))

        let count = self.cepstrum!.count
        let offset :Float = 200
        
        for i in 0 ..< count {
            let xPos :Int = i + 5
            let cepCoef = self.cepstrum![i]
            var yPos :Float
            if (cepCoef.isNaN || cepCoef.isInfinite) {
                yPos =  offset
            }else {
                yPos = Float(cepCoef * 30) + offset
            }
            context.addLine(to: CGPoint(x: xPos, y: Int(yPos)))
        }
        
        context.setStrokeColor(UIColor.black.cgColor)
        context.strokePath()
        
//         Sets the current graphics state to the state most recently saved
        context.restoreGState()
    }
    
    func switchOnDebugMode() {
        self.isDebugMode = true
    }
    
    func switchOffDebugMode() {
        self.isDebugMode = false
    }
}
