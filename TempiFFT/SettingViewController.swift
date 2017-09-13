//
//  SettingViewController.swift
//  TempiFFT
//
//  Created by Ryosuke Nakagawa on 2017/09/08.
//  Copyright © 2017年 John Scalo. All rights reserved.
//

import Foundation
import UIKit

class SettingViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let part = ["Sop", "Alt", "Ten", "Bas"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        // make button.
        let backButton: UIButton = UIButton()
        backButton.backgroundColor = UIColor.red
        backButton.setTitle("back", for: .normal)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.layer.cornerRadius = 5.0
        backButton.addTarget(self, action: #selector(onClickMyButton(sender:)), for: .touchUpInside)
        self.view.addSubview(backButton)
        
        
        // AutoLayout
        backButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 30.0).isActive = true
        backButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30.0).isActive = true
        backButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.1).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.delegate = self
        picker.dataSource = self
        picker.selectRow(1, inComponent: 0, animated: true)
        
        self.view.addSubview(picker)
        
        // AutoLayout
        picker.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        picker.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50.0).isActive = true
        picker.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.6).isActive = true
        picker.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return part.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return part[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        appDelegate.message = part[row]
        appDelegate.clef = part[row]
        print(part[row])
    }
    /*
     ボタンイベント.
     */
    internal func onClickMyButton(sender: UIButton){        
        // 遷移するViewを定義.
        let myViewController: UIViewController = SpectralViewController()
        
        // アニメーションを設定.
        myViewController.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        
                
        // Viewの移動.
        self.present(myViewController, animated: true, completion: nil)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let spectralViewController = segue.destination as! SpectralViewController
//        spectralViewController.selectedTonality = "moved"
//        
//    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
