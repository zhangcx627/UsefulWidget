//
//  UWPopupSWindow.swift
//  UWPopupView
//
//  Created by xfg on 2018/3/19.
//  Copyright © 2018年 xfg. All rights reserved.
//  弹窗window

/** ************************************************
 
 github地址：https://github.com/choiceyou/FWPopupView
 bug反馈、交流群：670698309
 
 ***************************************************
 */


import Foundation
import UIKit

public func kPV_RGBA (r:CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) -> UIColor {
    return UIColor (red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
}

open class UWPopupSWindow: UIWindow, UIGestureRecognizerDelegate {
    
    /// 单例模式
    @objc public class var sharedInstance: UWPopupSWindow {
        struct Static {
            static let kbManager = UWPopupSWindow(frame: UIScreen.main.bounds)
        }
        if #available(iOS 13.0, *) {
            if Static.kbManager.windowScene == nil {
                let windowScene = UIApplication.shared.connectedScenes.filter{$0.activationState == .foregroundActive}.first
                Static.kbManager.windowScene = windowScene as? UIWindowScene
            }
        }
        return Static.kbManager
    }
    // 默认false，当为true时：用户拖动外部遮罩层页面可以消失
    @objc open var panWildToHide: Bool = false
    
    /// 被隐藏的视图队列（A视图正在显示，接着B视图显示，此时就把A视图隐藏同时放入该队列）
    open var hiddenViews: [UIView] = []
    /// 将要展示的视图队列（A视图的显示或者隐藏动画正在进行中时，此时如果B视图要显示，则把B视图放入该队列，等动画结束从该队列中拿出来显示）
    open var willShowingViews: [UIView] = []
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let rootVC = UWPopupRootViewController()
        rootVC.view.backgroundColor = UIColor.clear
        self.rootViewController = rootVC
        
        self.windowLevel = UIWindow.Level.statusBar + 1
        
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(tapGesClick(tap:)))
        tapGest.delegate = self
        self.addGestureRecognizer(tapGest)
        
        let panGest = UIPanGestureRecognizer(target: self, action: #selector(panGesClick(pan:)))
        self.addGestureRecognizer(panGest)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UWPopupSWindow {
    
    @objc func tapGesClick(tap: UIGestureRecognizer) {
        
        if let attachView = self.attachView(), !attachView.UWBackgroundAnimating {
            for view in attachView.UWMaskView.subviews {
                if !self.hiddenViews.contains(view), let popupView = view as? UWMenuView {
                    if popupView.currentPopupViewState == .didAppear || popupView.currentPopupViewState == .didAppearAgain {
                        popupView.hide()
                    }
                }
            }
        }
    }
    
    @objc func panGesClick(pan: UIGestureRecognizer) {
        
        if self.panWildToHide {
            self.tapGesClick(tap: pan)
        }
    }
    
    /// 隐藏全部的弹窗（包括当前不可见的弹窗）
    @objc public func removeAllPopupView() {
        if let attachView = self.attachView() {
            for view in attachView.UWMaskView.subviews {
                if let popupView = view as? UWMenuView {
                    popupView.hide()
                }
            }
            attachView.hideUWBackground()
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.attachView()?.UWMaskView
    }
    
    public func attachView() -> UIView? {
        if self.rootViewController != nil {
            return self.rootViewController?.view
        } else {
            return nil
        }
    }
}

class UWPopupRootViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarStyle ?? UIStatusBarStyle.default
        } else {
            return UIApplication.shared.statusBarStyle
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.windowScene?.statusBarManager?.isStatusBarHidden ?? false
        } else {
            return UIApplication.shared.isStatusBarHidden
        }
    }
}

extension UIView {
    
    var UWBackgroundAnimating: Bool {
        get {
            if let key = UWBackgroundAnimatingKey, let isAnimating = objc_getAssociatedObject(self, key) as? Bool {
                return isAnimating
            }
            return false
        }
        set {
            if let key = UWBackgroundAnimatingKey {
                objc_setAssociatedObject(self, key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var UWAnimationDuration: TimeInterval {
        get {
            if let key = UWAnimationDurationKey, let duration = objc_getAssociatedObject(self, key) as? TimeInterval {
                return duration
            }
            return 0.0
        }
        set {
            if let key = UWAnimationDurationKey {
                objc_setAssociatedObject(self, key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var UWReferenceCount: Int {
        get {
            if let key = UWReferenceCountKey, let count = objc_getAssociatedObject(self, key) as? Int {
                return count
            }
            return 0
        }
        set {
            if let key = UWReferenceCountKey {
                objc_setAssociatedObject(self, key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    /// 遮罩层颜色
    var UWMaskViewColor: UIColor {
        get {
            if let key = UWBackgroundViewColorKey, let color = objc_getAssociatedObject(self, key) as? UIColor {
                return color
            }
            return kDefaultMaskViewColor
        }
        set {
            if let key = UWBackgroundViewColorKey {
                objc_setAssociatedObject(self, key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    /// 遮罩层
    var UWMaskView: UIView {
        guard let key = UWBackgroundViewKey else {
            return UIView()
        }
        if let tmpView = objc_getAssociatedObject(self, key) as? UIView {
            return tmpView
        } else {
           let tmpView = UIView(frame: self.bounds)
            self.addSubview(tmpView)
            tmpView.snp.makeConstraints({ (make) in
                make.top.left.bottom.right.equalTo(self)
            })
            
            tmpView.alpha = 0.0
            tmpView.layer.zPosition = CGFloat(MAXFLOAT)
            tmpView.backgroundColor = UWMaskViewColor
            objc_setAssociatedObject(self, key, tmpView, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return tmpView
        }
    }
    /// 显示遮罩层
    func showUWBackground() {
        
        self.UWReferenceCount += 1
        if self.UWReferenceCount > 1 {
            self.UWReferenceCount -= 1
            return
        }
        self.UWMaskView.isHidden = false
        
        if self == UWPopupSWindow.sharedInstance.attachView() {
            UWPopupSWindow.sharedInstance.isHidden = false
            UWPopupSWindow.sharedInstance.makeKeyAndVisible()
        } else if let aa = self as? UIWindow {
            self.isHidden = false
            aa.makeKeyAndVisible()
        } else {
            self.bringSubviewToFront(self.UWMaskView)
        }
        
        UIView.animate(withDuration: self.UWAnimationDuration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            
            self.UWMaskView.alpha = 1.0
            
        }) { (finished) in
            
        }
    }
    
    /// 隐藏遮罩层
    func hideUWBackground() {
        
        if self.UWReferenceCount > 1 {
            return
        }
        
        UIView.animate(withDuration: self.UWAnimationDuration, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
            
            self.UWMaskView.alpha = 0.0
            
        }) { (finished) in
            
            if self == UWPopupSWindow.sharedInstance.attachView() {
                UWPopupSWindow.sharedInstance.isHidden = true
            } else if self.isKind(of: UIWindow.self) {
                self.isHidden = true
            }
            
            self.UWReferenceCount -= 1
        }
    }
}
