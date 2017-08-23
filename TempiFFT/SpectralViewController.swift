//
//  SpectralViewController.swift
//  TempiHarness
//
//  Created by John Scalo on 1/7/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

class SpectralViewController: UIViewController {
    
    var audioInput: TempiAudioInput!
    var spectralView: SpectralView!
    
    // called immediately after a screen has been displayed
    override func viewDidLoad() {
        super.viewDidLoad()

        spectralView = SpectralView(frame: self.view.bounds)
        spectralView.backgroundColor = UIColor.white
        
        self.view.addSubview(spectralView)
        
        // prepare Image View
        let rect = CGRect(x:0, y:100, width: 100, height: 200)
        let imageView = UIImageView(frame: rect)
        
        // set Image display mode
        imageView.contentMode = .scaleAspectFit
        
        // set photo file
        imageView.image = UIImage(named: "G_clef.png")
        self.view.addSubview(imageView)
        
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
            self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: Int(numberOfFrames), samples: samples)
        }
        
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: 44100, numberOfChannels: 1)
        audioInput.startRecording()
        
//         draw 5 line (more simply!!)
//        let lineImage = self.makeScoreImage(pos_y: 50)
//        let lineView = UIImageView(image: lineImage)
//        self.view.addSubview(lineView)
        
//        self.makeScoreImage(pos_y: 100)
//        self.makeScoreImage(pos_y: 150)
//        self.makeScoreImage(pos_y: 200)
//        self.makeScoreImage(pos_y: 250)
        
        let audioClass = AudioDataClass(address: "/Users/Ryosuke/Downloads/a.wav")
        audioClass.loadAudioData()
        
        let samplingRate = audioClass.samplingRate!
        let sampleSize = audioClass.nframe!
        
        print("samplingRate: \(samplingRate)")
        print("sampleSize: \(sampleSize)")
        
        var inputBuffer = [Float](repeating: 0.0, count: sampleSize)
        for i in 0 ..< sampleSize {
            inputBuffer[i] = audioClass.buffer[0][i]
        }
        
        let stationaryPart = Array(inputBuffer[5000...5511])
        let cepstrum :[Double] = calculateCepstrum(stationaryPart)
        
        let testDraw = drawLine(cepstrum.map{Float($0)})
        let drawView = UIImageView(image: testDraw)

        self.view.addSubview(drawView)
    
        // make stop button
        let stopButton = UIButton()
        stopButton.setTitle("Stop", for: .normal)
        stopButton.setTitleColor(UIColor.yellow, for: .normal)
        stopButton.backgroundColor = UIColor.black
        stopButton.addTarget(self, action: #selector(stopButtonEvent(sender:)), for: .touchUpInside)
        stopButton.sizeToFit()
        stopButton.frame = CGRect(x: self.view.bounds.midX + 80, y: self.view.bounds.midY, width: 80, height: 40)
        self.view.addSubview(stopButton)
        
        // make start button
        let startButton = UIButton()
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(UIColor.yellow, for: .normal)
        startButton.backgroundColor = UIColor.black
        startButton.addTarget(self, action: #selector(startButtonEvent(sender:)), for: .touchUpInside)
        startButton.sizeToFit()
        startButton.frame = CGRect(x: self.view.bounds.midX - 80, y: self.view.bounds.midY, width: 80, height: 40)
        self.view.addSubview(startButton)
    }

    func gotSomeAudio(timeStamp: Double, numberOfFrames: Int, samples: [Float]) {
        let fft = TempiFFT(withSize: numberOfFrames, sampleRate: 44100.0)
        fft.windowType = TempiFFTWindowType.hanning
        fft.fftForward(samples)
        
        // Interpoloate the FFT data so there's one band per pixel.
        let screenWidth = UIScreen.main.bounds.size.width * UIScreen.main.scale
        fft.calculateLinearBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, numberOfBands: Int(screenWidth))

        tempi_dispatch_main { () -> () in
            self.spectralView.fft = fft
            self.spectralView.setNeedsDisplay()
        }
    }
    
    
    // called when stopButton is tapped
    func stopButtonEvent(sender: UIButton) {
        print("stop button pushed")
        audioInput.stopRecording()
    }
    
    // called when startButton is tapped
    func startButtonEvent(sender: UIButton) {
        print("start button pushed")
        audioInput.startRecording()
    }
    
    // function name isn't match. drawLine is more proper
   func makeScoreImage(pos_y: CGFloat) -> UIImage {
//        let viewWidth = self.view.bounds.size.width
//        let viewHeight = self.view.bounds.size.height
        
        let size = view.bounds.size
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        
        let line = UIBezierPath()
        line.move(to: CGPoint(x: 0, y: pos_y))
        line.addLine(to: CGPoint(x: 100, y: pos_y))
        line.close()
        
        UIColor.black.setStroke()
        UIColor.black.setFill()
        line.lineWidth = 5.0
        line.stroke()
    
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        return image!
    }
    
    func calculateCepstrum(_ inBuffer:[Float]) -> [Double] {
        let samples = inBuffer.map{Double($0)}
        let inputSize :Int = samples.count
        
        let label = UILabel(frame: CGRect(x: 30, y: 30, width: 200, height: 20))
        label.text = "inputSize:" + String(inputSize)
        self.view.addSubview(label)
        
        var reals = [Double](repeating: 0.0, count: inputSize/2)
        var imgs = [Double](repeating: 0.0, count: inputSize/2)
        var splitComplex = DSPDoubleSplitComplex(realp: &reals, imagp: &imgs)
        let complexBuffer :UnsafePointer<DSPDoubleComplex> = UnsafeRawPointer(samples).bindMemory(to: DSPDoubleComplex.self, capacity: inputSize)
        
        vDSP_ctozD(complexBuffer, 2, &splitComplex, 1, vDSP_Length(inputSize/2))
        
        let fftSize = inputSize
        let log2fftSize = vDSP_Length(log2(Double(fftSize)))
        let setup = vDSP_create_fftsetupD(log2fftSize, FFTRadix(FFT_RADIX2))
        
        vDSP_fft_zripD(setup!, &splitComplex, 1, log2fftSize, FFTDirection(FFT_FORWARD))

        var scale :Double = 1/2
        vDSP_vsmulD(splitComplex.realp, 1, &scale, splitComplex.realp, 1, vDSP_Length(inputSize/2))
        vDSP_vsmulD(splitComplex.imagp, 1, &scale, splitComplex.imagp, 1, vDSP_Length(inputSize/2))
        
        let fftRealValue = splitComplex.realp
        let fftImagValue = splitComplex.imagp
        
//        let fftOutputReal = UnsafeBufferPointer(start: splitComplex.realp, count: inputSize/2)
//        let fftOutputImag = UnsafeBufferPointer(start: splitComplex.imagp, count: inputSize/2)
        
        var magnitudes = [Double]()
        
        for index in 0 ..< inputSize {
            if (index < inputSize/2) {
                let ri = fftRealValue.advanced(by: index).pointee
                let ii = fftImagValue.advanced(by: index).pointee
                magnitudes.append(20 * log10(sqrt(ri * ri + ii * ii)))
            }else{
                let ri = fftRealValue.advanced(by: inputSize - index - 1).pointee
                let ii = fftImagValue.advanced(by: inputSize - index - 1).pointee
                magnitudes.append(20 * log10(sqrt(ri * ri + ii * ii)))
            }
        }
        
        var ifftInputReal = [Double](repeating: 0.0, count: inputSize/2)
        var ifftInputImag = [Double](repeating: 0.0, count: inputSize/2)
        var ifftSplitComplex = DSPDoubleSplitComplex(realp: &ifftInputReal, imagp: &ifftInputImag)
//        let ifftSplitComplexSrc :UnsafePointer<DSPComplex> = UnsafeRawPointer(magnitudes).bindMemory(to: DSPComplex.self, capacity: fftSize)
        let ifftSplitComplexSrc :UnsafePointer<DSPDoubleComplex> = UnsafeRawPointer(magnitudes).bindMemory(to: DSPDoubleComplex.self, capacity: inputSize)
        
  
//        vDSP_ctoz(ifftSplitComplexSrc, 2, &ifftSplitComplex, 1, vDSP_Length(fftSize/2))
        vDSP_ctozD(ifftSplitComplexSrc, 2, &ifftSplitComplex, 1, vDSP_Length(inputSize/2))
        
        let ifftSetup = vDSP_create_fftsetupD(log2fftSize, FFTRadix(FFT_RADIX2))
        
        vDSP_fft_zripD(ifftSetup!, &ifftSplitComplex, 1, UInt(log2fftSize), Int32(FFTDirection(FFT_INVERSE)))
        
        vDSP_vsmulD(ifftSplitComplex.realp, 1, &scale, ifftSplitComplex.realp, 1, vDSP_Length(inputSize/2))
        vDSP_vsmulD(ifftSplitComplex.imagp, 1, &scale, ifftSplitComplex.imagp, 1, vDSP_Length(inputSize/2))
        
        var ifftScale :Double = 1/256
        vDSP_vsmulD(ifftSplitComplex.realp, 1, &ifftScale, ifftSplitComplex.realp, 1, vDSP_Length(inputSize/2))
        vDSP_vsmulD(ifftSplitComplex.imagp, 1, &ifftScale, ifftSplitComplex.imagp, 1, vDSP_Length(inputSize/2))
        
        let ifftOutputReal = Array(UnsafeBufferPointer(start: ifftSplitComplex.realp, count: fftSize/2))
        let ifftOutputImag = Array(UnsafeBufferPointer(start: ifftSplitComplex.imagp, count: fftSize/2))
        
        var cepstrum = [Double]()
        for index in 0 ..< fftSize/2 {
            let ri = ifftOutputReal[index]
            let ii = ifftOutputImag[index]
//            cepstrum.append(sqrt(ri * ri + ii * ii))
            cepstrum.append(ri)
            print(ri)
        }
        
        vDSP_destroy_fftsetupD(setup)
        vDSP_destroy_fftsetupD(ifftSetup)
        
        return cepstrum
    }
    
    func drawLine(_ points:[Float]) -> UIImage {
        let line = UIBezierPath()
        let stationaryPart = points
        let size = view.bounds.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        line.move(to: CGPoint(x: 5, y: 30))
        for i in 0 ..< stationaryPart.count {
            var yPos = stationaryPart[i]
            if (yPos > 200 || yPos.isNaN || yPos.isInfinite) {
                yPos = 100
            }else {
//                yPos = yPos
            }
//            print("\(i): \(yPos)")
            line.addLine(to : CGPoint(x: 2 * i + 5, y: Int(yPos*10)+100))
        }
        
        line.lineWidth = 1.0
        UIColor.brown.setStroke()
        line.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    override func didReceiveMemoryWarning() {
        NSLog("*** Memory!")
        super.didReceiveMemoryWarning()
    }
}

