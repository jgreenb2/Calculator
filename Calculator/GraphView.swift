//
//  GraphView.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func functionValue(_ atXEquals: Double) -> Double?
}

protocol graphAnimation: class {
    func animationCompleted()
    func updateGraphPosition(byDelta deltaPosition:CGPoint)
}

@IBDesignable
class GraphView: UIView, UIGestureRecognizerDelegate, graphAnimation {
    
    // the intersection of the x & y axes expressed in screen coordinates
    // optional because it will be nil when a new GraphView is created
    //
    // used indirectly by graphCenter. This value is set directly when
    // moving the origin through dragging or tapping
    var graphOrigin:CGPoint? {
        didSet {
            if graphOrigin != nil {
                (minX,maxX) = newXRange(xDensity: density.x, origin: graphCenter)
                (minY,maxY) = newYRange(yDensity: density.y, origin: graphCenter)
                setNeedsDisplay()
             }
        }
    }
    
    // a computed version of the origin that returns the default center position
    // OR the graphOrigin if it's been set. Whenever anyone wants to know what
    // the current origin is, this is what you pass them
    private var graphCenter: CGPoint {
        return graphOrigin ?? convert(center, from: superview!)
    }

    @IBInspectable
    var lineWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var axesColor: UIColor = UIColor.blue() { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var lineColor: UIColor = UIColor.red() { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var minX:Double = -10
    @IBInspectable
    var maxX:Double = 10
    @IBInspectable
    var minY:Double = -10
    @IBInspectable
    var maxY:Double = 10
    
    private var simplePlot:Bool = false
    
    private var density: (x: CGFloat, y: CGFloat) = (25,25) {
        didSet {
            (minX,maxX) = newXRange(xDensity: density.x, origin: graphCenter)
            (minY,maxY) = newYRange(yDensity: density.y, origin: graphCenter)
        }
    }
    
    private func newYRange(yDensity: CGFloat, origin: CGPoint) -> (yMin:Double, yMax:Double) {
        return (Double(-origin.y/yDensity), Double((bounds.maxY-origin.y)/yDensity))
    }
    
    private func newXRange(xDensity: CGFloat, origin: CGPoint) -> (xMin:Double, xMax:Double) {
        return (Double(-origin.x/xDensity), Double((bounds.maxX-origin.x)/xDensity))
    }
    

    override func draw(_ rect: CGRect) {
        let axes = AxesDrawer(color: axesColor, contentScaleFactor: contentScaleFactor)
        if simplePlot {
            axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: density, drawHashMarks: false)
            plotFunction(inRect: rect,simple: true)
        } else {
            axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: density, drawHashMarks: true)
            plotFunction(inRect: rect,simple: false)
        }
    }
    
    // plot the function using the appropriate protocol
    // We are careful NOT to draw lines to or from 
    // undefined points
    weak var dataSource: GraphViewDataSource?

    private func plotFunction(inRect rect: CGRect, simple:Bool = false) {
        var prevValueUndefined = true
        let resolutionFactor:CGFloat = (simple ? 2.0 : 1.0)
        let curve = UIBezierPath()
        let increment = (1/contentScaleFactor)*resolutionFactor
        var i:CGFloat = 0
        while ( i < rect.width) {
            let x = ScreenToX(i)
            if let y = dataSource?.functionValue(x) {
                if !prevValueUndefined {
                    curve.addLine(to: XYToPoint(x,y))
                } else {
                    curve.move(to: XYToPoint(x,y))
                }
                prevValueUndefined = false
            } else {
                prevValueUndefined = true
            }
            i+=increment
        }
        curve.lineWidth=lineWidth
        lineColor.set()
        curve.stroke()
    }
    
    // coord transform functions
    
    private func XYToPoint(_ x: Double, _ y: Double) -> CGPoint {
        return CGPoint(x: XToScreen(x), y: YToScreen(y))
    }
    
    private func ScreenToX(_ i: CGFloat) -> Double {
        return Double((i - graphCenter.x)/density.x)
    }
    
    private func ScreenToY(_ i: CGFloat) -> Double {
        return Double((graphCenter.y - i)/density.y)
    }
    
    private func XToScreen(_ x: Double) -> CGFloat {
        return CGFloat(x)*density.x + graphCenter.x
    }
    
    private func YToScreen(_ y: Double) -> CGFloat {
        return -CGFloat(y)*density.y + graphCenter.y
    }
    
    private func ScreenToXY(_ p: CGPoint) -> CGPoint {
        return CGPoint(x: ScreenToX(p.x), y: ScreenToY(p.y))
    }
    
    // gesture handling functions
    
    // pan gestures that last for less than maxSwipeTime
    // are treated as swipes that start an inertial scrolling
    // animation
    var beginPanTime:Date?
    let maxSwipeTime = 0.3

