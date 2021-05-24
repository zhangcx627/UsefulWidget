//
//  PointUntils.swift
//  RedPoint
//
//  Created by 张晨旭 on 16/7/15.
//  Copyright © 2016年 张晨旭. All rights reserved.
//

import Foundation
import UIKit


class PointUtils: NSObject {
    
   static func getGlobalCenterPositionOf(_ view:UIView) -> CGPoint {
       var point = self.getGlobalPositionOf(view)
        let w = view.frame.size.width
        let h = view.frame.size.height
        point.x += w/2
        point.y += h/2
        return point
    }
    
   static func getGlobalPositionOf(_ view:UIView) -> CGPoint {
    //FIXME: 
        let window = UIApplication.shared.keyWindow
//    delegate?.window
        let rect = view.convert(view.bounds, to: window!)
        return rect.origin
    }
}

