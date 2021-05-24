//
//  EdoMenuView.swift
//  EdoPopupView
//
//  Created by xfg on 2018/5/19.
//  Copyright © 2018年 xfg. All rights reserved.
//  仿QQ、微信菜单

/** ************************************************
 
 github地址：https://github.com/choiceyou/FWPopupView
 bug反馈、交流群：670698309
 
 ***************************************************
 */


import Foundation
import UIKit
import SnapKit

let EdoPopupViewHideAllNotification = "EdoPopupViewHideAllNotification"
typealias ActionInfo = (title: String, icon: String, enabled: Bool, handler: (() -> ()))

class EdoMenuViewTableViewCell: UITableViewCell {
    
    var iconImgView: UIImageView
    var titleLabel: UILabel
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.iconImgView = UIImageView()
        self.titleLabel = UILabel()

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor.clear
        
        self.iconImgView.contentMode = .center
        self.iconImgView.backgroundColor = UIColor.clear
        self.contentView.addSubview(self.iconImgView)
        
        self.titleLabel.backgroundColor = UIColor.clear
        self.contentView.addSubview(self.titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupContent(title: String?, image: UIImage?, property: EdoMenuViewProperty, imgSize: CGSize = .zero) {
        
        self.selectionStyle = property.selectionStyle
        
        if let img = image {
            self.iconImgView.isHidden = false
            self.iconImgView.image = img
            self.iconImgView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(property.leftRigthMargin)
                make.centerY.equalToSuperview()
                make.size.equalTo(imgSize)
            }
        } else {
            self.iconImgView.isHidden = true
        }
        
        if let title = title {
            self.titleLabel.textAlignment = property.textAlignment
            let attributedString = NSAttributedString(string: title, attributes: property.titleTextAttributes)
            self.titleLabel.attributedText = attributedString
            self.titleLabel.snp.makeConstraints { (make) in
                if image != nil {
                    make.left.equalTo(self.iconImgView.snp.right).offset(property.commponentMargin)
                } else {
                    make.left.equalToSuperview().offset(property.leftRigthMargin)
                }
                make.right.equalToSuperview().offset(-property.leftRigthMargin)
                make.centerY.equalToSuperview()
            }
        }
    }
}

public typealias EdoPopupItemClickedBlock = (_ popupView: EdoMenuView, _ index: Int, _ title: String?) -> Void
/// 弹窗状态回调，注意：该回调会走N次
public typealias EdoPopupStateBlock = (_ popupView: EdoMenuView, _ popupViewState: EdoPopupViewState) -> Void
/// 弹窗显示、隐藏回调，内部回调，该回调不对外
public typealias EdoPopupShowBlock = (_ popupView: EdoMenuView) -> Void
/// 弹窗显示、隐藏回调，内部回调，该回调不对外
public typealias EdoPopupHideBlock = (_ popupView: EdoMenuView, _ hideWithRemove: Bool) -> Void
/// 弹窗已经显示回调
public typealias EdoPopupDidAppearBlock = (_ popupView: EdoMenuView) -> Void
/// 弹窗已经隐藏回调
public typealias EdoPopupDidDisappearBlock = (_ popupView: EdoMenuView) -> Void

