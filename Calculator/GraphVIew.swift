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
    

    @IBInspectable
    var lineWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var axesColor: UIColor = UIColor.blueColor() { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var lineColor: UIColor = UIColor.redColor() { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var scaleFactor: CGFloat = 1 {didSet {setNeedsDisplay()}}

    @IBInspectable
    var minX:Double = -10
    @IBInspectable
    var maxX:Double = 10
    
    var minY:Double = -10
    var maxY:Double = 10
    
    var density: CGFloat=100 {
        didSet {
            (minY,maxY) = newYRange(density, origin: graphCenter)
            setNeedsDisplay()
        }
    }
    
    func newYRange(density: CGFloat, origin: CGPoint) -> (yMin:Double, yMax:Double) {
        return (Double(-origin.y/density), Double((bounds.maxY-origin.y)/density))
    }
    
    func newXRange(density: CGFloat, origin: CGPoint) -> (xMin:Double, xMax:Double) {
        return (Double(-origin.x/density), Double((bounds.maxX-origin.x)/density))
    }
    
    weak var dataSource: GraphViewDataSource?
    
    var Xrange: Double {
        return maxX - minX + 1
    }
    
    override func drawRect(rect: CGRect) {
        let axes = AxesDrawer(color: axesColor, contentScaleFactor: scaleFactor)
        density = bounds.width/CGFloat(Xrange)
        axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: density)
    
        plotFunction()
    }

    func plotFunction() {
        var prevValueUndefined = true
        //let startPt = CGPoint(x: 0, y: graphCenter.y)
        let curve = UIBezierPath()
        
        let delta = Double(1.0/density)

        for (var i:CGFloat=0,x:Double=minX;i<bounds.width;i=i+1,x=x+delta) {
            if let y = dataSource?.functionValue(self, atXEquals: x) {
                if !prevValueUndefined {
                    curve.addLineToPoint(XYToPoint(x,y,density: density, origin: graphCenter))
                } else {
                    curve.moveToPoint(XYToPoint(x,y,density: density, origin: graphCenter))
                }
                prevValueUndefined = false
            } else {
                prevValueUndefined = true
            }
        }
        curve.lineWidth=lineWidth
        lineColor.set()
        curve.stroke()
    }
    
    func XYToPoint(x: Double, _ y: Double, density: CGFloat, origin: CGPoint) -> CGPoint {
        var point = CGPoint()
        point.x = CGFloat(x)*density + origin.x
        point.y = CGFloat(y)*density + origin.y

        return point
    }
}
