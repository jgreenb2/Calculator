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
    
    var graphOrigin:CGPoint? {
        didSet {
            if graphOrigin != nil {
                (minX,maxX) = newXRange(density.x, origin: graphCenter)
                (minY,maxY) = newYRange(density.y, origin: graphCenter)
                setNeedsDisplay()
            }
        }
    }
    
    var graphCenter: CGPoint {
        return graphOrigin ?? convertPoint(center, fromCoordinateSpace: superview!)
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
    @IBInspectable
    var minY:Double = -10
    @IBInspectable
    var maxY:Double = 10
    
    var density: (x: CGFloat, y: CGFloat) = (100,100) {
        didSet {
            (minX,maxX) = newXRange(density.x, origin: graphCenter)
            (minY,maxY) = newYRange(density.y, origin: graphCenter)
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
        density = (bounds.width/CGFloat(maxX-minX),bounds.height/CGFloat(maxY-minY))
        axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnitX: density.x, pointsPerUnitY: density.y)
    
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
        return CGFloat(x)*density.x + graphCenter.x
    }
    
    func ScreenToX(i: CGFloat) -> Double {
        return Double((i - graphCenter.x)/density.x)
    }
    
    func YToScreen(y: Double) -> CGFloat {
        return -CGFloat(y)*density.y + graphCenter.y
    }
    
    func moveOrigin(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let translation = gesture.translationInView(self)
            if graphOrigin == nil {
                graphOrigin = CGPoint(x:graphCenter.x + translation.x, y: graphCenter.y + translation.y)
            } else {
                graphOrigin!.x = graphOrigin!.x + translation.x
                graphOrigin!.y = graphOrigin!.y + translation.y
            }
            gesture.setTranslation(CGPointZero, inView: self)
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
            // if we don't have exactly 2 touchpoints we
            // don't know what's going on
            if gesture.numberOfTouches() == 2 {
                // get the touchpoints
                let touch1 = gesture.locationOfTouch(0, inView: self)
                let touch2 = gesture.locationOfTouch(1, inView: self)
                
                var densityX = density.x
                var densityY = density.y
                
                // compute the slope of the line
                let rise = Double(touch1.y - touch2.y)
                let run = Double(touch1.x - touch2.x)
                var theta = atan2(rise,run) * (180.0/M_PI)
                if theta > 90.0 {
                    theta -= 180.0
                } else if theta < -90.0 {
                    theta += 180.0
                }
                
                if theta > scaleZones.scaleXZoneMin && theta <= scaleZones.scaleXZoneMax {
                    densityX *= gesture.scale
                } else if theta > scaleZones.scaleXYZoneMin && theta <= scaleZones.scaleXYZoneMax {
                    densityX *= gesture.scale
                    densityY *= gesture.scale
                } else {
                    densityY *= gesture.scale
                }
                density = (densityX, densityY)

                gesture.scale=1
            }
        }
    }
    
    func jumpToOrigin(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            graphOrigin = gesture.locationInView(self)
        }
    }
}