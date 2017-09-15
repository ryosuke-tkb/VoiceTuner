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
    var recodingState: Bool = true
    enum BtnTag: Int {
        case setting = 100
        case recordSwitch = 101
        case debug = 102
    }
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
        
        // make button to switch recode state
        let recordSwitchButton = UIButton()
        recordSwitchButton.setTitle("Stop", for: .normal)
        recordSwitchButton.setTitleColor(UIColor.white, for: .normal)
        recordSwitchButton.backgroundColor = UIColor.red
        recordSwitchButton.layer.cornerRadius = 5.0
        recordSwitchButton.addTarget(self, action: #selector(onClickRecordButton(sender:)), for: .touchUpInside)
        recordSwitchButton.tag = BtnTag.recordSwitch.rawValue
        recordSwitchButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(recordSwitchButton)
        
        recordSwitchButton.topAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -100).isActive = true
        recordSwitchButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        recordSwitchButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        recordSwitchButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
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
        let cepstrum :[Double] = fft.calculateCepstrum(samples)
        
        // Interpoloate the FFT data so there's one band per pixel.
        let screenWidth = UIScreen.main.bounds.size.width * UIScreen.main.scale
        fft.calculateLinearBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, numberOfBands: Int(screenWidth))

        // conduct in main queue
        tempi_dispatch_main { () -> () in
            self.spectralView.fft = fft
            self.spectralView.cepstrum = cepstrum
            self.spectralView.guessedFreq = Int(fft.freq)
            self.spectralView.midiNN = fft.midiNN
            self.spectralView.midiNNhistory.removeFirst()
            self.spectralView.midiNNhistory.append(fft.midiNN)
            self.spectralView.setNeedsDisplay()
        }
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
    
    func onClickRecordButton(sender: UIButton) {
        if recodingState {
            sender.setTitle("Start", for: .normal)
            print("stop button pushed")
            audioInput.stopRecording()

            recodingState = false
        }else {
            sender.setTitle("Stop", for: .normal)
            print("start button pushed")
            audioInput.startRecording()
            
            recodingState = true
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

