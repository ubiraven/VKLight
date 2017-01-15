//
//  SplashScreenView.swift
//  VKLight
//
//  Created by Admin on 23.12.16.
//  Copyright © 2016 ArtemyevSergey. All rights reserved.
//

import UIKit

class SplashScreenView: UIView {
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.orange.cgColor,
                                UIColor.yellow.cgColor]
        self.layer.addSublayer(gradientLayer)
        
    }
    
    required init (coder: NSCoder) {
        super.init(coder: coder)!
        
        print(1)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.layer.frame
        gradientLayer.colors = [UIColor.orange.cgColor,
                                UIColor.yellow.cgColor]
        self.layer.addSublayer(gradientLayer)
        print(self.layer.sublayers!)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
