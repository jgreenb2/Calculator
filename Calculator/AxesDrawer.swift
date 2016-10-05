//
//  AxesDrawer.swift
//  Calculator
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//
//  modified by Jeff Greenberg to allow different x/y densities
//

import UIKit

class AxesDrawer
{
    private struct Constants {
        static let HashmarkSize: CGFloat = 6
    }
    
    var color = UIColor.blue
    var minimumPointsPerHashmark: CGFloat = 40
    var contentScaleFactor: CGFloat = 1 // set this from UIView's contentScaleFactor to position axes with maximum accuracy
    
    convenience init(color: UIColor, contentScaleFactor: CGFloat) {
        self.init()
        self.color = color
        self.contentScaleFactor = contentScaleFactor
    }
    
    convenience init(color: UIColor) {
        self.init()
        self.color = color
    }
    
    convenience init(contentScaleFactor: CGFloat) {
        self.init()
        self.contentScaleFactor = contentScaleFactor
    }

    // this method is the heart of the AxesDrawer
    // it draws in the current graphic context's coordinate system
    // therefore origin and bounds must be in the current graphics context's coordinate system
    // pointsPerUnit is essentially the "scale" of the axes
    // e.g. if you wanted there to be 100 points along an axis between -1 and 1,
    //    you'd set pointsPerUnit to 50

