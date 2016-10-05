//
//  GraphView.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

// MARK: - Protocols
protocol GraphViewDataSource: class {
    func functionValue(atXEquals x: Double) -> Double?
    func programIsSet() -> Bool
}

protocol graphAnimation: class {
    func animationCompleted()
    func updateGraphPosition(byDelta deltaPosition:CGPoint)
}

private typealias Interval = (x0: Double, xf: Double)

/**  
    GraphView is a UIView used to render the function plot.
 
    Although we allow panning and zooming, GraphView is not a
    UIScrollView. It provides a fixed-size viewport for drawing that is
    based on the available screen real estate. Transformations (e.g.
    panning/zooming) are handled manually by changing the coordinate
    transformation between the view coordinates and the function coordinates.
 
    Panning is acheived by changing the graphOrigin variable. Zooming occurs by 
    changing the density variable. Changing these values forces a setsNeedsDisplay
    which will redraw the entire graph.
 
    To improve peformance, function values are cached in the plotData struct and 
    a full function evaluation is only done for new abscissa values or if the abscissa
    scaling has changed.
 
    Pan gestures implement inertial scrolling by animating the graphOrigin variable if
    the velocity at the end of the pan gesture exceeds a threshold value.
*/
@IBDesignable
class GraphView: UIView, UIGestureRecognizerDelegate, graphAnimation {

    // MARK: - General graph and view properties
    
    /// the intersection of the x & y axes expressed in screen coordinates
    /// optional because it will be nil when a new GraphView is created
    ///
    /// used indirectly by graphCenter. This value is set directly when
    /// moving the origin through dragging or tapping
    var graphOrigin:CGPoint? {
        didSet {
            if graphOrigin != nil {
                (minX,maxX) = newXRange(pointsPerUnit: density.x, origin: graphCenter)
                (minY,maxY) = newYRange(pointsPerUnit: density.y, origin: graphCenter)
                setNeedsDisplay()
             }
        }
    }
    
    /// a computed version of the origin that returns the default center position
    /// OR the graphOrigin if it's been set. Whenever anyone wants to know what
    /// the current origin is, this is what you pass them
    private var graphCenter: CGPoint {
        return graphOrigin ?? convert(center, from: superview!)
    }

