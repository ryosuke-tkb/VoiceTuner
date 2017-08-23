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
        let cepstrum :[Float] = calculateCepstrum(stationaryPart)
        
        let testDraw = drawLine(cepstrum)
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
    
    func calculateCepstrum(_ inBuffer:[Float]) -> [Float] {
        let samples = inBuffer
        let inputSize :Int = samples.count
        
        let label = UILabel(frame: CGRect(x: 30, y: 30, width: 200, height: 20))
        label.text = "inputSize:" + String(inputSize)
        self.view.addSubview(label)
        
        var reals = [Float](repeating: 0.0, count: inputSize/2)
        var imgs = [Float](repeating: 0.0, count: inputSize/2)
        var splitComplex = DSPSplitComplex(realp: &reals, imagp: &imgs)
        let complexBuffer :UnsafePointer<DSPComplex> = UnsafeRawPointer(samples).bindMemory(to: DSPComplex.self, capacity: inputSize)
        
        vDSP_ctoz(complexBuffer, 2, &splitComplex, 1, vDSP_Length(inputSize/2))
        
        let fftSize = inputSize
        let log2fftSize = vDSP_Length(log2(Double(fftSize)))
        print("log2fftSize = \(log2fftSize)")
        let setup = vDSP_create_fftsetup(log2fftSize, FFTRadix(FFT_RADIX2))
        
        vDSP_fft_zrip(setup!, &splitComplex, 1, log2fftSize, FFTDirection(FFT_FORWARD))

        var scale :Float = 1/2
        vDSP_vsmul(splitComplex.realp, 1, &scale, splitComplex.realp, 1, vDSP_Length(inputSize/2))
        vDSP_vsmul(splitComplex.imagp, 1, &scale, splitComplex.imagp, 1, vDSP_Length(inputSize/2))
        
        var fftRealValue = splitComplex.realp
        print(fftRealValue.pointee)
        
        var fftImagValue = splitComplex.imagp
        print(fftImagValue.pointee)
        
        let fftOutputReal = Array(UnsafeBufferPointer(start: splitComplex.realp, count: inputSize/2))
        let fftOutputImag = Array(UnsafeBufferPointer(start: splitComplex.imagp, count: inputSize/2))
        
        var magnitudes = [Float]()
        
        for index in 0 ..< inputSize {
            if (index < inputSize/2) {
                let ri = fftRealValue.pointee
                let ii = fftImagValue.pointee
                magnitudes.append(log10f(sqrt(ri * ri + ii * ii)))
                fftRealValue += 1
                fftImagValue += 1
            }else{
                let ri = fftRealValue.pointee
                let ii = fftImagValue.pointee
                magnitudes.append(log10f(sqrt(ri * ri + ii * ii)))
                fftRealValue -= 1
                fftImagValue -= 1
            }
        }
        
        print("magnitudes[0] = \(magnitudes[1])")
        var ifftInputReal = [Float](repeating: 0.0, count: inputSize/2)
        var ifftInputImag = [Float](repeating: 0.0, count: inputSize/2)
        var ifftSplitComplex = DSPSplitComplex(realp: &ifftInputReal, imagp: &ifftInputImag)
//        let ifftSplitComplexSrc :UnsafePointer<DSPComplex> = UnsafeRawPointer(magnitudes).bindMemory(to: DSPComplex.self, capacity: fftSize)
        var ifftSplitComplexSrc :UnsafePointer<DSPComplex> = UnsafeRawPointer(magnitudes).bindMemory(to: DSPComplex.self, capacity: inputSize)
        
  
//        vDSP_ctoz(ifftSplitComplexSrc, 2, &ifftSplitComplex, 1, vDSP_Length(fftSize/2))
        vDSP_ctoz(ifftSplitComplexSrc, 2, &ifftSplitComplex, 1, vDSP_Length(inputSize/2))
        
//        var pOfIfftSplitComplex = ifftSplitComplex.realp
//        pOfIfftSplitComplex += 1
//        print("ifft_input_real[0] = \(pOfIfftSplitComplex.pointee)")
//        
        let ifftSetup = vDSP_create_fftsetup(log2fftSize, FFTRadix(FFT_RADIX2))
//        
//        var pointer = ifftSplitComplex.realp
//        for i in 0 ..< inputSize/2 {
//            print("\(i):\(pointer.pointee)")
//            pointer += 1
//        }
//        print("cep_real_BeforeFft = \(ifftSplitComplex.realp.pointee)")
        
        vDSP_fft_zrip(ifftSetup!, &ifftSplitComplex, 1, log2fftSize, FFTDirection(FFT_INVERSE))
        
        print("cep_real_AfterFft = \(ifftSplitComplex.realp.pointee)")
        
        var pointer2 = ifftSplitComplex.realp
        for i in 0 ..< inputSize/2 {
            print("\(i):\(pointer2.pointee)")
            pointer2 += 1
        }
        
        vDSP_vsmul(ifftSplitComplex.realp, 1, &scale, ifftSplitComplex.realp, 1, vDSP_Length(inputSize/2))
        vDSP_vsmul(ifftSplitComplex.imagp, 1, &scale, ifftSplitComplex.imagp, 1, vDSP_Length(inputSize/2))
        
        var pointerOfIfftSplitComplex = ifftSplitComplex.realp
        pointerOfIfftSplitComplex += 3
        print("cep_real[0] = \(pointerOfIfftSplitComplex.pointee)")
        
        let ifftOutputReal = Array(UnsafeBufferPointer(start: ifftSplitComplex.realp, count: fftSize/2))
        let ifftOutputImag = Array(UnsafeBufferPointer(start: ifftSplitComplex.imagp, count: fftSize/2))
        
        var cepstrum = [Float]()
        for index in 0 ..< fftSize/2 {
            let ri = ifftOutputReal[index]
            let ii = ifftOutputImag[index]
//            cepstrum.append(sqrt(ri * ri + ii * ii))
            cepstrum.append(ri)
        }
        
        vDSP_destroy_fftsetup(setup)
        vDSP_destroy_fftsetup(ifftSetup)
        
        return cepstrum
    }
    
    func drawLine(_ points:[Float]) -> UIImage {
        let line = UIBezierPath()
        let stationaryPart = points
        let size = view.bounds.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        line.move(to: CGPoint(x: 5, y: 5))
        for i in 0 ..< stationaryPart.count {
            var yPos = stationaryPart[i]
            if (yPos > 200 || yPos.isNaN || yPos.isInfinite) {
                yPos = 5
            }else {
//                yPos = yPos
            }
//            print("\(i): \(yPos)")
            line.addLine(to : CGPoint(x: 2 * i + 5, y: Int(yPos)))
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

