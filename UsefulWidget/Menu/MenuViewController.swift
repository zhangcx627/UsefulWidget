//
//  MenuViewController.swift
//  UsefulWidget
//
//  Created by chenxu on 2021/5/21.
//  https://github.com/choiceyou/FWPopupView.git

import UIKit

class MenuViewController: UIViewController {
    var btn = UIButton()
    let titles = ["创建群聊", "加好友/群", "扫一扫", "面对面快传", "付款", "拍摄"]
    let images = ["right_menu_multichat",
                  "right_menu_addFri",
                  "right_menu_QR",
                  "right_menu_facetoface",
                  "right_menu_payMoney",
                  "right_menu_sendvideo"]
    let images1 = [UIImage(named: "right_menu_multichat"),
                  UIImage(named: "right_menu_addFri"),
                  UIImage(named: "right_menu_QR"),
                  UIImage(named: "right_menu_facetoface"),
                  UIImage(named: "right_menu_payMoney"),
                  UIImage(named: "right_menu_sendvideo")]


    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        btn = UIButton(frame: .zero)
        btn.setTitle("title", for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        btn.backgroundColor = UIColor.lightGray
        btn.addTarget(self, action: #selector(btnAction(_:)), for: .touchUpInside)
        self.view.addSubview(btn)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(150)
            make.right.equalToSuperview().inset(70)
            make.width.height.equalTo(50)
        }
    }
    
    @objc func btnAction(_ sender: Any) {        
        let property = UWMenuViewProperty()
        property.popupPositionAlignment = btn.frame
        property.popupAnimationType = .position
        property.popupCustomAlignment = .right
        property.maskViewColor = UIColor(white: 0, alpha: 0.4)
        
        property.popupViewEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        property.topBottomMargin = 0
        property.animationDuration = 0.3
        property.popupArrowStyle = .none
        property.cornerRadius = 5
        property.splitColor = UIColor.clear
        property.separatorColor = UIColor.init(white: 1, alpha: 0.3)
        property.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.backgroundColor: UIColor.clear, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)]
        property.textAlignment = .left
        property.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        
        var listActions: [UWActionInfo] = []
        for idx in 0...5 {
            let title = titles[idx]
            let img = images[idx]
            listActions.append((title: title, icon: img, enabled: true, handler: {
                print("++++++\(title)")
            }))
        }
        let menuView = UWMenuView.menu(listActions, itemBlock: { (popupView, index, title) in
            print("Menu：点击了第\(index)个按钮, tilte:\(title)")
        }, property: property, imgSize: CGSize(width: 32, height: 32))
        menuView.show()

    }
}
