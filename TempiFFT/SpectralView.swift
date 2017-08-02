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
    let start = Date()
    
    override func draw(_ rect: CGRect) {
        
        if fft == nil {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()
        
        // prepare for note image
        let noteRect = CGRect(x:100, y: 20, width: 100, height: 200)
        let noteImageView = UIImageView(frame: noteRect)
        
        // set Image display mode
        noteImageView.contentMode = .scaleAspectFit
        
        // set photo file
        noteImageView.image = UIImage(named: "hachibu.png")
        // set subview tag (It's important for change position)
        noteImageView.tag = 20
        
        // this process add Subview so, subview count is increase every call
        // self.addSubview(noteImageView)
        
        self.drawSpectrum(context: context!)
        
        // We're drawing static labels every time through our drawRect() which is a waste.
        // If this were more than a demo we'd take care to only draw them once.
        
        // If you need FFT Hz label
        self.drawLabels(context: context!)
        
//        let time = Date().timeIntervalSince(start)
//        print("\(time)")
    }
    
    private func drawSpectrum(context: CGContext) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        
        let plotYStart: CGFloat = 48.0
        
        // Pushes a copy of the current graphics state onto the graphics state stack for the context.
        context.saveGState()
        // Changes the scale of the user coordinate system in a context
        context.scaleBy(x: 1, y: -1)
        // Changes the origins of the user coordinate system in a context
        context.translateBy(x: 0, y: -viewHeight)
        
        
        // UIColor array
        let colors = [UIColor.green.cgColor, UIColor.yellow.cgColor, UIColor.red.cgColor]
        let gradient = CGGradient(
            colorsSpace: nil, // generic color space
            colors: colors as CFArray,
            locations: [0.0, 0.3, 0.6])
        
        var x: CGFloat = 0.0
        
        let count = fft.numberOfBands
        
        // Draw the spectrum.
        let maxDB: Float = 64.0
        let minDB: Float = -32.0
        let headroom = maxDB - minDB
        let colWidth = tempi_round_device_scale(d: viewWidth / CGFloat(count))
        
        for i in 0..<count {
            let magnitude = fft.magnitudeAtBand(i)
            
            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
            var magnitudeDB = TempiFFT.toDB(magnitude)
            
            // Normalize the incoming magnitude so that -Inf = 0
            magnitudeDB = max(0, magnitudeDB + abs(minDB))
            
            let dbRatio = min(1.0, magnitudeDB / headroom)
            let magnitudeNorm = CGFloat(dbRatio) * viewHeight
            
            let colRect: CGRect = CGRect(x: x, y: plotYStart, width: colWidth, height: magnitudeNorm)
            
            let startPoint = CGPoint(x: viewWidth / 2, y: 0)
            let endPoint = CGPoint(x: viewWidth / 2, y: viewHeight)
            
            context.saveGState()
            context.clip(to: colRect)
            context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
            context.restoreGState()
            
            x += colWidth
        }
        
        
        //Ryosuke add
        context.move(to: CGPoint(x: 5, y: 5))

//        let count:Int = fft.numberOfBands
//        let count = 256
        let offset :Float = 50
        
        for i in 0 ..< count {
            let xPos :Int = i * 1 + 5
            let cepCoef = fft.getMagnitudes(i)
            var yPos :Float
            if (cepCoef.isNaN || cepCoef.isInfinite || cepCoef > 100) {
                yPos =  offset
            }else {
                yPos = TempiFFT.toDB(cepCoef) + 32 + offset
            }
            context.addLine(to: CGPoint(x: xPos, y: Int(yPos)))
        }
        
        context.setStrokeColor(UIColor.black.cgColor)
        context.strokePath()
        
        let drawOffsetY  :Float = 150
        context.move(to: CGPoint(x:5, y:0))
        let fftcount = 512
        
        for i in 0 ..< fftcount {
            let xPos :Int = i * 1 + 5
            let cepCoef = Float(0.0)
            var yPos :Float
            if (cepCoef.isNaN || cepCoef.isInfinite || cepCoef > 100) {
                yPos = drawOffsetY
            }else {
                yPos = TempiFFT.toDB(cepCoef) + 32 + drawOffsetY
            }
            context.addLine(to: CGPoint(x: xPos, y: Int(yPos)))
        }
        context.setStrokeColor(UIColor.red.cgColor)
        context.strokePath()
     
//        let drawCepOffsetY  :Float = 200
//        
//        context.move(to: CGPoint(x:5, y:Int(drawCepOffsetY)))
//        let cepcount = 256
//        let cepstrum = fft.getCepstrum()
//        
//        for i in 0 ..< cepcount {
//            let xPos :Int = i * 1 + 5
//            let cepCoef = cepstrum[i]
//            print("cepstrum(\(i)): \(cepCoef)")
//            var yPos :Float
//            if (cepCoef.isNaN || cepCoef.isInfinite || cepCoef > 100 || cepCoef < -100) {
//                yPos = drawCepOffsetY
//            }else {
//                yPos = cepCoef * 10
//            }
//            context.addLine(to: CGPoint(x: xPos, y: Int(yPos)))
//        }
//        context.setStrokeColor(UIColor.green.cgColor)
//        context.strokePath()
        
    
        context.setLineWidth(5.0)
        let r2: CGRect = CGRect(x:0, y:CGFloat(fft.averageMagnitude(lowFreq: 60.0, highFreq: 1200.0)), width:viewWidth-50, height:5)
        context.setFillColor(CGColor(colorSpace:CGColorSpaceCreateDeviceRGB(), components: [1.0, 0.0, 0.0, 1.0])!)
        context.addRect(r2)
        context.fill(r2)
        context.fillPath()
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
