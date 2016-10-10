//
//  GraphViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    var graphBrain = CalculatorBrain()
    var panGraphRecognizer:UIPanGestureRecognizer?
    var swipeFromLeftEdge:UIScreenEdgePanGestureRecognizer!
    
    // reset the origin on a layout change
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        graphView.graphOrigin = nil
    }
    
    override func viewDidLoad() {
        // add pan, pinch and tap recognizers
        let panGraphRecognizer = UIPanGestureRecognizer(target: graphView, action: #selector(graphView.moveOrigin(byGesture:)))
        graphView.addGestureRecognizer(panGraphRecognizer)
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(graphView.scaleGraph(byGesture:))))
        let tapRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(graphView.jumpToOrigin(byGesture:)))
        tapRecognizer.numberOfTapsRequired = 2
        graphView.addGestureRecognizer(tapRecognizer)
        
        // set the animator that implements inertial scrolling to use the screen
        // associated with the graphView
        graphView.animator().set(screen: graphView.window?.screen)
        
        navigationController?.delegate = self
        super.viewDidLoad()
    }
    
    // if we have just segued to the graphView, then mark the current graphView plotData as invalid
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is GraphViewController {
            graphView.plotData.stale = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        graphView.cancelAnimation()
    }
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
        }
    }
        
    func functionValue(atXEquals x: Double) -> Double? {
        if let result = graphBrain.set(variableName: "M", toValue: x) {
            if result.isNormal || result.isZero {
                return result
            }
        }
        return nil
    }
    
    func programIsSet() -> Bool {
        let p = graphBrain.program as! [String]
        return p.count > 0
    }
}
