//
//  Helpers.swift
//  UsefulWidget
//
//  Created by chenxu on 2021/9/3.
//

import UIKit

class Helpers: NSObject {
    //compare version
    private static func compareVersion(_ version1: String, version2: String) -> ComparisonResult {
        //No matter which version number is empty, Don't compared
        if version1.isEmpty || version2.isEmpty {
            return ComparisonResult.orderedSame
        }
        var ver1Arr = version1.split(separator: ".")
        var ver2Arr = version2.split(separator: ".")
        while ver1Arr.count < ver2Arr.count {
            ver1Arr.append("0")
        }
        while ver1Arr.count > ver2Arr.count {
            ver2Arr.append("0")
        }
        for i in 0..<ver1Arr.count {
            guard let num1 = Int(ver1Arr[i]), let num2 = Int(ver2Arr[i]) else {
                return ComparisonResult.orderedSame
            }
            if num1 == num2 { continue }
            if num1 > num2 {
                return ComparisonResult.orderedDescending
            } else {
                return ComparisonResult.orderedAscending
            }
        }
        return ComparisonResult.orderedSame
    }

}