open class EdoMenuView: UIView, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var actions: [ActionInfo]? {
        didSet {
            self.setNeedsLayout()
            self.setNeedsDisplay()
        }
    }
    
    /// 当前选中下标
    private var selectedIndex: Int = 0
    
    /// 最大的那一项的size
    private var maxItemSize: CGSize = CGSize.zero
    
    /// 保存点击回调
    private var popupItemClickedBlock: EdoPopupItemClickedBlock?
    
    /// 有箭头时：当前layer的mask
    private var maskLayer: CAShapeLayer?
    /// 有箭头时：当前layer的border
    private var borderLayer: CAShapeLayer?
    
    internal var finalSize = CGSize.zero
    
    private var popupStateBlock: EdoPopupStateBlock?
    /// 遮罩层为UIScrollView或其子类时，记录是否可以滚动
    internal var originScrollEnabled: Bool?
    /// 记录遮罩层设置前的颜色
    internal var originMaskViewColor: UIColor = .clear

    /// 记录弹窗弹起前keywindow
    internal var originKeyWindow: UIWindow?
    
    private var showAnimation: EdoPopupShowBlock?
    
    private var hideAnimation: EdoPopupHideBlock?
    
    private var popupDidAppearBlock: EdoPopupDidAppearBlock?
    private var popupDidDisappearBlock: EdoPopupDidDisappearBlock?
    /// 当前Constraints是否被设置过了
    private var haveSetConstraints: Bool = false
    
    private var tapGest: UITapGestureRecognizer?

    /// 是否重新设置了父视图
    private var isResetSuperView: Bool = false

    var popSWindow: EdoPopupSWindow
    
    var imgSize: CGSize = .zero
    /// 记录当前弹窗状态
    public var currentPopupViewState: EdoPopupViewState = .unKnow {
        willSet {
            if let popupStateBlock = self.popupStateBlock {
                popupStateBlock(self, newValue)
            }
        }
    }
    private lazy var tableView: UITableView = {
        
        let tableView = UITableView()
        tableView.register(EdoMenuViewTableViewCell.self, forCellReuseIdentifier: "cellId")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        self.addSubview(tableView)
        return tableView
    }()
    /// 1、当外部没有传入该参数时，默认为UIWindow的根控制器的视图，即表示弹窗放在EdoPopupSWindow上，此时若self.popSWindow.touchWildToHide = true表示弹窗视图外部可点击；2、当外部传入该参数时，该视图为传入的UIView，即表示弹窗放在传入的UIView上；
    @objc public var attachedView: UIView? {
        willSet {
            newValue?.edoMaskView.addSubview(self)
            if let new = newValue as? UIScrollView {
                self.originScrollEnabled = new.isScrollEnabled
            }
        }
    }
    @objc public var vProperty = EdoMenuViewProperty() {
        willSet {
            self.attachedView?.edoAnimationDuration = newValue.animationDuration
            if newValue.backgroundColor != nil {
                self.backgroundColor = newValue.backgroundColor
            }
        }
    }
    
    private func setupParams() {
        self.backgroundColor = .white
        
        self.originMaskViewColor = self.attachedView?.edoMaskViewColor ?? .clear
        self.attachedView?.edoMaskView.addSubview(self)
        self.isHidden = true
        
        self.showAnimation = self.customShowAnimation()
        self.hideAnimation = self.customHideAnimation()
        
        NotificationCenter.default.addObserver(self, selector: #selector(notifyHideAll(notification:)), name: NSNotification.Name(rawValue: EdoPopupViewHideAllNotification), object: nil)
    }
    /// 类初始化方法3
    ///
    /// - Parameters:
    ///   - itemTitles: 标题
    ///   - itemImageNames: 图片
    ///   - itemBlock: 点击回调
    ///   - property: 可设置参数
    /// - Returns: self
    class func menu(_ actions: [ActionInfo], itemBlock: EdoPopupItemClickedBlock? = nil, property: EdoMenuViewProperty?, imgSize: CGSize? = .zero) -> EdoMenuView {
        
        let popupMenu = EdoMenuView()
        popupMenu.setupUI(actions, itemBlock: itemBlock, property: property, imgSize: imgSize)
        return popupMenu
    }
    
    public override init(frame: CGRect) {
        self.popSWindow = EdoPopupSWindow(frame: UIScreen.main.bounds)
        self.popSWindow.backgroundColor = UIColor.clear
        self.attachedView = self.popSWindow.attachView()

        super.init(frame: frame)
        self.setupParams()
        self.vProperty = EdoMenuViewProperty()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 刷新当前视图及数据
    @objc open func refreshData() {
        self.setupFrame(property: self.vProperty)
        self.tableView.reloadData()
    }
}

extension EdoMenuView {
    
    private func setupUI(_ actions: [ActionInfo], itemBlock: EdoPopupItemClickedBlock? = nil, property: EdoMenuViewProperty?, imgSize: CGSize? = nil) {
        
        if actions.count == 0 {
            return
        }
        self.backgroundColor = .white

        if let property = property {
            self.vProperty = property
        } else {
            self.vProperty = EdoMenuViewProperty()
        }
        
        self.clipsToBounds = true
        self.actions = actions
        self.imgSize = imgSize ?? .zero
        
        self.popupItemClickedBlock = itemBlock
        let property = self.vProperty

        self.tableView.separatorInset = property.separatorInset
        self.tableView.layoutMargins = property.separatorInset
        self.tableView.separatorColor = property.separatorColor
        self.tableView.bounces = property.bounces
        
        self.maxItemSize = self.measureMaxSize()
        self.setupFrame(property: property)
        
        var tableViewY: CGFloat = 0
        if property.popupArrowStyle == .none {
            self.layer.cornerRadius = self.vProperty.cornerRadius
            self.layer.borderColor = self.vProperty.splitColor.cgColor
            self.layer.borderWidth = self.vProperty.splitWidth
        } else {
            tableViewY = property.popupArrowSize.height
        }
        
        // 用来隐藏多余的线条，不想自定义线条
        let footerViewHeight: CGFloat = 1
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: footerViewHeight))
        footerView.backgroundColor = UIColor.clear
        self.tableView.tableFooterView = footerView
        
        self.tableView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(tableViewY)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-((0) - footerViewHeight))
        }
    }
    
    private func setupFrame(property: EdoMenuViewProperty) {
        var tableViewY: CGFloat = 0
        switch property.popupArrowStyle {
        case .none:
            tableViewY = 0
            break
        case .round, .triangle:
            tableViewY = property.popupArrowSize.height
            break
        }
        
        var tmpMaxHeight: CGFloat = 0.0
        if let superView = self.superview {
            tmpMaxHeight = self.vProperty.popupViewMaxHeightRate * superView.frame.size.height
        } else {
            tmpMaxHeight = self.vProperty.popupViewMaxHeightRate * UIScreen.main.bounds.height
        }
        
        var selfSize: CGSize = CGSize.zero
        if property.popupViewSize.width > 0 && property.popupViewSize.height > 0 {
            selfSize = property.popupViewSize
        } else if self.vProperty.popupViewMaxHeightRate > 0 && self.maxItemSize.height * CGFloat(self.itemsCount()) > tmpMaxHeight {
            selfSize = CGSize(width: self.maxItemSize.width, height: tmpMaxHeight)
        } else {
            selfSize = CGSize(width: self.maxItemSize.width, height: self.maxItemSize.height * CGFloat(self.itemsCount()))
        }
        selfSize.height += tableViewY
        self.frame = CGRect(x: 0, y: tableViewY, width: selfSize.width, height: selfSize.height)
        self.finalSize = selfSize
        
        self.setupMaskLayer(property: property)
    }
    
    private func setupMaskLayer(property: EdoMenuViewProperty) {
        // 绘制箭头
        if property.popupArrowStyle != .none {
            if self.maskLayer != nil {
                self.layer.mask = nil
                self.maskLayer?.removeFromSuperlayer()
                self.maskLayer = nil
            }
            
            if self.borderLayer != nil {
                self.borderLayer?.removeFromSuperlayer()
                self.borderLayer = nil
            }
            
            // 圆角值
            let cornerRadius = property.cornerRadius
            /// 箭头的尺寸
            let arrowSize = property.popupArrowSize
            
            if property.popupArrowVertexScaleX > 1 {
                property.popupArrowVertexScaleX = 1
            } else if property.popupArrowVertexScaleX < 0 {
                property.popupArrowVertexScaleX = 0
            }
                        
            // 顶部Y值
            let maskTop = arrowSize.height
            // 底部Y值
            let maskBottom = self.frame.height
            
            // 开始画贝塞尔曲线
            let maskPath = UIBezierPath()
            
            // 左上圆角
            maskPath.move(to: CGPoint(x: 0, y: cornerRadius + maskTop))
            maskPath.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius + maskTop), radius: cornerRadius, startAngle: self.degreesToRadians(angle: 180), endAngle: self.degreesToRadians(angle: 270), clockwise: true)
            
            // 右上圆角
            maskPath.addLine(to: CGPoint(x: self.frame.width - cornerRadius, y: maskTop))
            maskPath.addArc(withCenter: CGPoint(x: self.frame.width - cornerRadius, y: maskTop + cornerRadius), radius: cornerRadius, startAngle: self.degreesToRadians(angle: 270), endAngle: self.degreesToRadians(angle: 0), clockwise: true)
            
            // 右下圆角
            maskPath.addLine(to: CGPoint(x: self.frame.width, y: maskBottom - cornerRadius))
            maskPath.addArc(withCenter: CGPoint(x: self.frame.width - cornerRadius, y: maskBottom - cornerRadius), radius: cornerRadius, startAngle: self.degreesToRadians(angle: 0), endAngle: self.degreesToRadians(angle: 90), clockwise: true)
            
            // 左下圆角
            maskPath.addLine(to: CGPoint(x: cornerRadius, y: maskBottom))
            maskPath.addArc(withCenter: CGPoint(x: cornerRadius, y: maskBottom - cornerRadius), radius: cornerRadius, startAngle: self.degreesToRadians(angle: 90), endAngle: self.degreesToRadians(angle: 180), clockwise: true)
            
            maskPath.close()
            
            // 截取圆角和箭头
            self.maskLayer = CAShapeLayer()
            self.maskLayer?.frame = self.bounds
            self.maskLayer?.path = maskPath.cgPath
            self.layer.mask = self.maskLayer
            
            // 边框
            let borderLayer = CAShapeLayer()
            borderLayer.frame = self.bounds
            borderLayer.path = maskPath.cgPath
            borderLayer.lineWidth = 1
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.strokeColor = property.splitColor.cgColor
            self.layer.addSublayer(borderLayer)
            self.borderLayer = borderLayer
        }
    }
}

