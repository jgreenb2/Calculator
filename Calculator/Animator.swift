//
//  Animator.swift
//  Calculator
//
//  Created by Jeff Greenberg on 5/19/16.
//  Copyright © 2016 Jeff Greenberg. All rights reserved.
//
//  Based on objective-C Animator example at
//  http://www.objc.io (see chapter 12, "implementing animations")
//
//  Switching from NSMutableSet to Swift Set sends us down a Protocol
//  Oriented Programming rabbit hole. We avoid it by using a Dictionary instead.
//
import UIKit

protocol Animation {
    func animationTick(dt:CFTimeInterval)
    var animationIdentifier:String { get }
    
}

class Animator {
    var displayLink:CADisplayLink?
    var animations=[String:Animation]()

    static let sharedInstance: Animator = {
        let instance = Animator(screen: UIScreen.mainScreen())
        return instance
    }()
    
    
    init(screen:UIScreen) {
        setDisplayLinkScreen(screen)
    }
    
    func setScreen(screen:UIScreen?) {
        guard let screen = screen else { return }
        guard let displayLink = displayLink else { return }
        
        displayLink.paused = true
        displayLink.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        setDisplayLinkScreen(screen)
    }
    
    func setDisplayLinkScreen(screen:UIScreen) {
        displayLink = screen.displayLinkWithTarget(self, selector: #selector(self.animationTick(_:)))
        displayLink?.paused = true
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func addAnimation(animation:Animation?) {
        guard let animation = animation else { return }
        guard animations.indexForKey(animation.animationIdentifier) == nil else { return }

        animations[animation.animationIdentifier] = animation
        if animations.count == 1 {
            displayLink?.paused = false
        }
    }
    
    func removeAnimation(animation:Animation?) {
        guard let animation = animation else { return }
        
        animations.removeValueForKey(animation.animationIdentifier)
        if animations.count == 0 {
            displayLink?.paused = true
        }
    }
    
    @objc func animationTick(displayLink: CADisplayLink) {
        let dt = displayLink.duration
        for (_, anim) in animations {
            anim.animationTick(dt)
        }
    }
}

extension UIView {
    func animator() -> Animator {
        return Animator.sharedInstance
    }
}

