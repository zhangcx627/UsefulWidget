//
//  DragDotTableViewCell.swift
//  UsefulWidget
//
//  Created by chenxu on 2021/5/24.
//

import UIKit

class DragDotTableViewCell: UITableViewCell, AZMetaBallCanvasDelegate {
    var metaBallCanvas: AZMetaBallCanvas?
    let indicatorView = IndicatorView(frame: CGRect.zero)
    private let dragAreaView = UIButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.indicatorView.backgroundColor = UIColor.clear
        self.indicatorView.indicatorColor = UIColor.blue
//        self.indicatorView.innerColor = UIColor.blue
        self.indicatorView.translatesAutoresizingMaskIntoConstraints = false

        self.dragAreaView.backgroundColor = UIColor.clear
        self.dragAreaView.translatesAutoresizingMaskIntoConstraints = false

        let drag:UIPanGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(drag(_:)))
        self.dragAreaView.addGestureRecognizer(drag)
        self.dragAreaView.alpha = 1.0

        self.dragAreaView.addTarget(self, action: #selector(clickedOnDot), for: .touchUpInside)
        self.contentView.addSubview(self.indicatorView)
        self.contentView.addSubview(self.dragAreaView)

        self.indicatorView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(50)
            make.size.equalTo(14)
        }
        self.dragAreaView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(45)
            make.size.equalTo(19)
        }
    }
    
    @objc func clickedOnDot() {
        print("++++clicked on dot")
    }

    @objc func drag(_ recognizer:UIPanGestureRecognizer)  {
        if self.metaBallCanvas == nil {
            if recognizer.state == .began {
                self.metaBallCanvas = AZMetaBallCanvas(azMetaBallItem: self.indicatorView)
                self.metaBallCanvas?.delegate = self
            }
        }

        self.metaBallCanvas?.dragAnimation(self.indicatorView, recognizer:recognizer)
        self.setNeedsDisplay()
    }

    func resetMetaBallCanvas() {
        self.metaBallCanvas?.reset()
    }
    //Mark: - AZMetaBallCanvasDelegate
    func deinitMetaBallCanvas() {
        self.metaBallCanvas = nil
    }

    func metaBallCanvasEnded() {
        print("+++++ drag finish")
    }

}
