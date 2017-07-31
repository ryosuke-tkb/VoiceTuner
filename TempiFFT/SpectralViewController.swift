//
//  SpectralViewController.swift
//  TempiHarness
//
//  Created by John Scalo on 1/7/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import UIKit
import AVFoundation

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
    
    override func didReceiveMemoryWarning() {
        NSLog("*** Memory!")
        super.didReceiveMemoryWarning()
    }
}

