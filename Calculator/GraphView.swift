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
    
    // the intersection of the x & y axes expressed in screen coordinates
    // optional because it will be nil when a new GraphView is created
    //
    // used indirectly by graphCenter. This value is set directly when
    // moving the origin through dragging or tapping
    var graphOrigin:CGPoint? {
        didSet {
            if graphOrigin != nil {
                (minX,maxX) = newXRange(density.x, origin: graphCenter)
                (minY,maxY) = newYRange(density.y, origin: graphCenter)
                setNeedsDisplay()
             }
        }
    }
    
    // a computed version of the origin that returns the default center position
    // OR the graphOrigin if it's been set. Whenever anyone wants to know what
    // the current origin is, this is what you pass them
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
    
    var touchCenter:CGPoint = CGPoint(x: 0, y: 0)
    let radius:CGFloat = 10

    var simplePlot:Bool = false
    
    var density: (x: CGFloat, y: CGFloat) = (25,25) {
        didSet {
            (minX,maxX) = newXRange(density.x, origin: graphCenter)
            (minY,maxY) = newYRange(density.y, origin: graphCenter)
            //setNeedsDisplay()
        }
    }
    
    func newYRange(density: CGFloat, origin: CGPoint) -> (yMin:Double, yMax:Double) {
        return (Double(-origin.y/density), Double((bounds.maxY-origin.y)/density))
    }
    
    func newXRange(density: CGFloat, origin: CGPoint) -> (xMin:Double, xMax:Double) {
        return (Double(-origin.x/density), Double((bounds.maxX-origin.x)/density))
    }
    

    override func drawRect(rect: CGRect) {
        let dot = UIBezierPath(ovalInRect: (CGRectMake ((touchCenter.x - radius/2), (touchCenter.y 
            - radius/2)
            , radius, radius)));
        UIColor.greenColor().setFill()
        dot.fill()

        let axes = AxesDrawer(color: axesColor, contentScaleFactor: contentScaleFactor)
        //density = (bounds.width/CGFloat(maxX-minX),bounds.height/CGFloat(maxY-minY))
        if simplePlot {
            axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: density, drawHashMarks: false)
            plotFunction(rect,simple: true)
        } else {
            axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: density, drawHashMarks: true)
            plotFunction(rect,simple: false)
        }
    }
    
    // plot the function using the appropriate protocol
    // We are careful NOT to draw lines to or from 
    // undefined points
    weak var dataSource: GraphViewDataSource?

    func plotFunction(rect: CGRect, simple:Bool = false) {
        var prevValueUndefined = true
        let resolutionFactor:CGFloat = (simple ? 2.0 : 1.0)
        let curve = UIBezierPath()
        let increment = (1/contentScaleFactor)*resolutionFactor
        for (var i:CGFloat=0;i<rect.width;i+=increment) {
            let x = ScreenToX(i)
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
    
    // coord transform functions
    
    func XYToPoint(x: Double, _ y: Double) -> CGPoint {
        return CGPoint(x: XToScreen(x), y: YToScreen(y))
    }
    
    func XToScreen(x: Double) -> CGFloat {
        return CGFloat(x)*density.x + graphCenter.x
    }
    
    func ScreenToX(i: CGFloat) -> Double {
        return Double((i - graphCenter.x)/density.x)
    }
    
    func ScreenToY(i: CGFloat) -> Double {
        return Double((graphCenter.y - i)/density.y)
    }
    
    func YToScreen(y: Double) -> CGFloat {
        return -CGFloat(y)*density.y + graphCenter.y
    }
    
    // gesture handling functions
    
    func moveOrigin(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            simplePlot = false
            setNeedsDisplay()
        case .Changed:
            simplePlot = true
            let translation = gesture.translationInView(self)
            graphOrigin = graphCenter + translation
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
        switch gesture.state {
        case .Changed:
            // if we don't have exactly 2 touchpoints we
            // don't know what's going on
            if gesture.numberOfTouches() == 2 {
                simplePlot = true
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
                
                var scalex:CGFloat = 1.0
                var scaley:CGFloat = 1.0
                
                if theta > scaleZones.scaleXZoneMin && theta <= scaleZones.scaleXZoneMax {
                    densityX *= gesture.scale
                    scalex = gesture.scale
                } else if theta > scaleZones.scaleXYZoneMin && theta <= scaleZones.scaleXYZoneMax {
                    densityX *= gesture.scale
                    densityY *= gesture.scale
                    scalex = gesture.scale
                    scaley = gesture.scale
                } else {
                    densityY *= gesture.scale
                    scaley = gesture.scale
                }
                density = (densityX, densityY)

                // compute the center of the pinch
                let deltaTouch = touch2 - touch1
                touchCenter = touch1 + deltaTouch/2.0
                let touchCenterInGraphCoord = CGPoint(x: ScreenToX(touchCenter.x), y: ScreenToY(touchCenter.y))
                
                // now compute the amount the origin has to move to keep this point 
                // in the same position on the screen
                let translation = CGPoint(x: touchCenterInGraphCoord.x*densityX*(1.0-1.0/scalex), y: touchCenterInGraphCoord.y*densityY*(1.0-1.0/scaley))
                graphOrigin = graphCenter - translation
                
                // let's put a dot where we think this thing is

                gesture.scale=1
            }
        case .Ended:
            simplePlot = false
            setNeedsDisplay()
        default:
            break
        }
    }
    
    func jumpToOrigin(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            graphOrigin = gesture.locationInView(self)
        }
    }
}

// add two CGpoints
private func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x+right.x, y: left.y+right.y)
}
// subtract two CGpoints
private func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x-right.x, y: left.y-right.y)
}

private func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x/right, y: left.y/right)
}