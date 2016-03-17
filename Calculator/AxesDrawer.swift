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
    
    var color = UIColor.blueColor()
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

    func drawAxesInRect(bounds: CGRect, origin: CGPoint, pointsPerUnit: (x: CGFloat, y: CGFloat), drawHashMarks:Bool = true)
    {
        let pointsPerUnitX = pointsPerUnit.x; let pointsPerUnitY = pointsPerUnit.y
        CGContextSaveGState(UIGraphicsGetCurrentContext())
        color.set()
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: bounds.minX, y: align(origin.y)))
        path.addLineToPoint(CGPoint(x: bounds.maxX, y: align(origin.y)))
        path.moveToPoint(CGPoint(x: align(origin.x), y: bounds.minY))
        path.addLineToPoint(CGPoint(x: align(origin.x), y: bounds.maxY))
        path.stroke()
        if drawHashMarks {
            drawHashmarksInRect(bounds, origin: origin, pointsPerUnitX: abs(pointsPerUnitX), pointsPerUnitY: abs(pointsPerUnitY))
        }
        CGContextRestoreGState(UIGraphicsGetCurrentContext())
    }

    // the rest of this class is private

    private func drawHashmarksInRect(bounds: CGRect, origin: CGPoint, pointsPerUnitX: CGFloat, pointsPerUnitY: CGFloat)
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
            while !CGRectContainsRect(bbox, bounds)
            {
                let labelX = formatterX.stringFromNumber((origin.x-bbox.minX)/pointsPerUnitX)!
                if let leftHashmarkPoint = alignedPoint(x: bbox.minX, y: origin.y, insideBounds:bounds) {
                    drawHashmarkAtLocation(leftHashmarkPoint, .Top("-\(labelX)"))
                }
                if let rightHashmarkPoint = alignedPoint(x: bbox.maxX, y: origin.y, insideBounds:bounds) {
                    drawHashmarkAtLocation(rightHashmarkPoint, .Top(labelX))
                }
                let labelY = formatterY.stringFromNumber((origin.y-bbox.minY)/pointsPerUnitY)!
                if let topHashmarkPoint = alignedPoint(x: origin.x, y: bbox.minY, insideBounds:bounds) {
                    drawHashmarkAtLocation(topHashmarkPoint, .Left(labelY))
                }
                if let bottomHashmarkPoint = alignedPoint(x: origin.x, y: bbox.maxY, insideBounds:bounds) {
                    drawHashmarkAtLocation(bottomHashmarkPoint, .Left("-\(labelY)"))
                }
                bbox.insetInPlace(dx: -pointsPerHashmarkX, dy: -pointsPerHashmarkY)
            }
        }
    }
    
    private func labelFormatter(unitsPerHashmark: CGFloat) -> NSNumberFormatter {
        // formatter for the hashmark labels
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = Int(-log10(Double(unitsPerHashmark)))
        formatter.minimumIntegerDigits = 1
        return formatter
    }
    
    private func startingHashmarkRadii(bounds: CGRect,origin: CGPoint, pointsPerHashmarkX: CGFloat, pointsPerHashmarkY: CGFloat) -> (x: CGFloat, y: CGFloat) {
        // figure out which is the closest set of hashmarks (radiating out from the origin) that are in bounds
        var startingHashmarkRadiusX: CGFloat = 1
        var startingHashmarkRadiusY: CGFloat = 1
        if !CGRectContainsPoint(bounds, origin) {
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
    
    private func unitsPerHashmark(minimumPointsPerHashmark: CGFloat, pointsPerUnit: CGFloat) -> CGFloat {
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
    
    private func drawHashmarkAtLocation(location: CGPoint, _ text: AnchoredText)
    {
        var dx: CGFloat = 0, dy: CGFloat = 0
        switch text {
            case .Left: dx = Constants.HashmarkSize / 2
            case .Right: dx = Constants.HashmarkSize / 2
            case .Top: dy = Constants.HashmarkSize / 2
            case .Bottom: dy = Constants.HashmarkSize / 2
        }
        
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: location.x-dx, y: location.y-dy))
        path.addLineToPoint(CGPoint(x: location.x+dx, y: location.y+dy))
        path.stroke()
        
        text.drawAnchoredToPoint(location, color: color)
    }
    
    private enum AnchoredText
    {
        case Left(String)
        case Right(String)
        case Top(String)
        case Bottom(String)
        
        static let VerticalOffset: CGFloat = 3
        static let HorizontalOffset: CGFloat = 6
        
        func drawAnchoredToPoint(location: CGPoint, color: UIColor) {
            let attributes = [
                NSFontAttributeName : UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote),
                NSForegroundColorAttributeName : color
            ]
            var textRect = CGRect(center: location, size: text.sizeWithAttributes(attributes))
            switch self {
                case Top: textRect.origin.y += textRect.size.height / 2 + AnchoredText.VerticalOffset
                case Left: textRect.origin.x += textRect.size.width / 2 + AnchoredText.HorizontalOffset
                case Bottom: textRect.origin.y -= textRect.size.height / 2 + AnchoredText.VerticalOffset
                case Right: textRect.origin.x -= textRect.size.width / 2 + AnchoredText.HorizontalOffset
            }
            text.drawInRect(textRect, withAttributes: attributes)
        }

        var text: String {
            switch self {
                case Left(let text): return text
                case Right(let text): return text
                case Top(let text): return text
                case Bottom(let text): return text
            }
        }
    }

    // we want the axes and hashmarks to be exactly on pixel boundaries so they look sharp
    // setting contentScaleFactor properly will enable us to put things on the closest pixel boundary
    // if contentScaleFactor is left to its default (1), then things will be on the nearest "point" boundary instead
    // the lines will still be sharp in that case, but might be a pixel (or more theoretically) off of where they should be

    private func alignedPoint(x x: CGFloat, y: CGFloat, insideBounds: CGRect? = nil) -> CGPoint?
    {
        let point = CGPoint(x: align(x), y: align(y))
        if let permissibleBounds = insideBounds {
            if (!CGRectContainsPoint(permissibleBounds, point)) {
                return nil
            }
        }
        return point
    }

    private func align(coordinate: CGFloat) -> CGFloat {
        return round(coordinate * contentScaleFactor) / contentScaleFactor
    }
}

extension CGRect
{
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x-size.width/2, y: center.y-size.height/2, width: size.width, height: size.height)
    }
}
