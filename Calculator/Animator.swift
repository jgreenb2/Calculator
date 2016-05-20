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
    func animationTick(dt:CFTimeInterval, inout finished:Bool)
}

class Animator: NSObject {
    var displayLink:CADisplayLink?
    var animations=NSMutableSet()

    static let sharedInstance: Animator = {
        let screen = UIScreen.mainScreen()
        let instance = Animator(screen: screen)
        return instance
    }()
    
    
    init(screen:UIScreen) {
        super.init()
        displayLink = screen.displayLinkWithTarget(self, selector: #selector(self.animationTick(_:)))
        displayLink?.paused = true
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
            var isFinished = false
            anim.animationTick(dt, finished: &isFinished)
        }
    }
}

extension UIView {
    func animator() -> Animator {
        return Animator.sharedInstance
    }
}