extension EdoMenuView {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.itemsCount()
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.maxItemSize.height
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as? EdoMenuViewTableViewCell {
            var title: String?
            var image: UIImage?
            if let actions = self.actions {
                title = actions[indexPath.row].title
                image = UIImage(named: actions[indexPath.row].icon)
            }
            
            cell.setupContent(title: title, image: image, property: self.vProperty, imgSize: self.imgSize)
            return cell
        } else {
            let cell = EdoMenuViewTableViewCell(style: .default, reuseIdentifier: "cellId")
            var title: String?
            var image: UIImage?
            if let actions = self.actions {
                title = actions[indexPath.row].title
                image = UIImage(named: actions[indexPath.row].icon)
            }
            
            cell.setupContent(title: title, image: image, property: self.vProperty, imgSize: self.imgSize)
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.hide()
        
//        if let popupItemClickedBlock = self.popupItemClickedBlock {
            if let actions = self.actions {
                actions[indexPath.row].handler()
            }
//            popupItemClickedBlock(self, indexPath.row, title)
//        }
    }
    
    @objc open func notifyHideAll(notification: Notification) {
        
        if let anyclass = notification.object as? AnyClass, self.isKind(of: anyclass) {
            self.hide()
        }
    }
    
    func show() {
        
        if self.currentPopupViewState == .willAppear || self.currentPopupViewState == .didAppear || self.currentPopupViewState == .didAppearButCovered || self.currentPopupViewState == .didAppearAgain {
            return
        }
        self.currentPopupViewState = .willAppear
        
        // 弹起时设置相关参数，因为隐藏或者销毁时会被重置掉，所以每次弹起时都重新调用
        if self.attachedView != nil && self.vProperty.maskViewColor != nil {
            if let maskViewColor = self.vProperty.maskViewColor {
                self.attachedView?.edoMaskViewColor = maskViewColor
            }
        }
        for tmpWindow in UIApplication.shared.windows {
            if tmpWindow.isKeyWindow {
                self.originKeyWindow = tmpWindow
            }
        }
        self.attachedView?.edoAnimationDuration = self.vProperty.animationDuration
        
        if self.attachedView != nil && self.attachedView != self.popSWindow.attachView() {
            if let tap = tapGest {
                tap.isEnabled = true
            } else {
                let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesClick(tap:)))
                tap.delegate = self
                self.attachedView?.addGestureRecognizer(tap)
                tapGest = tap
            }
            if let attachedView = self.attachedView as? UIScrollView {
                attachedView.isScrollEnabled = false
            }
        }
        
        if self.attachedView == nil {
            self.attachedView = self.popSWindow.attachView()
        }
        
        self.attachedView?.showEdoBackground(self.popSWindow)
        
        if let showA = self.showAnimation {
            showA(self)
        }
    }

    /// 点击隐藏
    ///
    /// - Parameter tap: 手势
    @objc func tapGesClick(tap: UITapGestureRecognizer) {
        
        if !self.edoBackgroundAnimating, let attachedView = self.attachedView {
            for view: UIView in attachedView.edoMaskView.subviews {
                if let popupView = view as? EdoMenuView {
                    popupView.hide()
                }
            }
        }
    }
    func hide() {
        
        if self.currentPopupViewState == .willDisappear || self.currentPopupViewState == .didDisappear {
            return
        }
        self.currentPopupViewState = .willDisappear
        
        if self.attachedView == nil {
            self.attachedView = self.popSWindow.attachView()
        }
        
        self.attachedView?.edoAnimationDuration = self.vProperty.animationDuration
        
        for tmpView: UIView in self.popSWindow.hiddenViews {
            if tmpView == self {
                if let index = self.popSWindow.hiddenViews.firstIndex(of: tmpView) {
                    self.popSWindow.hiddenViews.remove(at: index)
                }
            }
        }
        
        if self.popSWindow.hiddenViews.isEmpty && self.popSWindow.willShowingViews.isEmpty && self.attachedView?.edoBackgroundAnimating == false {
            self.attachedView?.hideEdoBackground(self.popSWindow)
        }
        
        let hideAnimation = self.hideAnimation
        if hideAnimation != nil {
            hideAnimation!(self, true)
        }

        if self.tapGest != nil && self.attachedView != nil {
            self.tapGest?.isEnabled = false
        }
        
        // 还原弹窗弹起时的相关参数
        self.attachedView?.edoMaskViewColor = self.originMaskViewColor
        if let attachedView = self.attachedView as? UIScrollView, let originScrollEnabled = self.originScrollEnabled {
            attachedView.isScrollEnabled = originScrollEnabled
        }
        if let originWindow = self.originKeyWindow {
            originWindow.makeKey()
        }
    }

}

