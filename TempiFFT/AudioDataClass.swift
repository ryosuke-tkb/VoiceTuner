//
//  AudioDataClass.swift
//  wave2
//
//  Created by 若狭　健太 on 2017/04/29.
//  Copyright © 2017年 wakasa. All rights reserved.
//

import Foundation
import AVFoundation

class AudioDataClass{
    
    //object for audio file
    var audioFile:AVAudioFile!
    
    //buffer for PCM data 便宜上AVAudioPCMBuffer型の変数を用意
    //クラス外から実際にバイナリデータにアクセスする際はbufferプロパティを使う。
    var PCMBuffer:AVAudioPCMBuffer!
    
    // audio file address
    var address:String
    
    //オーディオのバイナリデータを格納するためのbuffer, マルチチャンネルに対応するため、二次元配列になっています。
    var buffer:[[Float]]! = Array<Array<Float>>()
    
    //オーディオデータの情報
    var samplingRate:Double?
    var nChannel:Int?
    var nframe:Int?
    
    //initializer
    init(address:String){
        self.address = address
    }
    
    
    
    //import audio file
    func loadAudioData(){
        
        //create AVAudioFile
        //error handling do catch
        do{
            
            //オーディオファイルを読み込み、データをaudioFileに格納
            self.audioFile = try AVAudioFile(forReading: NSURL(fileURLWithPath: self.address) as URL)
            //get samplingRate
            self.samplingRate = self.audioFile.fileFormat.sampleRate
            //get channel
            self.nChannel = Int(self.audioFile.fileFormat.channelCount)
            
        }catch{
            //読み込み失敗
            print("Error : loading audio file \(self.address) failed.")
        }
        
        //もしオーディオファイル読み込みが成功していたら、バイナリデータを取得する
        if(self.audioFile != nil){
            
            //get frame length
            self.nframe = Int(self.audioFile.length)
            
            //allocate
            self.PCMBuffer = AVAudioPCMBuffer(pcmFormat: self.audioFile.processingFormat, frameCapacity: AVAudioFrameCount(self.nframe!))
            
            //error handling
            do{
                //audioFileから、PCMBufferにバイナリデータを取得する
                try self.audioFile.read(into: self.PCMBuffer)
                
                //各チャンネル毎にバイナリデータをbufferに追加する
                for i in 0..<self.nChannel!{
                    
                    let buf:[Float] = Array(UnsafeMutableBufferPointer(start:self.PCMBuffer.floatChannelData![i], count:self.nframe!))
                    
                    self.buffer.append(buf)
                    
                }
                
            }catch{
                print("loading audio data failed.")
            } 
        }
    }
    
    

    //arg1: data:[[Float]] : バイナリデータを保持した、多チャンネルに対応したバッファ。クラス内ではbufferプロパティに対応する。
    //arg2: address : オーディオファイル書き出し先＋ファイル名
    //arg3: format : writeAudioData()メソッド使用前にloadAudioData()メソッドを使用してオーディオファイルを読み込んでいる場合、新たにformatを指定する必要はない。その場合はnilを渡す。
    //もしバイナリデータのフォーマットを変えたい場合などはここに指定する。
    
    func writeAudioData(data:[[Float]],address:String,format:AVAudioFormat?)->Bool{
        
        //バイナリデータフォーマットを格納する
        var audioformat:AVAudioFormat?
        
        
        let nChannel:Int = data.count
        let nframe:Int = data[0].count
        
//フレーム数が0の場合、dataは空。
        if(nframe == 0){print("Error : no data."); return false}
        
        //チャンネル数が0であれば、dataは空
        if(nChannel > 0){
            
//読み込んだオーディオファイルと同じフバイナリフォーマットで書き出す場合
            if(format == nil){ // we follow loaded audio file format
                
//サンプリングレートの設定がなければ、デフォルトの44100hzを採用
                if(self.samplingRate == nil){self.samplingRate = 44100;}
                
                if(self.audioFile != nil){
                    
                    //setup audio format
                    audioformat = AVAudioFormat(standardFormatWithSampleRate: self.samplingRate!, channels: AVAudioChannelCount(nChannel))
                }
                
            }else{// we use new audio file format
                audioformat = format
            }
        }else{
            return false
        }
        
        //make PCMBuffer
        let buffer = AVAudioPCMBuffer(pcmFormat:audioformat!, frameCapacity: AVAudioFrameCount(nframe))
        //update frameLength which is the actual size of the file to be written in a disk
        buffer.frameLength = AVAudioFrameCount(nframe)
        
        //copy input data to PCMBuffer
        
        for i in 0..<nChannel{
            for j in 0..<nframe{
                buffer.floatChannelData?[i][j] = data[i][j]
            }
        }
        //make an audio file for writing
        var writeAudioFile:AVAudioFile?
        
        do{
            //書き出すオーディオファイルのフォーマット
            writeAudioFile = try AVAudioFile(forWriting: NSURL(fileURLWithPath: address) as URL, settings: [
                AVFormatIDKey:Int(kAudioFormatLinearPCM), // file format
                AVSampleRateKey:audioformat!.sampleRate,
                AVNumberOfChannelsKey:nChannel,
                AVEncoderBitRatePerChannelKey:16 // 16bit
                ])
            
        }catch{
            print("Error : making audio file failed.")
            return false
        }
        
        //export an audio file
        do{
            //書き出し
            try writeAudioFile!.write(from: buffer)
            print("\(nframe) samples are written in \(address)")
            
        }catch{
            print("Error : Could not export audio file")
            return false
        }
        
        return true
    }
    
}




