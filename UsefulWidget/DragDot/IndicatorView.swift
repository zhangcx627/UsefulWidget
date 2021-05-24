//
//  IndicatorView.swift
//  UsefulWidget
//
//  Created by chenxu on 2021/5/24.
//

import UIKit
let PADDING:CGFloat = 1.5

class IndicatorView: UIView {
    var indicatorColor:UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var innerColor:UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ r: CGRect) {
        let rect = CGRect(x: PADDING, y: PADDING, width: r.size.width - 2 * PADDING, height: r.size.height - 2 * PADDING)
        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.addEllipse(in: rect)
            if let indicatorColor = self.indicatorColor {
                //http://stackoverflow.com/questions/3742971/only-white-fill-color-is-transparent-in-uiview
                ctx.setFillColor(indicatorColor.cgColor)
            }
            ctx.fillPath()
            if let innerColor = self.innerColor {
                //white bg
                let bgSize = rect.size.width - 3
                let bgRect = CGRect(x: rect.origin.x + 1.5, y: rect.origin.y + 1.5, width: bgSize, height: bgSize)
                ctx.addEllipse(in: bgRect)
                ctx.setFillColor(UIColor.white.cg(for: traitCollection))
                ctx.fillPath()
                
                //inner
                let innerSize = rect.size.width * 0.5
                let innerRect = CGRect(x: rect.origin.x + rect.size.width * 0.5 - innerSize * 0.5, y: rect.origin.y + rect.size.height * 0.5 - innerSize * 0.5, width: innerSize, height: innerSize)
                ctx.addEllipse(in: innerRect)
                ctx.setFillColor(innerColor.cgColor)
                ctx.fillPath()
            }
        }
        super.draw(r)
    }


}
