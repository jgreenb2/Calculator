//
//  GraphViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource, UIGestureRecognizerDelegate {
    
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
        let panGraphRecognizer = UIPanGestureRecognizer(target: graphView, action: #selector(graphView.moveOrigin(_:)))
        graphView.addGestureRecognizer(panGraphRecognizer)
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(graphView.scaleGraph(_:))))
        let tapRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(graphView.jumpToOrigin(_:)))
        tapRecognizer.numberOfTapsRequired = 2
        graphView.addGestureRecognizer(tapRecognizer)
        
        // set the animator that implements inertial scrolling to use the screen
        // associated with the graphView
        graphView.animator().setScreen(graphView.window?.screen)
        
        // you can reveal the master view by swiping from the left edge...
        if let svc = splitViewController as? GlobalUISplitViewController {
            swipeFromLeftEdge = UIScreenEdgePanGestureRecognizer(target: svc, action: #selector(svc.showMaster))
            swipeFromLeftEdge.edges = .Left
            graphView.addGestureRecognizer(swipeFromLeftEdge)
        }
        
        // ...or by using the bar button
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
                
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        graphView.cancelAnimation()
    }
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
        }
    }
        
    func functionValue(sender: GraphView, atXEquals: Double) -> Double? {
        if let result = graphBrain.setVariable("M", value: atXEquals) {
            if result.isNormal || result.isZero {
                return result
            }
        }
        return nil
    }
    
    func programSet() -> Bool {
        let p = graphBrain.program as! [String]
        return p.count > 0
    }
}
