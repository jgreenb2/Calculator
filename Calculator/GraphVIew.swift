//
//  GraphView.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func functionValue(sender: GraphView, atXEquals: Double) -> Double?
}

@IBDesignable
class GraphView: UIView {

    var graphCenter: CGPoint {
        return convertPoint(center, fromCoordinateSpace: superview!)
    }
    
    //@IBInspectable
    var density: CGFloat=100 { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var color: UIColor = UIColor.blueColor() { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var scaleFactor: CGFloat = 1 {didSet {setNeedsDisplay()}}

    @IBInspectable
    var minX:CGFloat = -10
    @IBInspectable
    var maxX:CGFloat = 10
    
    weak var dataSource: GraphViewDataSource?
    
    override func drawRect(rect: CGRect) {
        let axes = AxesDrawer(color: color, contentScaleFactor: scaleFactor)
        density = bounds.width/(maxX-minX+1)
        axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: density)
    }


}
