//
//  AZMetaBallCanvas.swift
//  RedPoint
//
//  Created by 张晨旭 on 16/7/15.
//  Copyright © 2016年 张晨旭. All rights reserved.
//

import Foundation
import UIKit

public protocol AZMetaBallCanvasDelegate: NSObjectProtocol {
    func deinitMetaBallCanvas()
    func metaBallCanvasEnded()
}

class AZMetaBallCanvas: UIView, CAAnimationDelegate, POPAnimationDelegate {
    var azMetaBallItem: AZMetaBallItem
    /** 画线 */ var path :UIBezierPath?
    /** 触摸点 */ var touchPoint:CGPoint = CGPoint()
    /** 是否触摸 */  var isTouch:Bool = false
    /** 连心线长度 */  var distance:Float = 0
    let iV = UIImageView()
    var explosionAnimation: CAKeyframeAnimation?
    var popbackAnimation: POPSpringAnimation?
    var touchView:UIView?
    
    weak var delegate: AZMetaBallCanvasDelegate?

    init(azMetaBallItem: UIView) {
        self.azMetaBallItem = AZMetaBallItem(view: azMetaBallItem)
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = UIColor.clear
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.AppDidEnterBackground), name: NSNotification.Name(rawValue: "WillResignActive"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.AppDidEnterBackground), name: NSNotification.Name(rawValue: "UIDeviceOrientationDidChangeNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.AppDidEnterBackground), name: NSNotification.Name(rawValue: "WillChangeController"), object: nil)
    }
    