extension EdoMenuView {
    
    /// 计算控件的最大宽度、高度
    ///
    /// - Returns: CGSize
    fileprivate func measureMaxSize() -> CGSize {
        
        if self.actions == nil {
            return CGSize.zero
        }
        
        let property = self.vProperty
        var titleSize = CGSize.zero
        var totalMaxSize = CGSize.zero
        
        let titleAttrs = property.titleTextAttributes
        
        if let actions = self.actions {
            var tmpSize = CGSize.zero
            var index = 0
            for action in actions {
                titleSize = (action.title as NSString).size(withAttributes: titleAttrs)
                tmpSize = CGSize(width: titleSize.width + self.imgSize.width, height: titleSize.height + self.imgSize.height)
                
                totalMaxSize.width = max(totalMaxSize.width, tmpSize.width)
                totalMaxSize.height = max(totalMaxSize.height, tmpSize.height)
                
                index += 1
            }
        }
        
        totalMaxSize.width += property.leftRigthMargin * 2
        if self.actions?.count != 0{
            totalMaxSize.width += property.commponentMargin
        }
        
        
        var width = min(ceil(totalMaxSize.width), property.popupViewMaxWidth)
        width = max(width, property.popupViewMinWidth)
        totalMaxSize.width = width
        
        if imgSize.height > 0 {
            totalMaxSize.height = imgSize.height + property.topBottomMargin * 2
        } else {
            totalMaxSize.height += property.topBottomMargin * 2
            if property.popupViewItemHeight > 0 {
                totalMaxSize.height = property.popupViewItemHeight
            } else {
                totalMaxSize.height = ceil(totalMaxSize.height)
            }
        }
        return totalMaxSize
    }
    
    /// 计算总计行数
    ///
    /// - Returns: 行数
    fileprivate func itemsCount() -> Int {
        
        if let actions = self.actions {
            return actions.count
        } else {
            return 0
        }
    }
    
    /// 角度转换
    ///
    /// - Parameter angle: 传入的角度值
    /// - Returns: CGFloat
    fileprivate func degreesToRadians(angle: CGFloat) -> CGFloat {
        return angle * CGFloat(Double.pi) / 180
    }
}

// MARK: - 动画事件
extension EdoMenuView {
    
