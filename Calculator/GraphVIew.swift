//
//  GraphVIew.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

@IBDesignable
class GraphVIew: UIView {

    var graphCenter: CGPoint {
        return convertPoint(center, fromCoordinateSpace: superview!)
    }
    
    @IBInspectable
    var density: CGFloat = 40 { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var color: UIColor = UIColor.blueColor() { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var scaleFactor: CGFloat = 1 {didSet {setNeedsDisplay()}}

    
    override func drawRect(rect: CGRect) {
        let axes = AxesDrawer(color: color, contentScaleFactor: scaleFactor)
        axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: density)
    }


}