    @IBInspectable
    var lineWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var axesColor:UIColor = #colorLiteral(red: 0, green: 0, blue: 1, alpha: 1) { didSet { setNeedsDisplay() } }
    @IBInspectable
    var lineColor:UIColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1) { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var minX:Double = -10
    @IBInspectable
    var maxX:Double = 10
    @IBInspectable
    var minY:Double = -10
    @IBInspectable
    var maxY:Double = 10
        
    private var simplePlot:Bool = false
    /// Density is a tuple that defines the number of view coordiante points per unit in
    /// function space. Changing the density triggers a recomputation of the view boundaries
    /// in function space.
    private var density: (x: CGFloat, y: CGFloat) = (25,25) {
        didSet {
            (minX,maxX) = newXRange(pointsPerUnit: density.x, origin: graphCenter)
            (minY,maxY) = newYRange(pointsPerUnit: density.y, origin: graphCenter)
        }
    }
    
    /**
     compute a tuple that defines the vertical range of the current view in function space
     
     - parameter density: view density
     - parameter origin:  view origin
     
     - returns: vertical range
     */
    private func newYRange(pointsPerUnit yDensity: CGFloat, origin: CGPoint) -> (yMin:Double, yMax:Double) {
        return (Double(-origin.y/yDensity), Double((bounds.maxY-origin.y)/yDensity))
    }
    
    /**
     compute a tuple that defines the horizontal range of the current view in function space
     
     - parameter density: view density
     - parameter origin:  view origin
     
     - returns: horizontal range
     */
    private func newXRange(pointsPerUnit xDensity: CGFloat, origin: CGPoint) -> (xMin:Double, xMax:Double) {
        return (Double(-origin.x/xDensity), Double((bounds.maxX-origin.x)/xDensity))
    }
    
    // MARK: - Plotting
    lazy var axes:AxesDrawer = { AxesDrawer(color: self.axesColor, contentScaleFactor: self.contentScaleFactor) }()
    override func draw(_ rect: CGRect) {
        axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: density, drawHashMarks: !simplePlot)
        plotFunction(inRect: rect,simple: simplePlot)
    }
    
    weak var dataSource: GraphViewDataSource?
    
    /**
     *  A holder for the function data used
        to generate a plot
     */
    struct PlotData {
        fileprivate var data:RingBuffer<Double?>
        fileprivate var interval:Interval
        var stale=true
        
        fileprivate init(npoints: Int, xrange: Interval) {
            data = RingBuffer(N: npoints)
            interval = xrange
        }
        
        init() {
            self.init(npoints: 0, xrange: Interval(x0: 0, xf: 0))
        }
    }
    
    // store the function data in plotData.
    var plotData = PlotData()

    /**
     draw the actual graph
     
     - parameter rect:   The  rect that defines the viewport
     - parameter simple: Set to true to suppress axis labels. May also
                         simplify plotting in other unspecified ways
     */
    private func plotFunction(inRect rect: CGRect, simple:Bool = false) {
        var prevValueUndefined = true
        let curve = UIBezierPath()
        
        // set the viewport parameters
        let nPoints = rect.width
        let xrange = Interval(x0: ScreenToX(0), xf: ScreenToX(nPoints-1))
        let increment = 1/contentScaleFactor
        
        // retrieve the data that will be plotted
        updateFunctionData(dataToBeUpdated: &plotData,
                           dataSize: Int(nPoints*contentScaleFactor),
                           xrange: xrange,
                           deltaX: Double(increment/density.x))
        
        // do the drawing but be
        // careful NOT to draw lines to or from 
        // undefined points
        var i:CGFloat = 0
        while ( i < nPoints) {
            let x = ScreenToX(i)
            if let y = plotData.data.next() ?? nil {    // plotData.data.next() returns a Double??
                if !prevValueUndefined {
                    curve.addLine(to: XYToPoint(x,y))
                } else {
                    curve.move(to: XYToPoint(x,y))
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
    
    /**
      evaluate the function. only recalculate the newly exposed portions of the
      plot axis.
     
      There are 3 cases: 
      1) recalculate the entire function
      2) calculate new values on the left
      3) claculate new values on the right
     
     - parameter plotData: Holder for the data. Will be updated by funcData
     - parameter dataSize: the number of data points for a full function evaluation
     - parameter xrange:   An inclusive x-axis interval
     - parameter dx:       The x-axis increment
     */
    private func updateFunctionData(dataToBeUpdated plotData:inout PlotData, dataSize: Int, xrange: Interval, deltaX dx: Double) {
        struct staticVars {
            static var size = 0
            static var dx:Double = 0
        }

        // if the xaxis scaling has changed or the axis has a different number of points
        // we need to recalculate the entire function. 
        //
        // plotData.stale is set true on a segue which usually
        // means that the user initiated plotting of a new function
        
        if staticVars.size != dataSize || staticVars.dx != dx || plotData.stale {
            staticVars.size = dataSize
            staticVars.dx = dx
            
            plotData = PlotData(npoints: dataSize, xrange: xrange)
            var x = xrange.x0
            while x <= xrange.xf {
                plotData.data.addAtCurrentPosition(dataSource?.functionValue(atXEquals: x))
                x += dx
            }
            plotData.interval = xrange
            plotData.stale = false
            
        // If the plot is scrolling to the right we just need to calculate the 'earlier' points
            
        } else if xrange.x0 < plotData.interval.x0 {
            var x = plotData.interval.x0 - dx
            while x >= roundToDx(xrange.x0, dx: dx) {
                plotData.data.prependToBeginning(dataSource?.functionValue(atXEquals: x))
                plotData.interval -= dx                
                x -= dx
            }

        // ...or if it's scrolling to the left we add points to the end
            
         } else if xrange.xf > plotData.interval.xf {
            var x = plotData.interval.xf + dx
            while x <= roundToDx(xrange.xf, dx: dx) {
                plotData.data.appendToEnd(dataSource?.functionValue(atXEquals: x))
                plotData.interval += dx
                x += dx
            }
        }
        
        // set the read pointer to the beginning before returning
        plotData.data.reset()
    }
    
    /**
     Rounds a Double to the nearest 'dx'
     
     - parameter x:  The value to round
     - parameter dx: The increment to round to
     
     - returns: The rounded value
     */
    private func roundToDx(_ x:Double, dx: Double) -> Double {
        return floor(round(x/dx))*dx
    }
    
    // MARK: - coord transforms
    /**
     convert point in function space to view coordinates
     
     - parameter x: function abscissa
     - parameter y: function ordinate
     
     - returns: CGPoint in view
     */
    private func XYToPoint(_ x: Double, _ y: Double) -> CGPoint {
        return CGPoint(x: XToScreen(x), y: YToScreen(y))
    }
    
    /**
     convert horizontal view coordinate to abscissa
     
     - parameter i: horizontal point
     
     - returns: abscissa value
     */
    private func ScreenToX(_ i: CGFloat) -> Double {
        return Double((i - graphCenter.x)/density.x)
    }
    
    /**
     convert vertical view coordinate to ordinate
     
     - parameter i: vertical point
     
     - returns: ordinate value
     */
    private func ScreenToY(_ i: CGFloat) -> Double {
        return Double((graphCenter.y - i)/density.y)
    }
    
    /**
     convert abscissa to horizontal view coordinate
     
     - parameter x: abscissa value
     
     - returns: horizontal view coordinate
     */
    private func XToScreen(_ x: Double) -> CGFloat {
        return CGFloat(x)*density.x + graphCenter.x
    }
    
    /**
     convert ordinate to vertical view coordinate
     
     - parameter y: ordinate value
     
     - returns: vertical view coordiante
     */
    private func YToScreen(_ y: Double) -> CGFloat {
        return -CGFloat(y)*density.y + graphCenter.y
    }
    
    /**
     convert point in view to an abscissa and ordinate
     
     - parameter p: point in view
     
     - returns: CGPoint containing abscissa and ordinate
     */
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
    
    /**
        Executed when a pan gesture is in the .Ended state.
        if speed is greater than threshold, kickoff an animation
        that implements inertial scrolling
     
     - parameter velocity: vector velocity at the end of the gesture
       in points/second
     */
    func finishPanGesture(withVelocity v: CGPoint) {
        if let delta = beginPanTime?.timeIntervalUntilNow , delta < maxSwipeTime {
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
    
    /**
        Define regions used by scaleGraph to
        determine the direction to move the
        plot. Zones are in degrees.
     
     - seealso: scaleGraph

     */
    private struct scaleZones {
        static let scaleXYZoneMin = -67.5
        static let scaleXYZoneMax = 67.5
        static let scaleXZoneMin = -22.5
        static let scaleXZoneMax = 22.5
    }
    
    /**
     Respond to a pinch/zoom gesture by changing the x and/or y axis scaling.
     We handle 3 cases:
     
     - 'vertical' pinch/zoom scales the y-axis only
     - 'horizontal' pinch/zoom scales the x-axis only
     - 'diagonal' pinch/zoom scales both the x and y axes simultaneously
     
     The defintion of vertial/horizontal/diagonal is based on the angular 
     definitions in the scaleZones struct.
     
     Zooming occurs around the centroid of the pinch/zoom gesture. This is
     accomplished by simultaneously changing the transformation density as well
     as the graphOrigin.
     
     - parameter gesture: the pinch/zoom gesture recognizer
     */
    func scaleGraph(byGesture pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .changed:
            // if we don't have exactly 2 touchpoints we
            // don't know what's going on
            if pinch.numberOfTouches == 2 {
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
    /**
     turn off reduced resolution plotting
     */
    private func drawDetailedPlot() {
        simplePlot = false
        setNeedsDisplay()        
    }
    
    /**
     move graph origin to the tap location
     
     - parameter gesture: the tap gesture
     */
    func jumpToOrigin(byGesture tap: UITapGestureRecognizer) {
        if tap.state == .ended {
            graphOrigin = tap.location(in: self)
        }
    }

    // MARK: - inertial animation
    
    private var inertialAnimation:moveGraphWithInertia?
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
    
    internal func animationCompleted() {
        cancelAnimation()
        drawDetailedPlot()
    }
    
    func updateGraphPosition(byDelta dp: CGPoint) {
        graphOrigin = graphCenter + dp
    }
    
}

// MARK: - computes graph movement with simple newtonian friction model
private class moveGraphWithInertia: Animation {
    let animationIdentifier = "inertialAnimation"
    
    var velocity:CGPoint
    weak var delegate:graphAnimation?
    
    let mu = CGFloat(5)
    let velocityThreshold = CGFloat(10)
    
    init(initialVelocity:CGPoint) {
        velocity = initialVelocity
    }
    
    func animationTick(_ tickDelta: CFTimeInterval) {
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

// MARK: - Operator overloads for convenient arithmetic

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

// increment or decrement an interval

private func += (left:inout Interval, right: Double)  {
    left.x0 += right
    left.xf += right
}

private func -= (left:inout Interval, right: Double) {
    left.x0 -= right
    left.xf -= right
}

// I hate the minus sign on timeIntervalSinceNow so we just
// create a better version here
extension Date {
    var timeIntervalUntilNow: TimeInterval {
        return -timeIntervalSinceNow
    }
}