    /// 显示动画
    ///
    /// - Returns: EdoPopupShowBlock
    private func customShowAnimation() -> EdoPopupShowBlock {
        
        let popupBlock = { [weak self] (popupView: EdoMenuView) in
            
            guard let strongSelf = self, let attachedView = strongSelf.attachedView else {
                return
            }
            
            // 保证前一次弹窗销毁完毕
            var tmpHiddenViews: [UIView] = []
            for view in attachedView.edoMaskView.subviews {
                if let view = view as? EdoMenuView {
                    if view == strongSelf {
                        view.isHidden = false
                    } else if view.currentPopupViewState != .unKnow {
                        view.isHidden = true
                        view.currentPopupViewState = .didAppearButCovered
                        tmpHiddenViews.append(view)
                    }
                }
            }
            strongSelf.popSWindow.hiddenViews.removeAll()
            strongSelf.popSWindow.hiddenViews.append(contentsOf: tmpHiddenViews)
            
            if !strongSelf.haveSetConstraints || strongSelf.isResetSuperView == true {
                strongSelf.setupConstraints(constraintsState: .constraintsBeforeAnimation)
            }
            
            strongSelf.setupConstraints(constraintsState: .constraintsShownAnimation)
            
            strongSelf.attachedView?.edoBackgroundAnimating = true
            
            if strongSelf.vProperty.usingSpringWithDamping >= 0 && strongSelf.vProperty.usingSpringWithDamping <= 1 {
                UIView.animate(withDuration: strongSelf.vProperty.animationDuration, delay: 0.0, usingSpringWithDamping: strongSelf.vProperty.usingSpringWithDamping, initialSpringVelocity: strongSelf.vProperty.initialSpringVelocity, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    
                    strongSelf.showAnimationDuration()
                    
                }, completion: { (finished) in
                    
                    strongSelf.showAnimationFinished()
                    
                })
            } else {
                UIView.animate(withDuration: strongSelf.vProperty.animationDuration, delay: 0.0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    
                    strongSelf.showAnimationDuration()
                    
                }, completion: { (finished) in
                    
                    strongSelf.showAnimationFinished()
                    
                })
            }
        }
        
        return popupBlock
    }
    
    /// 显示动画的操作
    private func showAnimationDuration() {
        
        if self.vProperty.popupAnimationType == .position {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
        } else if self.vProperty.popupAnimationType == .frame {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
        }
    }
    
    /// 显示动画完成后的操作
    private func showAnimationFinished() {
        
        if let popupDidAppearBlock = self.popupDidAppearBlock {
            popupDidAppearBlock(self)
        }
        self.currentPopupViewState = .didAppear
        
        if self.popSWindow.willShowingViews.count > 0 {
            if let willShowingView: EdoMenuView = self.popSWindow.willShowingViews.first as? EdoMenuView {
                willShowingView.show()
                self.popSWindow.willShowingViews.removeFirst()
            }
        } else {
            self.attachedView?.edoBackgroundAnimating = false
        }
    }
    
    /// 隐藏动画
    ///
    /// - Returns: EdoPopupHideBlock
    private func customHideAnimation() -> EdoPopupHideBlock {
        
        let popupBlock: EdoPopupHideBlock = { [weak self] popupView, isRemove in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.setupConstraints(constraintsState: .constraintsHiddenAnimation)
            
            strongSelf.attachedView?.edoBackgroundAnimating = true
            
            UIView.animate(withDuration: strongSelf.vProperty.animationDuration, animations: {
                
                if strongSelf.vProperty.popupAnimationType == .position {
                    strongSelf.superview?.layoutIfNeeded()
                } else if strongSelf.vProperty.popupAnimationType == .frame {
                    strongSelf.superview?.layoutIfNeeded()
                    strongSelf.layoutIfNeeded()
                }
            }, completion: { (finished) in
                
                if isRemove == true {
                    strongSelf.removeFromSuperview()
                    if let index = strongSelf.popSWindow.hiddenViews.firstIndex(of: strongSelf) {
                        strongSelf.popSWindow.hiddenViews.remove(at: index)
                    }
                }
                strongSelf.isHidden = true
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.0001, execute: {
                    if strongSelf.popSWindow.willShowingViews.count > 0 {
                        if let willShowingView: EdoMenuView = strongSelf.popSWindow.willShowingViews.last as? EdoMenuView {
                            willShowingView.show()
                            strongSelf.popSWindow.willShowingViews.removeLast()
                        }
                    } else if !strongSelf.popSWindow.hiddenViews.isEmpty {
                        if let showView: EdoMenuView = strongSelf.popSWindow.hiddenViews.last as? EdoMenuView {
                            showView.isHidden = false
                            showView.currentPopupViewState = .didAppearAgain
                            strongSelf.popSWindow.hiddenViews.removeLast()
                        }
                    }
                    
                    strongSelf.currentPopupViewState = .didDisappear
                    if let popupDidDisappearBlock = strongSelf.popupDidDisappearBlock {
                        popupDidDisappearBlock(strongSelf)
                    }
                })
                
                strongSelf.attachedView?.edoBackgroundAnimating = false
                
            })
        }
        
        return popupBlock
    }
    
    /// 根据不同状态、动画设置视图的不同约束
    ///
    /// - Parameter constraintsState: EdoConstraintsState
    private func setupConstraints(constraintsState: EdoConstraintsState) {
        
        let myAlignment: EdoPopupCustomAlignment = self.vProperty.popupCustomAlignment
        let myPosition = self.vProperty.popupPositionAlignment
        
        self.snp.updateConstraints { (make) in
            if myPosition.minY + self.finalSize.height > UIScreen.main.bounds.height - 50 {
                make.bottom.equalToSuperview().offset(20)
                make.top.equalToSuperview().inset(UIScreen.main.bounds.height - 20)
            } else {
                make.top.equalToSuperview().offset(myPosition.minY)
                make.bottom.equalToSuperview().inset(UIScreen.main.bounds.height - myPosition.minY)
            }
        }
        return
        if (self.superview == nil) {
            return
        }
        
        if constraintsState == .constraintsBeforeAnimation {
            self.layoutIfNeeded()
            if self.finalSize.equalTo(CGSize.zero) {
                self.finalSize = self.frame.size
            }
            self.haveSetConstraints = true
            
            if self.vProperty.popupAnimationType == .position {
                if self.isResetSuperView == true {
                    self.isResetSuperView = false
                    self.snp.remakeConstraints { (make) in
                        make.width.equalTo(self.finalSize.width)
                        self.constraintsBeforeAnimationPosition(make: make, myAlignment: myAlignment, myPosition: myPosition)
                    }
                } else {
                    self.snp.makeConstraints { (make) in
                        make.width.equalTo(self.finalSize.width)
                        self.constraintsBeforeAnimationPosition(make: make, myAlignment: myAlignment, myPosition: myPosition)
                    }
                }
                self.superview?.layoutIfNeeded()
            } else if self.vProperty.popupAnimationType == .frame {
                if self.isResetSuperView == true {
                    self.isResetSuperView = false
                    self.snp.remakeConstraints { (make) in
                        self.constraintsBeforeAnimationFrame(make: make, myAlignment: myAlignment, myPosition: myPosition)
                    }
                } else {
                    self.snp.makeConstraints { (make) in
                        self.constraintsBeforeAnimationFrame(make: make, myAlignment: myAlignment, myPosition: myPosition)
                    }
                }
                self.superview?.layoutIfNeeded()
            }
        } else if constraintsState == .constraintsShownAnimation {
            self.snp.updateConstraints { (make) in
                if self.vProperty.popupAnimationType == .position {
                    if myPosition.minY + self.finalSize.height > UIScreen.main.bounds.height - 50 {
                        make.bottom.equalToSuperview().inset(20)
                        make.top.equalToSuperview().inset(UIScreen.main.bounds.height - 20 - self.finalSize.height)
                    } else {
                        make.top.equalToSuperview().offset(myPosition.minY)
                        make.bottom.equalToSuperview().inset(UIScreen.main.bounds.height - myPosition.minY - self.finalSize.height)
                    }
                } else if self.vProperty.popupAnimationType == .frame {
                    if myAlignment == .left {
                        make.height.equalTo(self.finalSize.height)
                        make.width.equalTo(self.finalSize.width)
                    } else if myAlignment == .right {
                        make.height.equalTo(self.finalSize.height)
                        make.width.equalTo(self.finalSize.width)
                    }
                }
            }
        } else if constraintsState == .constraintsHiddenAnimation {
            self.snp.updateConstraints { (make) in
                if self.vProperty.popupAnimationType == .position {
                    if myPosition.minY + self.finalSize.height > UIScreen.main.bounds.height - 50 {
                        make.bottom.equalToSuperview().offset(20)
                        make.top.equalToSuperview().inset(UIScreen.main.bounds.height - 20)
                    } else {
                        make.top.equalToSuperview().offset(myPosition.minY)
                        make.bottom.equalToSuperview().inset(UIScreen.main.bounds.height - myPosition.minY)
                    }
                } else if self.vProperty.popupAnimationType == .frame {
                    if myAlignment == .left {
                        make.height.equalTo(0)
                        make.width.equalTo(0)
                    } else if myAlignment == .right {
                        make.height.equalTo(0)
                        make.width.equalTo(0)
                    }
                }
            }
        }
    }
    
    /// 位移动画展示前的约束
    ///
    /// - Parameters:
    ///   - make: ConstraintMaker
    ///   - myAlignment: 自定义弹窗校准位置
    private func constraintsBeforeAnimationPosition(make: ConstraintMaker, myAlignment: EdoPopupCustomAlignment, myPosition: CGRect) {
        
        let edgeInsets = self.vProperty.popupViewEdgeInsets
        if myPosition.minY + self.finalSize.height > UIScreen.main.bounds.height - 50 {
            make.bottom.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(UIScreen.main.bounds.height - 20)
        } else {
            make.top.equalToSuperview().offset(myPosition.minY)
            make.bottom.equalToSuperview().inset(UIScreen.main.bounds.height - myPosition.minY)
        }
        if myAlignment == .left {
            make.left.equalToSuperview().offset(myPosition.origin.x + edgeInsets.left - edgeInsets.right)
            
        } else if myAlignment == .right {
            make.right.equalToSuperview().offset(-(UIScreen.main.bounds.width - myPosition.maxX + edgeInsets.left - edgeInsets.right))
        }
    }
    
    /// 修改frame值动画展示前的约束
    ///
    /// - Parameters:
    ///   - make: ConstraintMaker
    ///   - myAlignment: 自定义弹窗校准位置
    private func constraintsBeforeAnimationFrame(make: ConstraintMaker, myAlignment: EdoPopupCustomAlignment, myPosition: CGRect) {
        
        let edgeInsets = self.vProperty.popupViewEdgeInsets
        if myPosition.minY + self.finalSize.height > UIScreen.main.bounds.height - 50 {
            make.bottom.equalToSuperview().inset(20)
        } else {
            make.top.equalToSuperview().offset(myPosition.minY)
        }
        if myAlignment == .left {
            make.left.equalToSuperview().offset(myPosition.origin.x + edgeInsets.left - edgeInsets.right)
            
        } else if myAlignment == .right {
            make.right.equalToSuperview().offset(UIScreen.main.bounds.width - myPosition.maxX + edgeInsets.left - edgeInsets.right)
        }
        make.width.equalTo(self.finalSize.width)
        make.height.equalTo(0)
    }
}