    func drawAxesInRect(_ bounds: CGRect, origin: CGPoint, pointsPerUnit: (x: CGFloat, y: CGFloat), drawHashMarks:Bool = true)
    {
        let pointsPerUnitX = pointsPerUnit.x; let pointsPerUnitY = pointsPerUnit.y
        UIGraphicsGetCurrentContext()?.saveGState()
        color.set()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.minX, y: align(origin.y)))
        path.addLine(to: CGPoint(x: bounds.maxX, y: align(origin.y)))
        path.move(to: CGPoint(x: align(origin.x), y: bounds.minY))
        path.addLine(to: CGPoint(x: align(origin.x), y: bounds.maxY))
        path.stroke()
        if drawHashMarks {
            drawHashmarksInRect(bounds, origin: origin, pointsPerUnitX: abs(pointsPerUnitX), pointsPerUnitY: abs(pointsPerUnitY))
        }
        UIGraphicsGetCurrentContext()?.restoreGState()
    }

    // the rest of this class is private

    private func drawHashmarksInRect(_ bounds: CGRect, origin: CGPoint, pointsPerUnitX: CGFloat, pointsPerUnitY: CGFloat)
    {
        if ((origin.x >= bounds.minX) && (origin.x <= bounds.maxX)) || ((origin.y >= bounds.minY) && (origin.y <= bounds.maxY))
        {

            let unitsPerHashmarkX = unitsPerHashmark(minimumPointsPerHashmark, pointsPerUnit: pointsPerUnitX)
            let unitsPerHashmarkY = unitsPerHashmark(minimumPointsPerHashmark, pointsPerUnit: pointsPerUnitY)
            let pointsPerHashmarkX = unitsPerHashmarkX * pointsPerUnitX
            let pointsPerHashmarkY = unitsPerHashmarkY * pointsPerUnitY
            
            let startingHashmarkR = startingHashmarkRadii(bounds,origin: origin,pointsPerHashmarkX: pointsPerHashmarkX,pointsPerHashmarkY: pointsPerHashmarkY)
            
            // now create a bounding box inside whose edges those four hashmarks lie
            var bbox = CGRect(center: origin, size: CGSize(width: 2*pointsPerHashmarkX*startingHashmarkR.x, height: 2*pointsPerHashmarkY*startingHashmarkR.y))

            // formatter for the hashmark labels
            let formatterX = labelFormatter(unitsPerHashmarkX)
            let formatterY = labelFormatter(unitsPerHashmarkY)
    

            // radiate the bbox out until the hashmarks are further out than the bounds
            while !bbox.contains(bounds)
            {   
                let labelX = formatterX.string(from: NSNumber(value: Float((origin.x-bbox.minX)/pointsPerUnitX)))!
                if let leftHashmarkPoint = alignedPoint(bbox.minX, y: origin.y, insideBounds:bounds) {
                    drawHashmarkAtLocation(leftHashmarkPoint, .top("-\(labelX)"))
                }
                if let rightHashmarkPoint = alignedPoint(bbox.maxX, y: origin.y, insideBounds:bounds) {
                    drawHashmarkAtLocation(rightHashmarkPoint, .top(labelX))
                }
                let labelY = formatterY.string(from: NSNumber(value: Float((origin.y-bbox.minY)/pointsPerUnitY)))!
                if let topHashmarkPoint = alignedPoint(origin.x, y: bbox.minY, insideBounds:bounds) {
                    drawHashmarkAtLocation(topHashmarkPoint, .left(labelY))
                }
                if let bottomHashmarkPoint = alignedPoint(origin.x, y: bbox.maxY, insideBounds:bounds) {
                    drawHashmarkAtLocation(bottomHashmarkPoint, .left("-\(labelY)"))
                }
                bbox = bbox.insetBy(dx: -pointsPerHashmarkX, dy: -pointsPerHashmarkY)
            }
        }
    }
    
    private func labelFormatter(_ unitsPerHashmark: CGFloat) -> NumberFormatter {
        // formatter for the hashmark labels
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = Int(-log10(Double(unitsPerHashmark)))
        formatter.minimumIntegerDigits = 1
        return formatter
    }
    
    private func startingHashmarkRadii(_ bounds: CGRect,origin: CGPoint, pointsPerHashmarkX: CGFloat, pointsPerHashmarkY: CGFloat) -> (x: CGFloat, y: CGFloat) {
        // figure out which is the closest set of hashmarks (radiating out from the origin) that are in bounds
        var startingHashmarkRadiusX: CGFloat = 1
        var startingHashmarkRadiusY: CGFloat = 1
        if !bounds.contains(origin) {
            if origin.x > bounds.maxX {
                startingHashmarkRadiusX = (origin.x - bounds.maxX) / pointsPerHashmarkX + 1
            } else if origin.x < bounds.minX {
                startingHashmarkRadiusX = (bounds.minX - origin.x) / pointsPerHashmarkX + 1
            }
            if origin.y > bounds.maxY {
                startingHashmarkRadiusY = (origin.y - bounds.maxY) / pointsPerHashmarkY + 1
            } else {
                startingHashmarkRadiusY = (bounds.minY - origin.y) / pointsPerHashmarkY + 1
            }
        }
        return (floor(startingHashmarkRadiusX), floor(startingHashmarkRadiusY))
    }
    
    private func unitsPerHashmark(_ minimumPointsPerHashmark: CGFloat, pointsPerUnit: CGFloat) -> CGFloat {
        // figure out how many units each hashmark must represent
        // to respect both pointsPerUnit and minimumPointsPerHashmark
        var unitsPerHashmark = minimumPointsPerHashmark / pointsPerUnit
        if unitsPerHashmark < 1 {
            unitsPerHashmark = pow(10, ceil(log10(unitsPerHashmark)))
        } else {
            unitsPerHashmark = floor(unitsPerHashmark)
        }
        
        return unitsPerHashmark
    }
    
    private func drawHashmarkAtLocation(_ location: CGPoint, _ text: AnchoredText)
    {
        var dx: CGFloat = 0, dy: CGFloat = 0
        switch text {
            case .left: dx = Constants.HashmarkSize / 2
            case .right: dx = Constants.HashmarkSize / 2
            case .top: dy = Constants.HashmarkSize / 2
            case .bottom: dy = Constants.HashmarkSize / 2
        }
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: location.x-dx, y: location.y-dy))
        path.addLine(to: CGPoint(x: location.x+dx, y: location.y+dy))
        path.stroke()
        
        text.drawAnchoredToPoint(location, color: color)
    }
    
    private enum AnchoredText
    {
        case left(String)
        case right(String)
        case top(String)
        case bottom(String)
        
        static let VerticalOffset: CGFloat = 3
        static let HorizontalOffset: CGFloat = 6
        
        func drawAnchoredToPoint(_ location: CGPoint, color: UIColor) {
            let attributes = [
                NSFontAttributeName : UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote),
                NSForegroundColorAttributeName : color
            ]
            var textRect = CGRect(center: location, size: text.size(attributes: attributes))
            switch self {
                case .top: textRect.origin.y += textRect.size.height / 2 + AnchoredText.VerticalOffset
                case .left: textRect.origin.x += textRect.size.width / 2 + AnchoredText.HorizontalOffset
                case .bottom: textRect.origin.y -= textRect.size.height / 2 + AnchoredText.VerticalOffset
                case .right: textRect.origin.x -= textRect.size.width / 2 + AnchoredText.HorizontalOffset
            }
            text.draw(in: textRect, withAttributes: attributes)
        }

        var text: String {
            switch self {
                case .left(let text): return text
                case .right(let text): return text
                case .top(let text): return text
                case .bottom(let text): return text
            }
        }
    }

    // we want the axes and hashmarks to be exactly on pixel boundaries so they look sharp
    // setting contentScaleFactor properly will enable us to put things on the closest pixel boundary
    // if contentScaleFactor is left to its default (1), then things will be on the nearest "point" boundary instead
    // the lines will still be sharp in that case, but might be a pixel (or more theoretically) off of where they should be

    private func alignedPoint(_ x: CGFloat, y: CGFloat, insideBounds: CGRect? = nil) -> CGPoint?
    {
        let point = CGPoint(x: align(x), y: align(y))
        if let permissibleBounds = insideBounds {
            if (!permissibleBounds.contains(point)) {
                return nil
            }
        }
        return point
    }

    private func align(_ coordinate: CGFloat) -> CGFloat {
        return round(coordinate * contentScaleFactor) / contentScaleFactor
    }
}

extension CGRect
{
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x-size.width/2, y: center.y-size.height/2, width: size.width, height: size.height)
    }
}
