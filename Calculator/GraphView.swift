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
    
    var graphOrigin:CGPoint? = nil {
        didSet {
            (minX,maxX) = newXRange(density, origin: graphCenter)
            setNeedsDisplay()
        }
    }
    var graphCenter: CGPoint {
        if let newOrigin = graphOrigin {
            return newOrigin
        } else {
            return convertPoint(center, fromCoordinateSpace: superview!)
        }
    }

    @IBInspectable
    var lineWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var axesColor: UIColor = UIColor.blueColor() { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var lineColor: UIColor = UIColor.redColor() { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var minX:Double = -10
    @IBInspectable
    var maxX:Double = 10
    
    var density: CGFloat=100 {
        didSet {
            (minX,maxX) = newXRange(density, origin: graphCenter)
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

    override func drawRect(rect: CGRect) {
        let axes = AxesDrawer(color: axesColor, contentScaleFactor: contentScaleFactor)
        density = bounds.width/CGFloat(maxX-minX)
        axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: density)
    
        plotFunction()
    }

    func plotFunction() {
        var prevValueUndefined = true
        let curve = UIBezierPath()
        for (var i:CGFloat=0;i<bounds.width;i=i+1/contentScaleFactor) {
            var x = ScreenToX(i)
            if let y = dataSource?.functionValue(self, atXEquals: x) {
                if !prevValueUndefined {
                    curve.addLineToPoint(XYToPoint(x,y))
                } else {
                    curve.moveToPoint(XYToPoint(x,y))
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
    
    func XYToPoint(x: Double, _ y: Double) -> CGPoint {
        var point = CGPoint()
        point.x = XToScreen(x)
        point.y = YToScreen(y)

        return point
    }
    
    func XToScreen(x: Double) -> CGFloat {
        return CGFloat(x)*density + graphCenter.x
    }
    
    func ScreenToX(i: CGFloat) -> Double {
        return Double((i - graphCenter.x)/density)
    }
    
    func YToScreen(y: Double) -> CGFloat {
        return -CGFloat(y)*density + graphCenter.y
    }
    
    func moveOrigin(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let translation = gesture.translationInView(self)
            if graphOrigin != nil {
                graphOrigin!.x = graphOrigin!.x + translation.x
                graphOrigin!.y = graphOrigin!.y + translation.y
            } else {
                let newOrigin = CGPoint(x:graphCenter.x + translation.x, y: graphCenter.y + translation.y)
                graphOrigin = newOrigin
            }
            gesture.setTranslation(CGPointZero, inView: self)
            setNeedsDisplay()
        default:
            break
        }
    }
    
    private struct scaleZones {
        static let scaleXYZoneMin = -67.5
        static let scaleXYZoneMax = 67.5
        static let scaleXZoneMin = -22.5
        static let scaleXZoneMax = 22.5
    }
    func scaleGraph(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Changed {
//            // get the first (hopefully only!) touchpoints
//            let touch1 = gesture.locationOfTouch(0, inView: self)
//            let touch2 = gesture.locationOfTouch(1, inView: self)
//            
//            // compute the slope of the line
//            let rise = Double(touch1.y - touch2.y)
//            let run = Double(touch1.x - touch2.x)
//            var theta = atan2(rise,run) * (180.0/M_PI)
//            if theta > 90.0 {
//                theta -= 180.0
//            } else if theta < -90.0 {
//                theta += 180.0
//            }
//            
//            if theta > scaleZones.scaleXZoneMin && theta <= scaleZones.scaleXZoneMax {
//                println("X scaling")
//            } else if theta > scaleZones.scaleXYZoneMin && theta <= scaleZones.scaleXYZoneMax {
//                println("Uniform scaling")
//            } else {
//                println("Y scaling")
//            }
            density *= gesture.scale
            gesture.scale=1
        }
    }
    
    func jumpToOrigin(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            graphOrigin = gesture.locationInView(self)
        }
    }
}
