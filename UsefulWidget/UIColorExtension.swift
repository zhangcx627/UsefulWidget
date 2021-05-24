//
//  UIColorExtension.swift
//  UsefulWidget
//
//  Created by chenxu on 2021/5/24.
//

import UIKit

extension UIColor {

    //Return dynamic cg color
    func cg(for trait: UITraitCollection) -> CGColor {
        if #available(iOS 13, *) {
            return resolvedColor(with: trait).cgColor
        } else {
            return self.cgColor
        }
    }
}
