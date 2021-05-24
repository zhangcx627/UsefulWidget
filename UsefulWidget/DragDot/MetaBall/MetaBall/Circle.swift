//
//  Circle.swift
//  RedPoint
//
//  Created by 张晨旭 on 16/7/15.
//  Copyright © 2016年 张晨旭. All rights reserved.
//

import Foundation
import UIKit

class Circle {
    
    var radius :Float = 0.0
    var centerPoint :CGPoint?
    
    var color :UIColor?
    var orignRadius: Float = 0.0
    
    func initWithcenterPoint(_ center:CGPoint , radius:Float) -> Circle {
        self.centerPoint = center
        self.radius = radius
        self.orignRadius = radius

        self.color = UIColor.blue
        
        return self
    }
    
    func initWithcenterPoint(_ center:CGPoint , radius:Float , color:UIColor) -> Circle{
        let _ = self.initWithcenterPoint(center, radius: radius)
        self.color = color
        return self
    }
    
    func description() -> String {
        return "point :\(String(describing: self.centerPoint)) radius:\(self.radius) color :\(String(describing: self.color))"
    }
}
