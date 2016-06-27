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
//  Animator is a Singleton that encapsulates iOS's CADisplayLink timer. It allows
//  any class or type conforming to the Animation protocol to be called at the screen
//  refresh frequency.
//
import UIKit

protocol Animation {
    func animationTick(tickDelta:CFTimeInterval)
    var animationIdentifier:String { get }
    
}

class Animator {
    var displayLink:CADisplayLink?
    var animations=[String:Animation]()

    static let sharedInstance: Animator = {
        let instance = Animator(screen: UIScreen.main())
        return instance
    }()
    
    
    private init(screen:UIScreen) {
        setDisplayLink(screen: screen)
    }
    
    func set(screen:UIScreen?) {
        guard let screen = screen else { return }
        guard let displayLink = displayLink else { return }
        
        displayLink.isPaused = true
        displayLink.remove(from: RunLoop.main(), forMode: RunLoopMode.commonModes.rawValue)
        setDisplayLink(screen: screen)
    }
    
    private func setDisplayLink(screen:UIScreen) {
        displayLink = screen.displayLink(withTarget: self, selector: #selector(self.animationTick(_:)))
        displayLink?.isPaused = true
        displayLink?.add(to: RunLoop.main(), forMode: RunLoopMode.commonModes.rawValue)
    }
    
    func add(animation:Animation?) {
        guard let animation = animation else { return }
        guard animations.index(forKey: animation.animationIdentifier) == nil else { return }

        animations[animation.animationIdentifier] = animation
        if animations.count == 1 {
            displayLink?.isPaused = false
        }
    }
    
    func remove(animation:Animation?) {
        guard let animation = animation else { return }
        
        animations.removeValue(forKey: animation.animationIdentifier)
        if animations.count == 0 {
            displayLink?.isPaused = true
        }
    }
    
    @objc func animationTick(_ displayLink: CADisplayLink) {
        let dt = displayLink.duration
        for (_, anim) in animations {
            anim.animationTick(tickDelta: dt)
        }
    }
}

extension UIView {
    func animator() -> Animator {
        return Animator.sharedInstance
    }
}

