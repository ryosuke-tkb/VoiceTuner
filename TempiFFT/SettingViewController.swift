//
//  SettingViewController.swift
//  TempiFFT
//
//  Created by Ryosuke Nakagawa on 2017/09/08.
//  Copyright © 2017年 John Scalo. All rights reserved.
//

import Foundation
import UIKit

class SettingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        // make button.
        let backButton: UIButton = UIButton(frame: CGRect(x: 0,y: 0, width: 120, height: 50))
        backButton.backgroundColor = UIColor.red
        backButton.layer.masksToBounds = true
        backButton.setTitle("back", for: .normal)
        backButton.layer.cornerRadius = 20.0
        backButton.layer.position = CGPoint(x: self.view.bounds.width/2 , y:self.view.bounds.height-50)
        backButton.addTarget(self, action: #selector(onClickMyButton(sender:)), for: .touchUpInside)
        self.view.addSubview(backButton)
    }
    
    /*
     ボタンイベント.
     */
    internal func onClickMyButton(sender: UIButton){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.message = "Hello"
        
        // 遷移するViewを定義.
        let myViewController: UIViewController = SpectralViewController()
        
        // アニメーションを設定.
        myViewController.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        
                
        // Viewの移動.
        self.present(myViewController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let spectralViewController = segue.destination as! SpectralViewController
        spectralViewController.selectedTonality = "moved"
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