    deinit {
        self.delegate?.deinitMetaBallCanvas()
        window?.isUserInteractionEnabled = true
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func AppDidEnterBackground() {
        self.touchView?.isHidden = false
        self.reset()
    }
    
    //MARK: drawRect
    override func draw(_ rect: CGRect) {
        self.path = UIBezierPath()
        self.caculateDistance(self.azMetaBallItem.centerCircle, circle2: self.azMetaBallItem.touchCircle)
        if !isTouch || distance > self.azMetaBallItem.maxDistance {
            return
        }
        self.drawBezierCurve(self.azMetaBallItem.centerCircle, circle2: self.azMetaBallItem.touchCircle)
        self.drawCenterCircle()
        self.drawTouchCircle()
    }

    func reset() {
        self.dragEnded()
        let window = UIApplication.shared.keyWindow
        window?.isUserInteractionEnabled = true
        self.explosionAnimation?.delegate = nil
        self.popbackAnimation?.delegate = nil
        self.touchView?.pop_removeAllAnimations()
        self.iV.layer.removeAllAnimations()
        self.delegate?.deinitMetaBallCanvas()
        self.removeFromSuperview()
    }
    
    func dragEnded() {
        self.isTouch = false
        //self.azMetaBallItem.view.removeFromSuperview()
        self.distance = 0
    }
    
    func dragAnimation(_ touch:UIView, recognizer:UIGestureRecognizer)  {
        self.touchPoint = recognizer.location(in: self)
        self.touchView = touch
        
        switch recognizer.state {
        case .began:
            if let window = UIApplication.shared.keyWindow {
                self.frame = CGRect(x: 0, y: 0, width: window.frame.size.width, height: window.frame.size.height)
                self.isUserInteractionEnabled = false
                window.isUserInteractionEnabled = false
                window.addSubview(self)
                //self.resetTouchCenter(self.cell.indicatorView.center)
                //self.addSubview(self.azMetaBallItem.view)
            }
            isTouch = true
        case .changed:
            self.touchView?.isHidden = true
            self.resetTouchCenter(touchPoint)
        case .ended:
            if distance > self.azMetaBallItem.maxDistance {
                self.explosion()
                self.delegate?.metaBallCanvasEnded()
            } else {
                self.touchView?.isHidden = false
                if let tv = self.touchView {
                    self.springBack(tv, fromPoint: touchPoint, toPoint: tv.center)
                } else {
                    self.reset()
                }
            }
            self.dragEnded()
        default:
            break
        }
        self.setNeedsDisplay()
    }
    
    //MARK: draw circle
    func drawCenterCircle() {
        self.azMetaBallItem.centerCircle.radius = self.azMetaBallItem.centerCircle.orignRadius - distance / 15
        self.drawCircle(self.path!, circle: self.azMetaBallItem.centerCircle)
    }
    
    func drawTouchCircle (){
        self.azMetaBallItem.touchCircle.radius = self.azMetaBallItem.touchCircle.orignRadius - distance / 30
        self.drawCircle(self.path!, circle: self.azMetaBallItem.touchCircle)
    }
    
    func drawCircle(_ path :UIBezierPath, circle :Circle){
        self.path?.addArc(withCenter: circle.centerPoint!, radius: CGFloat(circle.radius), startAngle: 0, endAngle: 360, clockwise: true)
        circle.color?.setFill()
        self.path!.fill()
        self.path!.removeAllPoints()
    }
    
    //MARK: reset touch center point of touch circle and touch view
    func resetTouchCenter(_ center:CGPoint) {
        self.azMetaBallItem.touchCircle.centerPoint = center
    }

    //MARK: caculate distance of two circle
    func caculateDistance(_ circle1: Circle, circle2: Circle){
        
        let circle1_x:Float = Float(circle1.centerPoint!.x);
        let circle1_y:Float = Float(circle1.centerPoint!.y);
        let circle2_x:Float = Float(circle2.centerPoint!.x);
        let circle2_y:Float = Float(circle2.centerPoint!.y);
        //连心线的长度
        distance = sqrt(powf(circle1_x - circle2_x, 2) + powf(circle1_y - circle2_y, 2));
    }

    //MARK: draw curve
    func drawBezierCurve(_ circle1: Circle, circle2: Circle){
        let circle1_x:Float = Float((circle1.centerPoint?.x)!)
        let circle1_y:Float = Float((circle1.centerPoint?.y)!)
        let circle2_x:Float = Float((circle2.centerPoint?.x)!)
        let circle2_y:Float = Float((circle2.centerPoint?.y)!)
        //连心线长度
        let d = sqrt(powf(circle1_x - circle2_x,2) + powf(circle1_y-circle2_y, 2))
        //连心线x轴夹角
        //0 can't be the denominator
        var angle1:Float = 0
        if (circle1_x - circle2_x) != 0 {
            angle1 = atan((circle2_y - circle1_y) / (circle1_x - circle2_x))
        }
        
        //连心线和公切线的夹角
        var angle2:Float = 0
        if d != 0 {
            angle2 = asin((circle1.radius - circle2.radius) / d)
        }
        //切点到圆心和x轴的夹角
        let angle3 = Float(Double.pi/2) - angle1 - angle2
        let angle4 = Float(Double.pi/2) - angle1 + angle2

        let offset1_X = cos(angle3) * circle1.radius
        let offset1_Y = sin(angle3) * circle1.radius
        let offset2_X = cos(angle3) * circle2.radius
        let offset2_Y = sin(angle3) * circle2.radius
        let offset3_X = cos(angle4) * circle1.radius
        let offset3_Y = sin(angle4) * circle1.radius
        let offset4_X = cos(angle4) * circle2.radius
        let offset4_Y = sin(angle4) * circle2.radius
        
        let p1_x = circle1_x - offset1_X
        let p1_y = circle1_y - offset1_Y
        let p2_x = circle2_x - offset2_X
        let p2_y = circle2_y - offset2_Y
        let p3_x = circle1_x + offset3_X
        let p3_y = circle1_y + offset3_Y
        let p4_x = circle2_x + offset4_X
        let p4_y = circle2_y + offset4_Y
        
        let p1 = CGPoint(x: CGFloat(p1_x), y: CGFloat(p1_y));
        let p2 = CGPoint(x: CGFloat(p2_x), y: CGFloat(p2_y));
        let p3 = CGPoint(x: CGFloat(p3_x), y: CGFloat(p3_y));
        let p4 = CGPoint(x: CGFloat(p4_x), y: CGFloat(p4_y));
        
        let p1_center_p4 = CGPoint(x: (CGFloat(p1_x) + CGFloat(p4_x))/2, y: (CGFloat(p1_y) + CGFloat(p4_y))/2)
        let p2_center_p3 = CGPoint(x: (CGFloat(p2_x) + CGFloat(p3_x))/2, y: (CGFloat(p2_y) + CGFloat(p3_y))/2)
        
        
        self.drawBezierCurveStart(p1, endPoint: p2, controlPoint: p2_center_p3)
        self.drawLineStart(p2, endPoint: p4)
        self.drawBezierCurveStart(p4, endPoint: p3, controlPoint: p1_center_p4)
        self.drawLineStart(p3, endPoint: p1)
        
        path?.move(to: p1)
        path?.close()
        path?.fill()
    }

    func drawLineStart(_ startPoint:CGPoint, endPoint:CGPoint) {
        path?.addLine(to: endPoint)
        UIColor.blue.setStroke()
        UIColor.blue.setFill()
        path?.fill()
    }
    
    func drawBezierCurveStart(_ startPoint:CGPoint, endPoint:CGPoint, controlPoint:CGPoint) {
        path?.move(to: startPoint)
        path?.addQuadCurve(to: endPoint, controlPoint: controlPoint)
    }

    //MARK: animation
    //爆炸效果
    func explosion() {
        var array = [CGImage]()
        for i in 1..<6 {
            if let image = UIImage(named: "blue-dot-animation-\(i)")?.cgImage {
                array.append(image)
            }
        }
        iV.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        iV.center = touchPoint
        self.addSubview(iV)
        let animation = CAKeyframeAnimation(keyPath:"contents")
        animation.calculationMode = CAAnimationCalculationMode.discrete
        animation.duration = 0.2
        animation.values = array
        animation.repeatCount = 1
        animation.isRemovedOnCompletion = true
        animation.delegate = self
        self.iV.layer.add(animation, forKey:"animation")
        self.explosionAnimation = animation
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.reset()
    }
    
    //回弹效果
    func springBack(_ view:UIView , fromPoint:CGPoint, toPoint:CGPoint){
    
        var fromPoint = fromPoint
    //计算fromPoint在view的superView为坐标系里的坐标
        let viewPoint: CGPoint = PointUtils.getGlobalPositionOf(view)
        fromPoint.x = fromPoint.x - viewPoint.x + toPoint.x
        fromPoint.y = fromPoint.y - viewPoint.y + toPoint.y
        view.center = fromPoint
    
        let anim = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
        anim?.fromValue = NSValue(cgPoint:fromPoint)
        anim?.toValue = NSValue(cgPoint:toPoint)
        anim?.springBounciness = 4.0 //[0-20] 弹力 越大则震动幅度越大
        anim?.springSpeed = 20.0     //[0-20] 速度 越大则动画结束越快
        anim?.dynamicsMass = 3.0     //质量
        anim?.dynamicsFriction = 30.0//摩擦，值越大摩擦力越大，越快结束弹簧效果
        anim?.dynamicsTension = 676.0//拉力
        anim?.delegate = self
        self.popbackAnimation = anim
        view.pop_add(anim, forKey: kPOPLayerPosition)
    }
    
    func pop_animationDidStop(_ anim: POPAnimation!, finished: Bool) {
        self.reset()
    }
}

