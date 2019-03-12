//
//  ViewController.swift
//  Control-Gimbald
//
//  Created by Alejandro Mendoza on 3/11/19.
//  Copyright © 2019 Alejandro Mendoza. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    @IBOutlet weak var xAngleLabel: UILabel!
    
    @IBOutlet weak var yAngleLabel: UILabel!
    
    @IBOutlet weak var zAngleLabel: UILabel!
    
    
    let motionManager = CMMotionManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        startAccelerometerData()
    }
    
    func startAccelerometerData(){
        motionManager.accelerometerUpdateInterval = 0.1
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){
            [unowned self] (data, error) in
            
            if let accelerometerData = data {
                
                self.xAngleLabel.text = "-> \(self.accelerationIntoDegrees(accelerometerData.acceleration.x, accelerometerData.acceleration.y))"
                self.yAngleLabel.text = "-> \(self.accelerationIntoDegrees(accelerometerData.acceleration.x, accelerometerData.acceleration.z))"
                self.zAngleLabel.text = "\(self.accelerationIntoDegrees(accelerometerData.acceleration.y, accelerometerData.acceleration.z))"
            }
        }
    }
    
    
    func accelerationIntoDegrees(_ axis1Acceleration: Double, _ axis2Acceleration: Double) -> Double{
        let angle = atan2(axis1Acceleration, axis2Acceleration)
        return (angle * 180/Double.pi)
    }


}