/// EdoMenuView的相关属性，请注意其父类中还有很多公共属性
open class EdoMenuViewProperty: NSObject {
    
    /// 弹窗大小，如果没有设置，将按照统一的计算方式
    @objc public var popupViewSize = CGSize.zero
    /// 指定行高优先级 > 自动计算的优先级
    @objc public var popupViewItemHeight: CGFloat = 0
    
    /// 未选中时按钮字体属性
    @objc public var titleTextAttributes: [NSAttributedString.Key: Any] = [:]
    /// 文字位置
    @objc public var textAlignment : NSTextAlignment = .left
    
    /// 内容位置
    @objc public var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment = .left
    /// 选中风格
    @objc public var selectionStyle: UITableViewCell.SelectionStyle = .none
    
    /// 分割线颜色
    @objc public var separatorColor: UIColor = kPV_RGBA(r: 231, g: 231, b: 231, a: 1)
    /// 分割线偏移量
    @objc public var separatorInset: UIEdgeInsets = UIEdgeInsets.zero
    
    /// 是否开启tableview回弹效果
    @objc public var bounces: Bool = false
    
    /// 弹窗的最大宽度
    @objc open var popupViewMaxWidth: CGFloat  = UIScreen.main.bounds.width * 0.6
    /// 弹窗的最小宽度
    @objc open var popupViewMinWidth: CGFloat  = 20
    
