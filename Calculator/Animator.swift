//
//  Animator.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/19/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//
//  Based on objective-C Animator example at
//  http://www.objc.io (see 12, "implementing animations")
//
import UIKit

protocol Animation: class {
    func animationTick(dt:CFTimeInterval)
}

class Animator: NSObject {
    var displayLink:CADisplayLink?
    var animations=NSMutableSet()

    static let sharedInstance: Animator = {
        let instance = Animator(screen: UIScreen.mainScreen())
        return instance
    }()
    
    
    init(screen:UIScreen) {
        super.init()
        displayLink = screen.displayLinkWithTarget(self, selector: #selector(self.animationTick(_:)))
        displayLink?.paused = true
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func setScreen(screen:UIScreen?) {
        guard screen != nil else { return }
        guard displayLink != nil else { return }
        
        displayLink?.paused = true
        displayLink?.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        displayLink = screen!.displayLinkWithTarget(self, selector: #selector(self.animationTick(_:)))
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func addAnimation(animation:Animation?) {
        guard let animation = animation else {
            return
        }
        
        animations.addObject(animation)
        if animations.count == 1 {
            displayLink?.paused = false
        }
    }
    
    func removeAnimation(animation:Animation?) {
        guard let animation = animation else {
            return
        }
        
        animations.removeObject(animation)
        if animations.count == 0 {
            displayLink?.paused = true
        }
    }
    
    func animationTick(displayLink: CADisplayLink) {
        let dt = displayLink.duration
        for a in animations {
            let anim = a as! Animation
            anim.animationTick(dt)
        }
    }
}

extension UIView {
    func animator() -> Animator {
        return Animator.sharedInstance
    }
}

