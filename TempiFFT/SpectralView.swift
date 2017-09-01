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
    var guessFreq: Int?
    var noteImage: UIImage?
    var midiNN: Int?
    
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
                self.subviews[0].frame = CGRect(x: 150, y: 225, width: 30, height: 30) // C3
                self.subviews[1].isHidden = true
            case 49:
                self.subviews[0].frame = CGRect(x: 150, y: 225, width: 30, height: 30) // C#3
                self.subviews[1].frame = CGRect(x: 120, y: 225, width: 30, height: 30)
                self.subviews[1].isHidden = false
            case 50:
                self.subviews[0].frame = CGRect(x: 150, y: 210, width: 30, height: 30) // D3
                self.subviews[1].isHidden = true
            case 51:
                self.subviews[0].frame = CGRect(x: 150, y: 210, width: 30, height: 30) // D#3
                self.subviews[1].frame = CGRect(x: 120, y: 210, width: 30, height: 30)
                self.subviews[1].isHidden = false
            case 52:
                self.subviews[0].frame = CGRect(x: 150, y: 195, width: 30, height: 30) // E3
                self.subviews[1].isHidden = true
            case 53:
                self.subviews[0].frame = CGRect(x: 150, y: 195, width: 30, height: 30) // E#3
            case 54:
                self.subviews[0].frame = CGRect(x: 150, y: 180, width: 30, height: 30) // F3
                self.subviews[1].isHidden = true
            case 55:
                self.subviews[0].frame = CGRect(x: 150, y: 165, width: 30, height: 30) // G3
                self.subviews[1].isHidden = true
            case 56:
                self.subviews[0].frame = CGRect(x: 150, y: 165, width: 30, height: 30) // G#3
            case 57:
                self.subviews[0].frame = CGRect(x: 150, y: 150, width: 30, height: 30) // A3
                self.subviews[1].isHidden = true
            case 58:
                self.subviews[0].frame = CGRect(x: 150, y: 150, width: 30, height: 30) // A#3
            case 60:
                self.subviews[0].frame = CGRect(x: 150, y: 135, width: 30, height: 30) // B3
                self.subviews[1].isHidden = true
            case 61:
                self.subviews[0].frame = CGRect(x: 150, y: 135, width: 30, height: 30) //B#3
            default: self.subviews[0].isHidden = true
            }
        }

        self.drawSpectrum(context: context!)
        
        // We're drawing static labels every time through our drawRect() which is a waste.
        // If this were more than a demo we'd take care to only draw them once.
        
        // If you need FFT Hz label
//        self.drawLabels(context: context!)
    }
    
    private func drawSpectrum(context: CGContext) {
//        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
//        
//        let plotYStart: CGFloat = 48.0
        
        // Pushes a copy of the current graphics state onto the graphics state stack for the context.
        context.saveGState()
        // Changes the scale of the user coordinate system in a context
        context.scaleBy(x: 1, y: -1)
        // Changes the origins of the user coordinate system in a context
        context.translateBy(x: 0, y: -viewHeight)
        
        
//        // UIColor array
//        let colors = [UIColor.green.cgColor, UIColor.yellow.cgColor, UIColor.red.cgColor]
//        let gradient = CGGradient(
//            colorsSpace: nil, // generic color space
//            colors: colors as CFArray,
//            locations: [0.0, 0.3, 0.6])
//        
//        var x: CGFloat = 0.0
//        
//        let count = fft.numberOfBands
//        
//        // Draw the spectrum.
//        let maxDB: Float = 64.0
//        let minDB: Float = -32.0
//        let headroom = maxDB - minDB
//        let colWidth = tempi_round_device_scale(d: viewWidth / CGFloat(count))
//        
//        for i in 0..<count {
//            let magnitude = fft.magnitudeAtBand(i)
//            
//            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
//            var magnitudeDB = TempiFFT.toDB(magnitude)
//            
//            // Normalize the incoming magnitude so that -Inf = 0
//            magnitudeDB = max(0, magnitudeDB + abs(minDB))
//            
//            let dbRatio = min(1.0, magnitudeDB / headroom)
//            let magnitudeNorm = CGFloat(dbRatio) * viewHeight
//            
//            let colRect: CGRect = CGRect(x: x, y: plotYStart, width: colWidth, height: magnitudeNorm)
//            
//            let startPoint = CGPoint(x: viewWidth / 2, y: 0)
//            let endPoint = CGPoint(x: viewWidth / 2, y: viewHeight)
//            
//            context.saveGState()
//            context.clip(to: colRect)
//            context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
//            context.restoreGState()
//            
//            x += colWidth
//        }
//        
        
        //Ryosuke add
        context.move(to: CGPoint(x: 5, y: 5))

//        let count:Int = fft.numberOfBands
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
    
    private func drawLabels(context: CGContext) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        
        context.saveGState()
        context.translateBy(x: 0, y: viewHeight);
        
        let pointSize: CGFloat = 15.0
        let font = UIFont.systemFont(ofSize: pointSize, weight: UIFontWeightRegular)
        
        let freqLabelStr = "Frequency (kHz)"
        var attrStr = NSMutableAttributedString(string: freqLabelStr)
        attrStr.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, freqLabelStr.characters.count))
        attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellow, range: NSMakeRange(0, freqLabelStr.characters.count))
        
        var x: CGFloat = viewWidth / 2.0 - attrStr.size().width / 2.0
        //attrStr.draw(at: CGPoint(x: x, y: -22))
        
        let labelStrings: [String] = ["5", "10", "15", "20"]
        let labelValues: [CGFloat] = [5000, 10000, 15000, 20000]
        let samplesPerPixel: CGFloat = CGFloat(fft.sampleRate) / 2.0 / viewWidth
        for i in 0..<labelStrings.count {
            let str = labelStrings[i]
            let freq = labelValues[i]
            
            attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, str.characters.count))
            attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellow, range: NSMakeRange(0, str.characters.count))
            
            x = freq / samplesPerPixel - pointSize / 2.0
            attrStr.draw(at: CGPoint(x: x, y: -40))
        }
        
        context.restoreGState()
    }
}
