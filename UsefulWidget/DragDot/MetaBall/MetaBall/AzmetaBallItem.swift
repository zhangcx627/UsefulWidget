//
//  AzmetaBallItem.swift
//  RedPoint
//
//  Created by 张晨旭 on 16/7/15.
//  Copyright © 2016年 张晨旭. All rights reserved.
//

import Foundation
import UIKit

class AZMetaBallItem:NSObject {
    let kMaxDistance:Float = 65.0
    
    var view:UIView!
    var centerCircle:Circle = Circle()
    var touchCircle:Circle = Circle()
    var maxDistance:Float = 0
    
    init(view:UIView) {
        super.init()
        self.view = self.duplicate(view)
        
        let w:Float = Float(view.frame.size.width + 3)
        let h:Float = Float(view.frame.size.height + 3)
        
        let point = PointUtils.getGlobalCenterPositionOf(view)
        
        self.centerCircle = Circle().initWithcenterPoint(point, radius: min(w, h)/2, color: UIColor.blue)
        self.touchCircle  = Circle().initWithcenterPoint(point, radius: min(w, h)/2, color: UIColor.blue)
        
        self.maxDistance = kMaxDistance
        
        if min(w, h) > 50 {
            self.maxDistance = 2 * kMaxDistance
        }
    }
    
    func duplicate(_ view: UIView) -> IndicatorView{
        let tempArchive = NSKeyedArchiver.archivedData(withRootObject: view)
        let emailView = NSKeyedUnarchiver.unarchiveObject(with: tempArchive) as! IndicatorView
        emailView.indicatorColor = UIColor.blue
        emailView.frame = CGRect(x: emailView.frame.origin.x,y: emailView.frame.origin.y,width: emailView.frame.size.width + 10, height: emailView.frame.size.height + 10)
        return emailView
    }
    
    
}

