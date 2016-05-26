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
    func programSet() -> Bool
}

protocol graphAnimation: class {
    func animationCompleted()
    func updateGraphPosition(deltaPosition:CGPoint)
}

typealias Interval = (x0: Double, xf: Double)

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
                (minX,maxX) = newXRange(density.x, origin: graphCenter)
                (minY,maxY) = newYRange(density.y, origin: graphCenter)
                setNeedsDisplay()
             }
        }
    }
    
    // a computed version of the origin that returns the default center position
    // OR the graphOrigin if it's been set. Whenever anyone wants to know what
    // the current origin is, this is what you pass them
    private var graphCenter: CGPoint {
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
        
    private var simplePlot:Bool = false
    
    private var density: (x: CGFloat, y: CGFloat) = (25,25) {
        didSet {
            (minX,maxX) = newXRange(density.x, origin: graphCenter)
            (minY,maxY) = newYRange(density.y, origin: graphCenter)
        }
    }
    
    private func newYRange(density: CGFloat, origin: CGPoint) -> (yMin:Double, yMax:Double) {
        return (Double(-origin.y/density), Double((bounds.maxY-origin.y)/density))
    }
    
    private func newXRange(density: CGFloat, origin: CGPoint) -> (xMin:Double, xMax:Double) {
        return (Double(-origin.x/density), Double((bounds.maxX-origin.x)/density))
    }
    

    override func drawRect(rect: CGRect) {
        let axes = AxesDrawer(color: axesColor, contentScaleFactor: contentScaleFactor)
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
    private var xInterval:Interval?
    
    class PlotData {
        var data:RingBuffer<Double?>
        private var interval:Interval
        
        private init(N: Int, i: Interval) {
            data = RingBuffer(N: N)
            interval = i
        }
    }
    
    lazy var plotData:PlotData = { [unowned self] in 
        let nPoints = self.bounds.width
        let xrange = Interval(x0: self.ScreenToX(0), xf: self.ScreenToX(nPoints-1))
        return PlotData(N: Int(nPoints*self.contentScaleFactor),i: xrange)
        }()

    private func plotFunction(rect: CGRect, simple:Bool = false) {
        guard  let dataSource = dataSource else { return }
        guard  dataSource.programSet() else { return }
        
        var prevValueUndefined = true
        let curve = UIBezierPath()
        
        let nPoints = rect.width
        let xrange = Interval(x0: ScreenToX(0), xf: ScreenToX(nPoints-1))
        let increment = 1/contentScaleFactor
        funcData(&plotData, dataSize: Int(nPoints*contentScaleFactor), xrange: xrange, dx: Double(increment/density.x))
        var i:CGFloat = 0
        while ( i < nPoints) {
            let x = ScreenToX(i)
            if let y = plotData.data.next() ?? nil {
                if !prevValueUndefined {
                    curve.addLineToPoint(XYToPoint(x,y))
                } else {
                    curve.moveToPoint(XYToPoint(x,y))
                }
                prevValueUndefined = false
            } else {
                prevValueUndefined = true
            }
            i += increment
        }
        curve.lineWidth=lineWidth
        lineColor.set()
        curve.stroke()
    }
    
    func funcData(inout plotData:PlotData, dataSize: Int, xrange: Interval, dx: Double) {
        struct staticVars {
            static var size = 0
            static var dx:Double = 0
        }

        var iter1=0, iter2=0, iter3=0

        if staticVars.size != dataSize || staticVars.dx != dx {
            staticVars.size = dataSize
            staticVars.dx = dx
            
            plotData = PlotData(N: dataSize, i: xrange)
            var x = xrange.x0
            while iter1 < dataSize {
                plotData.data.addAtCurrentPosition(dataSource?.functionValue(self, atXEquals: x))
                x += dx
                iter1 += 1
            }
            plotData.interval = xrange
        } else if xrange.x0 < plotData.interval.x0 {
            plotData.data.reset()
            let n = Int(round((plotData.interval.x0 - xrange.x0)/dx))
            var x = plotData.interval.x0 - dx
            while iter2 < n {
                plotData.data.prependToBeginning(dataSource?.functionValue(self, atXEquals: x))
                plotData.interval -= dx
                
                x -= dx
                iter2 += 1
            }
         } else if xrange.xf > plotData.interval.xf {
            plotData.data.reset()
            let n = Int(round((xrange.xf - plotData.interval.xf)/dx))
            var x = plotData.interval.xf + dx
            while iter3 < n {
                plotData.data.appendToEnd(dataSource?.functionValue(self, atXEquals: x))
                plotData.interval += dx

                x += dx
                iter3 += 1
            }
        }
        
        plotData.data.reset()
    }
    
    // coord transform functions
    
    private func XYToPoint(x: Double, _ y: Double) -> CGPoint {
        return CGPoint(x: XToScreen(x), y: YToScreen(y))
    }
    
    private func ScreenToX(i: CGFloat) -> Double {
        return Double((i - graphCenter.x)/density.x)
    }
    
    private func ScreenToY(i: CGFloat) -> Double {
        return Double((graphCenter.y - i)/density.y)
    }
    
    private func XToScreen(x: Double) -> CGFloat {
        return CGFloat(x)*density.x + graphCenter.x
    }
    
    private func YToScreen(y: Double) -> CGFloat {
        return -CGFloat(y)*density.y + graphCenter.y
    }
    
    private func ScreenToXY(p: CGPoint) -> CGPoint {
        return CGPoint(x: ScreenToX(p.x), y: ScreenToY(p.y))
    }
    
    // gesture handling functions
    
    // pan gestures that last for less than maxSwipeTime
    // are treated as swipes that start an inertial scrolling
    // animation
    var beginPanTime:NSDate?
    let maxSwipeTime = 0.3

    func moveOrigin(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Began:
            beginPanTime = NSDate()
        case .Ended:
            drawDetailedPlot()
            // start an inertial animation if needed
            finishPanGesture(gesture.velocityInView(self))
        case .Changed:
            simplePlot = true
            let translation = gesture.translationInView(self)
            graphOrigin = graphCenter + translation
            gesture.setTranslation(CGPointZero, inView: self)
        default:
            break
        }
    }
    
    // if speed is greater than threshold, kickoff an animation
    // that implements inertial scrolling
    func finishPanGesture(velocity: CGPoint) {
        if let delta = beginPanTime?.timeIntervalSinceNow {
            if -delta < maxSwipeTime {
                simplePlot = true
                startInertialAnimation(velocity)
            }
        }
    }

    // on any touch in the window cancel any existing inertial
    // animation
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        cancelAnimation()
        animationCompleted()
        super.touchesBegan(touches, withEvent: event)
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
                let touchCenter = gesture.locationInView(self)
                
                // now compute the amount the origin has to move to keep this point 
                // in the same position on the screen

                let translation = CGPoint(x: (touchCenter.x-graphCenter.x)*(1.0-scalex), y: (touchCenter.y-graphCenter.y)*(1.0-scaley))
                graphOrigin = graphCenter + translation
                
                gesture.scale=1
            }
        case .Ended:
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
    func jumpToOrigin(gesture: UITapGestureRecognizer) {
        if gesture.state == .Ended {
            graphOrigin = gesture.locationInView(self)
        }
    }

    // inertial animation functions
    
    var inertialAnimation:moveGraphWithInertia?
    func cancelAnimation() {
        if let inertialAnimation = inertialAnimation {
            animator().removeAnimation(inertialAnimation)
        }
    }
    
    func startInertialAnimation(initialVelocity:CGPoint) {
        cancelAnimation()
        inertialAnimation = moveGraphWithInertia(initialVelocity: initialVelocity)
        inertialAnimation?.delegate = self
        animator().addAnimation(inertialAnimation)
    }
    
    func animationCompleted() {
        cancelAnimation()
        drawDetailedPlot()
    }
    
    func updateGraphPosition(deltaPosition: CGPoint) {
        graphOrigin = graphCenter + deltaPosition
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
    
    func animationTick(dt: CFTimeInterval) {
        assert(delegate != nil, "The graphAnimation delegate is not set")
        
        let time = CGFloat(dt)
        let frictionForce = velocity * mu 
        
        velocity = velocity - frictionForce * time
        

        let delta = velocity * time
        delegate?.updateGraphPosition(delta)
        
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
private func magnitude(v:CGPoint) -> CGFloat{
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

// increment or decrement an interval

private func += (inout left:Interval, right: Double)  {
    left.x0 += right
    left.xf += right
}

private func -= (inout left:Interval, right: Double) {
    left.x0 -= right
    left.xf -= right
}


