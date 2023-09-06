//
//  Extensions.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 23.08.2023.
//

import Foundation
import UIKit
import SDWebImage

extension UIView {
    public var width: CGFloat {
        return self.frame.size.width
    }
    
    public var height: CGFloat {
        return self.frame.size.height
    }
    
    public var top: CGFloat {
        return self.frame.origin.y
    }
    
    public var bottom: CGFloat {
        return self.frame.size.height + self.frame.origin.y
    }
    
    public var left: CGFloat {
        return self.frame.origin.x
    }
    
    public var right: CGFloat {
        return self.frame.size.width + self.frame.origin.x
    }
    
    func addSubViews(_ view: UIView...) {
        view.forEach({
            addSubview($0)
        })
    }
}

extension Notification.Name {
    static let didLoginNotification = Notification.Name("didLoginNotification")
}

extension UIImageView {
    func downloadImage(url: URL) {
        self.sd_setImage(with: url, completed: nil)
    }
}

extension Date {
    public static let dateFormaterMessage: DateFormatter = {
        let formater = DateFormatter()
        formater.dateStyle = .medium
        formater.timeStyle = .long
        formater.locale = .current
        return formater
    }()
}


extension Int {
    public static func roundToNearestEvenInteger(_ number: Double) -> Double {
        let roundedNumber = round(number)
        if roundedNumber.truncatingRemainder(dividingBy: 2) == 0 {
            return roundedNumber
        } else {
            return roundedNumber + 1
        }
    }
}

