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
    var inData: [Float]!
    
    // called immediately after a screen has been displayed
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        spectralView = SpectralView(frame: self.view.bounds)
        spectralView.backgroundColor = UIColor.white
        spectralView.noteImage = UIImage(named: "zen-onpu.png")
        spectralView.prepareNoteImage()
        self.view.addSubview(spectralView)
        
        // prepare Image View
        let imageView = UIImageView()
        
        // set photo file
        if appDelegate.clef == nil {
            imageView.image = UIImage(named: "G_clef_resized.png")
        } else if appDelegate.clef == "Bas" {
            imageView.image = UIImage(named: "F_clef_resized.png")
        } else {
            imageView.image = UIImage(named: "G_clef_resized.png")
        }
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(imageView)
        
        // this part is Auto Laytout by NSLayoutAnchor
        imageView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.5).isActive = true
        imageView.widthAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.5 * imageView.image!.size.width / imageView.image!.size.height).isActive = true
        
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
            self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: Int(numberOfFrames), samples: samples)
        }
        
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: 44100, numberOfChannels: 1)
        audioInput.startRecording()
        
        // draw 5 lines
        for i in -2...2 {
            let lineImage = self.makeScoreImage(pos_y: self.view.bounds.height * 0.5 + self.view.bounds.height * 1/16 * CGFloat(i))
            let lineView = UIImageView(image: lineImage)
            self.view.addSubview(lineView)
        }
        
        if appDelegate.NumOfAccidental != 0 {
            if let tmpView = self.view.viewWithTag(2000) {
                tmpView.removeFromSuperview()
            }
            let tonalityView = UIView()
            tonalityView.translatesAutoresizingMaskIntoConstraints = false
            tonalityView.tag = 2000
            self.view.addSubview(tonalityView)
            
            tonalityView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            tonalityView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            tonalityView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
            tonalityView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
            
            if appDelegate.tonality == "sharp" {
                let deltaCoef: [CGFloat] = [-4,-1,-5,-2,1,-3,0]
                for i in 0 ..< appDelegate.NumOfAccidental {
                    let imageView = UIImageView()
                    imageView.image = UIImage(named: "sharp.png")
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    tonalityView.addSubview(imageView)
                    
                    imageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: self.view.bounds.height * 1/32 * deltaCoef[i]).isActive = true
                    imageView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: CGFloat(100 + 10 * i)).isActive = true
                    imageView.heightAnchor.constraint(equalToConstant: self.view.bounds.height * 1/16 * 1.5).isActive = true
                    imageView.widthAnchor.constraint(equalToConstant: self.view.bounds.height * 1/16 * 1.5 * imageView.image!.size.width / imageView.image!.size.height).isActive = true
                }
            }else if appDelegate.tonality == "flat" {
                let deltaCoef: [CGFloat] = [0,-3,1,-2,2,-1,3]
                
            }
        }else {
            if let tmpView = self.view.viewWithTag(2000) {
                tmpView.removeFromSuperview()
            }
        }
        
        // make stop button
        let stopButton = UIButton()
        stopButton.setTitle("Stop", for: .normal)
        stopButton.setTitleColor(UIColor.yellow, for: .normal)
        stopButton.backgroundColor = UIColor.black
        stopButton.addTarget(self, action: #selector(stopButtonEvent(sender:)), for: .touchUpInside)
        stopButton.sizeToFit()
        stopButton.frame = CGRect(x: self.view.bounds.midX + 80, y: self.view.bounds.maxY - 45, width: 80, height: 40)
        self.view.addSubview(stopButton)
        
        // make start button
        let startButton = UIButton()
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(UIColor.yellow, for: .normal)
        startButton.backgroundColor = UIColor.black
        startButton.addTarget(self, action: #selector(startButtonEvent(sender:)), for: .touchUpInside)
        startButton.sizeToFit()
        startButton.frame = CGRect(x: self.view.bounds.midX - 80, y: self.view.bounds.maxY - 45, width: 80, height: 40)
        self.view.addSubview(startButton)
        
        // make debug mode button
        let debugButton = UIButton()
        debugButton.setTitle("debug", for: .normal)
        debugButton.setTitleColor(UIColor.yellow, for: .normal)
        debugButton.backgroundColor = UIColor.black
        debugButton.addTarget(self, action: #selector(switchDebugMode(sender:)), for: .touchUpInside)
        debugButton.sizeToFit()
        debugButton.frame = CGRect(x: 450, y: 20, width: 80, height: 20)
        self.view.addSubview(debugButton)
        
        // make setting mode button.
        let settingButton: UIButton = UIButton()
        settingButton.layer.masksToBounds = true
        settingButton.translatesAutoresizingMaskIntoConstraints = false
        settingButton.addTarget(self, action: #selector(onClickMyButton(sender:)), for: .touchUpInside)
        settingButton.setImage(UIImage(named: "setting.png"), for: UIControlState.normal)
        self.view.addSubview(settingButton)
        
        settingButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 15.0).isActive = true
        settingButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 15.0).isActive = true
        settingButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        settingButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    func gotSomeAudio(timeStamp: Double, numberOfFrames: Int, samples: [Float]) {
        let fft = TempiFFT(withSize: numberOfFrames, sampleRate: 44100.0)
        fft.windowType = TempiFFTWindowType.hanning
        fft.fftForward(samples)
        
        self.inData = samples
        let cepstrum :[Double] = calculateCepstrum(samples)
        
        // get max value's index
        let (maxI, _) = cepstrum[100...411].enumerated().max(by: {$0.element < $1.element})!
        
        // calculate frequency from max value's index
        let freq = 44100/(maxI+100)
        
        // convert frequency to MIDI note number
        let nn :Int = 69 + Int(round(12 * log2f(Float(freq)/440)))
        
        // Interpoloate the FFT data so there's one band per pixel.
        let screenWidth = UIScreen.main.bounds.size.width * UIScreen.main.scale
        fft.calculateLinearBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, numberOfBands: Int(screenWidth))

        // conduct in main queue
        tempi_dispatch_main { () -> () in
            self.spectralView.fft = fft
            self.spectralView.cepstrum = cepstrum
            self.spectralView.guessedFreq = Int(freq)
            self.spectralView.midiNN = nn
            self.spectralView.midiNNhistory.removeFirst()
            self.spectralView.midiNNhistory.append(nn)
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
    
    func switchDebugMode(sender: UIButton) {
        if self.spectralView.isDebugMode {
            self.spectralView.switchOffDebugMode()
            if let infoView = self.spectralView.viewWithTag(100) {
                infoView.removeFromSuperview()
            }
        }else {
            self.spectralView.switchOnDebugMode()
        }
    }
    
    internal func onClickMyButton(sender: UIButton){
        // define transition destination view
        let myViewController: UIViewController = SettingViewController()
        
        // set animation mode
        myViewController.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        
        // move to defined view
        self.present(myViewController, animated: true, completion: nil)
    }
    
    // function name isn't match. drawLine is more proper
   func makeScoreImage(pos_y: CGFloat) -> UIImage {
        let size = view.bounds.size
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        
        let line = UIBezierPath()
        line.move(to: CGPoint(x: 0, y: pos_y))
        line.addLine(to: CGPoint(x: size.width, y: pos_y))
        line.close()
        
        UIColor.black.setStroke()
        UIColor.black.setFill()
        line.lineWidth = 2.0
        line.stroke()
    
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        return image!
    }
    
    func calculateCepstrum(_ inBuffer:[Float]) -> [Double] {
        // cast float to double
        let doubleInBuffer = inBuffer.map{Double($0)}
        var samples = doubleInBuffer
        let inputSize :Int = samples.count
        
        // multiple hamming window
        var window = [Double](repeating: 0.0, count: inputSize)
        vDSP_hamm_windowD(&window, UInt(inputSize), 0)
        vDSP_vmulD(doubleInBuffer, 1, window, 1, &samples, 1, UInt(inputSize))
        
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
        let ifftSplitComplexSrc :UnsafePointer<DSPDoubleComplex> = UnsafeRawPointer(magnitudes).bindMemory(to: DSPDoubleComplex.self, capacity: inputSize)
        
        vDSP_ctozD(ifftSplitComplexSrc, 2, &ifftSplitComplex, 1, vDSP_Length(inputSize/2))
        
        let ifftSetup = vDSP_create_fftsetupD(log2fftSize, FFTRadix(FFT_RADIX2))
        
        vDSP_fft_zripD(ifftSetup!, &ifftSplitComplex, 1, UInt(log2fftSize), Int32(FFTDirection(FFT_INVERSE)))
        
        var ifftScale :Double = 1/Double(inputSize)
        vDSP_vsmulD(ifftSplitComplex.realp, 1, &ifftScale, ifftSplitComplex.realp, 1, vDSP_Length(inputSize/2))
        vDSP_vsmulD(ifftSplitComplex.imagp, 1, &ifftScale, ifftSplitComplex.imagp, 1, vDSP_Length(inputSize/2))
        
        let ifftOutputReal = Array(UnsafeBufferPointer(start: ifftSplitComplex.realp, count: fftSize/2))
        let ifftOutputImag = Array(UnsafeBufferPointer(start: ifftSplitComplex.imagp, count: fftSize/2))
        
        var cepstrum = [Double]()
        for index in 0 ..< fftSize/2 {
            let ri = ifftOutputReal[index]
            let ii = ifftOutputImag[index]
            cepstrum.append(sqrt(ri * ri + ii * ii))
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
            let xPos = i
            if (i < 100 || yPos.isNaN || yPos.isInfinite) {
                yPos = 100
            }else {
                yPos = abs(yPos) * 30 + 100
            }
            line.addLine(to : CGPoint(x: xPos + 5, y: Int(yPos)))
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