    /// 标题字体大小
    @objc open var titleFontSize: CGFloat = 18.0
    /// 标题字体，设置该值后titleFontSize无效
    @objc open var titleFont: UIFont?
    /// 标题文字颜色
    @objc open var titleColor: UIColor = kPV_RGBA(r: 51, g: 51, b: 51, a: 1)
    
    /// 按钮字体大小
    @objc open var buttonFontSize: CGFloat = 17.0
    /// 按钮字体，设置该值后buttonFontSize无效
    @objc open var buttonFont: UIFont?
    /// 按钮高度
    @objc open var buttonHeight: CGFloat = 48.0
    /// 普通按钮文字颜色
    @objc open var itemNormalColor: UIColor = kPV_RGBA(r: 51, g: 51, b: 51, a: 1)
    /// 高亮按钮文字颜色
    @objc open var itemHighlightColor: UIColor = kPV_RGBA(r: 254, g: 226, b: 4, a: 1)
    /// 选中按钮文字颜色
    @objc open var itemPressedColor: UIColor = kPV_RGBA(r: 240, g: 240, b: 240, a: 1)
    
    /// 单个控件中的文字（图片）等与该控件上（下）之前的距离。注意：这个距离指的是单个控件内部哦，不是控件与控件之间
    @objc open var topBottomMargin:CGFloat = 12
    /// 单个控件中的文字（图片）等与该控件左（右）之前的距离。注意：这个距离指的是单个控件内部哦，不是控件与控件之间
    @objc open var leftRigthMargin:CGFloat = 16
    /// 控件之间的间距
    @objc open var commponentMargin:CGFloat = 16
    
    /// 边框颜色（部分控件分割线也用这个颜色）
    @objc open var splitColor: UIColor = kPV_RGBA(r: 231, g: 231, b: 231, a: 1)
    /// 分割线、边框的宽度
    @objc open var splitWidth: CGFloat = (1/UIScreen.main.scale)
    /// 圆角值
    @objc open var cornerRadius: CGFloat = 5.0
    
    /// 弹窗的背景色（注意：这边指的是弹窗而不是遮罩层，遮罩层背景色的设置是：edoMaskViewColor）
    @objc open var backgroundColor: UIColor?
    /// 弹窗的背景渐变色：当未设置backgroundColor时该值才有效
    @objc open var backgroundLayerColors: [UIColor]?
    /// 弹窗的背景渐变色相关属性：当设置了backgroundLayerColors时该值才有效
    @objc open var backgroundLayerStartPoint: CGPoint = CGPoint(x: 0.0, y: 0.0)
    /// 弹窗的背景渐变色相关属性：当设置了backgroundLayerColors时该值才有效
    @objc open var backgroundLayerEndPoint: CGPoint = CGPoint(x: 1.0, y: 0.0)
    /// 弹窗的背景渐变色相关属性：当设置了backgroundLayerColors时该值才有效
    @objc open var backgroundLayerLocations: [NSNumber] = [0, 1]
    
    /// 弹窗的最大高度占遮罩层高度的比例，0：表示不限制
    @objc open var popupViewMaxHeightRate: CGFloat = 0.6
    
    /// 弹窗箭头的样式
    @objc open var popupArrowStyle = EdoMenuArrowStyle.none
    /// 弹窗箭头的尺寸
    @objc open var popupArrowSize = CGSize(width: 28, height: 12)
    /// 弹窗箭头的顶点的X值相对于弹窗的宽度，默认在弹窗X轴的一半，因此设置范围：0~1
    @objc open var popupArrowVertexScaleX: CGFloat = 0.5
    /// 弹窗圆角箭头的圆角值
    @objc open var popupArrowCornerRadius: CGFloat = 2.5
    /// 弹窗圆角箭头与边线交汇处的圆角值
    @objc open var popupArrowBottomCornerRadius: CGFloat = 4.0
    
    
    // ===== 自定义弹窗（继承EdoPopupView）时可能会用到 =====
    
