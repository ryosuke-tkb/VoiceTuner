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
    let compos = [["Sop", "Alt", "Ten", "Bas"],["sharp","flat"],["0","1","2","3","4","5","6","7"]]
    
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
    
    // return component size
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return compos.count
    }
    
    // return row size of each component
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let compo = compos[component]
        return compo.count
    }
    
    
    // return width of each component
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 0 {
            return 50
        }else if component == 1 {
            return 80
        }else {
            return 30
        }
    }
    
    // return selected item
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let item = compos[component][row]
        return item
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        appDelegate.message = compos[component][row]
        appDelegate.clef = compos[component][row]
        let row1 = pickerView.selectedRow(inComponent: 0)
        let row2 = pickerView.selectedRow(inComponent: 1)
        let row3 = pickerView.selectedRow(inComponent: 2)
        
        appDelegate.tonality = self.pickerView(pickerView, titleForRow: row2, forComponent: 1)
        appDelegate.NumOfAccidental = Int(self.pickerView(pickerView, titleForRow: row3,forComponent: 2)!)!
        print(compos[component][row])
    }

    internal func onClickMyButton(sender: UIButton){        
        let myViewController: UIViewController = SpectralViewController()
        
        myViewController.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        
        self.present(myViewController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