    func moveOrigin(byGesture pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            beginPanTime = Date()
        case .ended:
            drawDetailedPlot()
            // start an inertial animation if needed
            finishPanGesture(withVelocity: pan.velocity(in: self))
        case .changed:
            simplePlot = true
            let translation = pan.translation(in: self)
            graphOrigin = graphCenter + translation
            pan.setTranslation(CGPoint.zero, in: self)
        default:
            break
        }
    }
    
    // if speed is greater than threshold, kickoff an animation
    // that implements inertial scrolling
    func finishPanGesture(withVelocity v: CGPoint) {
        if let delta = beginPanTime?.timeIntervalUntilNow where delta < maxSwipeTime {
            simplePlot = true
            startInertialAnimation(withVelocity: v)
        }
    }

    // on any touch in the window cancel any existing inertial
    // animation
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelAnimation()
        animationCompleted()
        super.touchesBegan(touches, with: event)
    }
    
    private struct scaleZones {
        static let scaleXYZoneMin = -67.5
        static let scaleXYZoneMax = 67.5
        static let scaleXZoneMin = -22.5
        static let scaleXZoneMax = 22.5
    }
    
    func scaleGraph(byGesture pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .changed:
            // if we don't have exactly 2 touchpoints we
            // don't know what's going on
            if pinch.numberOfTouches() == 2 {
                simplePlot = true
                // get the touchpoints
                let touch1 = pinch.location(ofTouch: 0, in: self)
                let touch2 = pinch.location(ofTouch: 1, in: self)
                
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
                    densityX *= pinch.scale
                    scalex = pinch.scale
                } else if theta > scaleZones.scaleXYZoneMin && theta <= scaleZones.scaleXYZoneMax {
                    densityX *= pinch.scale
                    densityY *= pinch.scale
                    scalex = pinch.scale
                    scaley = pinch.scale
                } else {
                    densityY *= pinch.scale
                    scaley = pinch.scale
                }
                density = (densityX, densityY)

                // compute the center of the pinch
                let touchCenter = pinch.location(in: self)
                
                // now compute the amount the origin has to move to keep this point 
                // in the same position on the screen

                let translation = CGPoint(x: (touchCenter.x-graphCenter.x)*(1.0-scalex), y: (touchCenter.y-graphCenter.y)*(1.0-scaley))
                graphOrigin = graphCenter + translation
                
                pinch.scale=1
            }
        case .ended:
            drawDetailedPlot()
        default:
            break
        }
    }
    
    // turn off reduced resolution plotting
    func drawDetailedPlot() {
        simplePlot = false
        setNeedsDisplay()        
    }
    
    // move graph origin to the tap location
    func jumpToOrigin(byGesture tap: UITapGestureRecognizer) {
        if tap.state == .ended {
            graphOrigin = tap.location(in: self)
        }
    }

    // inertial animation functions
    
    var inertialAnimation:moveGraphWithInertia?
    func cancelAnimation() {
        if let inertialAnimation = inertialAnimation {
            animator().remove(animation: inertialAnimation)
        }
    }
    
    func startInertialAnimation(withVelocity v:CGPoint) {
        cancelAnimation()
        inertialAnimation = moveGraphWithInertia(initialVelocity: v)
        inertialAnimation?.delegate = self
        animator().add(animation: inertialAnimation)
    }
    
    func animationCompleted() {
        drawDetailedPlot()
    }
    
    func updateGraphPosition(byDelta dp: CGPoint) {
        graphOrigin = graphCenter + dp
    }
}

// computes graph movement with simple newtonian friction model
class moveGraphWithInertia: Animation {
    let animationIdentifier = "inertialAnimation"
    
    var velocity:CGPoint
    weak var delegate:graphAnimation?
    
    let mu = CGFloat(5)
    let velocityThreshold = CGFloat(10)
    
    init(initialVelocity:CGPoint) {
        velocity = initialVelocity
    }
    
    func animationTick(tickDelta: CFTimeInterval) {
        assert(delegate != nil, "The graphAnimation delegate is not set")
        
        let time = CGFloat(tickDelta)
        let frictionForce = velocity * mu 
        
        velocity = velocity - frictionForce * time
        

        let delta = velocity * time
        delegate?.updateGraphPosition(byDelta: delta)
        
        let speed = magnitude(velocity)      
        if speed < velocityThreshold {
            delegate?.animationCompleted()
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
// L2 norm of CGPoint
private func magnitude(_ v:CGPoint) -> CGFloat{
    return sqrt(pow(v.x,2)+pow(v.y,2))
}
// cartesian distance from p1 to p2
private func distance(from p1:CGPoint, to p2:CGPoint) -> CGFloat {
    let delta = p2 - p1
    return magnitude(delta)
}

// divide a CGPoint by a scalar
private func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x/right, y: left.y/right)
}

// multiply a CGPoint by a scalar
private func * (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x*right, y: left.y*right)
}

// I hate the minus sign on timeIntervalSinceNow so we just
// create a better version here
extension Date {
    var timeIntervalUntilNow: TimeInterval {
        return -timeIntervalSinceNow
    }
}