    /// 弹窗校准位置
    @objc open var popupPositionAlignment: CGRect = CGRect.zero
    /// defult from left
    @objc open var popupCustomAlignment: EdoPopupCustomAlignment = .right
    /// 弹窗动画类型
    @objc open var popupAnimationType: EdoPopupAnimationType = .position
    
    /// 弹窗偏移量
    @objc open var popupViewEdgeInsets = UIEdgeInsets.zero
    /// 遮罩层的背景色（也可以使用edoMaskViewColor），注意：该参数在弹窗隐藏后，还原为弹窗弹起时的值
    @objc open var maskViewColor: UIColor?
    
    /// 显示、隐藏动画所需的时间
    @objc open var animationDuration: TimeInterval = 0.2
    /// 阻尼系数，范围：0.0f~1.0f，数值越小「弹簧」的振动效果越明显。默认：-1，表示没有「弹簧」效果
    @objc open var usingSpringWithDamping: CGFloat = -1
    /// 初始速率，数值越大一开始移动越快，默认为：5
    @objc open var initialSpringVelocity: CGFloat = 5
    
    /// 3D放射动画（当且仅当：popupAnimationType == .scale3D 时有效）
    @objc open var transform3D: CATransform3D = CATransform3DMakeScale(1.2, 1.2, 1.0)
    /// 2D放射动画
    @objc open var transform: CGAffineTransform                     = CGAffineTransform(scaleX: 0.001, y: 0.001)
    
    
    public override init() {
        super.init()
        
        self.reSetParams()
    }

    public func reSetParams() {
        
        self.titleTextAttributes = [NSAttributedString.Key.foregroundColor: self.itemNormalColor, NSAttributedString.Key.backgroundColor: UIColor.clear, NSAttributedString.Key.font: UIFont.systemFont(ofSize: self.buttonFontSize)]
        
        self.leftRigthMargin = 16
        
        self.popupViewMaxHeightRate = 0.7
    }
}

/// 当前约束的状态
///
/// - beforeAnimation: 动画之前的约束
/// - showAnimation: 显示动画的约束
/// - hideAnimation: 隐藏动画的约束
private enum EdoConstraintsState: Int {
    case constraintsBeforeAnimation
    case constraintsShownAnimation
    case constraintsHiddenAnimation
}

/// 弹窗状态
///
/// - unKnow: 不知
/// - willAppear: 将要显示
/// - didAppear: 已经显示
/// - willDisappear: 将要隐藏
/// - didDisappear: 已经隐藏
/// - didAppearButCovered: 已经显示，但是被其他弹窗遮盖住了（实际上当前状态下弹窗是不可见）
/// - didAppearAgain: 已经显示，其上面遮盖的弹窗消失了（实际上当前状态与EdoPopupStateDidAppear状态相同）
@objc public enum EdoPopupViewState: Int {
    case unKnow
    case willAppear
    case didAppear
    case willDisappear
    case didDisappear
    case didAppearButCovered
    case didAppearAgain
}
/// 自定义弹窗校准位置，注意：这边设置靠置哪边动画就从哪边出来
///
/// - center: 中间，默认值
/// - topCenter: 上中
/// - leftCenter: 左中
/// - bottomCenter: 下中
/// - rightCenter: 右中
/// - topLeft: 上左
/// - topRight: 上右
/// - bottomLeft: 下左
/// - bottomRight: 下右
@objc public enum EdoPopupCustomAlignment: Int {
    case left
    case right
}
/// 自定义弹窗动画类型
///
/// - position: 位移动画，视图靠边的时候建议使用
/// - scale: 缩放动画
/// - scale3D: 3D缩放动画（注意：这边隐藏时用的还是scale动画）
/// - frame: 修改frame值的动画，视图未靠边的时候建议使用
@objc public enum EdoPopupAnimationType: Int {
    case position
    case frame
}

/// 弹窗箭头的样式
///
/// - none: 无箭头
/// - round: 圆角
/// - triangle: 菱角
@objc public enum EdoMenuArrowStyle: Int {
    case none
    case round
    case triangle
}

let edoReferenceCountKey: UnsafeRawPointer? = UnsafeRawPointer.init(bitPattern: "edoReferenceCountKey".hashValue)

let edoBackgroundViewKey: UnsafeRawPointer? = UnsafeRawPointer.init(bitPattern: "edoBackgroundViewKey".hashValue)
let edoBackgroundViewColorKey: UnsafeRawPointer? = UnsafeRawPointer.init(bitPattern: "edoBackgroundViewColorKey".hashValue)
let edoBackgroundAnimatingKey: UnsafeRawPointer? = UnsafeRawPointer.init(bitPattern: "edoBackgroundAnimatingKey".hashValue)
let edoAnimationDurationKey: UnsafeRawPointer? = UnsafeRawPointer.init(bitPattern: "edoAnimationDurationKey".hashValue)

/// 遮罩层的默认背景色
let kDefaultMaskViewColor = UIColor(white: 0, alpha: 0.5)

