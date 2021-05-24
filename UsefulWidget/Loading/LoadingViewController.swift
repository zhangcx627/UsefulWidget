//
//  LoadingViewController.swift
//  UsefulWidget
//
//  Created by chenxu on 2021/5/24.
//  https://github.com/ninjaprox/NVActivityIndicatorView.git
//  You can add some other loading from this repository

import UIKit

class LoadingViewController: UIViewController {
    var headImage = CircleStrokeSpinActivityIndicatorView(imageName: "right_menu_sendvideo", frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    var btn = UIButton()
    var isLoading: Bool = false

    init() {
        super.init(nibName: nil, bundle: nil)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func setupUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(self.headImage)
        self.headImage.isUserInteractionEnabled = true
        self.headImage.snp.makeConstraints { (make) in
            make.width.height.equalTo(41)
            make.centerX.centerY.equalToSuperview()
//            make.bottom.equalToSuperview().inset(16)
        }

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

    func startLoading() {
        if !self.isLoading {
            headImage.setUpAnimation(size: CGSize(width: 40, height: 40), color: UIColor.red)
            self.isLoading = true
        }
    }
    
    func stopLoading() {
        if self.isLoading {
            headImage.stopAnimating()
            self.isLoading = false
        }
    }
    
    
    @objc func btnAction(_ sender: Any) {
        if self.isLoading {
            self.stopLoading()
        } else {
            self.startLoading()
        }
    }
}
