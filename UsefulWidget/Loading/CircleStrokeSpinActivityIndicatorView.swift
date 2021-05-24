//
//  CircleStrokeSpinActivityIndicatorView.swift
//  UsefulWidget
//
//  Created by chenxu on 2021/5/24.
//

import UIKit

class CircleStrokeSpinActivityIndicatorView: UIView {
    var headImage = UIImageView()
    var imageName: String
    var imageFrame: CGRect
    var circleLayer: CALayer?
    
    init(imageName: String, frame: CGRect) {
        self.imageName = imageName
        self.imageFrame = frame
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateHeaderImage(name: String, email: String) {
        if self.headImage.bounds.size.height == 0 {
            self.headImage.frame = self.imageFrame
        }
        self.headImage.image = UIImage(named: self.imageName)
    }
    
    func setUpUI() {
        self.headImage.frame = self.imageFrame
        self.headImage.layer.cornerRadius = self.imageFrame.size.height/2.0
        self.headImage.clipsToBounds = true
        self.headImage.image = UIImage(named: self.imageName)
//            EdoTintImage(self.imageName)
        self.headImage.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.headImage)
        self.headImage.isUserInteractionEnabled = true
        self.headImage.snp.makeConstraints { (make) in
            make.top.bottom.leading.trailing.equalToSuperview().inset(1)
        }
    }
    
    func setUpAnimation(size: CGSize, color: UIColor) {
        let beginTime: Double = 0.5
        let strokeStartDuration: Double = 1.2
        let strokeEndDuration: Double = 0.7

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)

        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.duration = strokeEndDuration
        strokeEndAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
        strokeEndAnimation.fromValue = 0
        strokeEndAnimation.toValue = 1

        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.duration = strokeStartDuration
        strokeStartAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
        strokeStartAnimation.fromValue = 0
        strokeStartAnimation.toValue = 1
        strokeStartAnimation.beginTime = beginTime

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [rotationAnimation, strokeEndAnimation, strokeStartAnimation]
        groupAnimation.duration = strokeStartDuration + beginTime
        groupAnimation.repeatCount = .infinity
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = .forwards

        let layer: CAShapeLayer = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath()

        path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                    radius: size.width / 2,
                    startAngle: -(.pi / 2),
                    endAngle: .pi + .pi / 2,
                    clockwise: true)
        layer.fillColor = nil
        layer.strokeColor = color.cgColor
        layer.lineWidth = 2
        layer.backgroundColor = nil
        layer.path = path.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        let frame = CGRect(
            x: (layer.bounds.width - size.width) / 2,
            y: (layer.bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )

        layer.frame = frame
        layer.add(groupAnimation, forKey: "animation")
        self.circleLayer = layer
        self.layer.addSublayer(layer)
    }

    func stopAnimating() {
        if let layer = self.circleLayer {
            self.layer.sublayers?.removeObject(layer)
        }
    }

}
