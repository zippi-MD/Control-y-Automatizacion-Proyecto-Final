//
//  ViewController.swift
//  Control-Gimbald
//
//  Created by Alejandro Mendoza on 3/11/19.
//  Copyright © 2019 Alejandro Mendoza. All rights reserved.
//

import UIKit
import CoreMotion
import CoreBluetooth

enum controlState {
    case controlling, changing
}

class ViewController: UIViewController {
    
    @IBOutlet weak var xAngleLabel: UILabel!
    
    @IBOutlet weak var yAngleLabel: UILabel!
    
    @IBOutlet weak var changeValueButton: UIButton!
    @IBOutlet weak var variablesView: UIView!
    
    var appState: controlState = .controlling
    
//    First Axis Stepper
    
    @IBOutlet weak var firstAxisKpValueLabel: UILabel!
    @IBOutlet weak var firstAxisKiValueLabel: UILabel!
    @IBOutlet weak var firstAxisKdValueLabel: UILabel!
    
    @IBOutlet weak var firstAxisKpStepper: UIStepper!
    @IBOutlet weak var firstAxisKiStepper: UIStepper!
    @IBOutlet weak var firstAxisKdStepper: UIStepper!
    
    
    
//    Second Axis Stepper
    
    @IBOutlet weak var secondAxisKpValueLabel: UILabel!
    @IBOutlet weak var secondAxisKiValueLabel: UILabel!
    @IBOutlet weak var secondAxiskdValueLabel: UILabel!
    
    @IBOutlet weak var secondAxisKpStepper: UIStepper!
    @IBOutlet weak var secondAxisKiStepper: UIStepper!
    @IBOutlet weak var secondAxisKdStepper: UIStepper!
    
    
    
    
    let motionManager = CMMotionManager()
    var manager: CBCentralManager!
    
    var myBluetoothPeripheral: CBPeripheral!
    var myCharacteristic: CBCharacteristic!
    
    var isMyPeripheralConected = false
    
    var timer: Timer? = nil
    
    var angleXY: Int = 0
    var angleXZ: Int = 0
    var angleYZ: Int = 0
    
    
    //PID
    
    var readTime = 0.05
    
    //First Axis
    
    var desiredValueFirstAxis: Int = 90
    var actualValueFirstAxis: Int = 0
    
    var positionForFirstAxis: Int = 90
    
    var kpFirstAxis = 0.209 {
        willSet {
            firstAxisKpValueLabel.text = "kp: \(newValue)"
        }
    }
    var kiFirstAxis = 0.01 {
        willSet {
            firstAxisKiValueLabel.text = "ki: \(newValue)"
        }
    }
    var kdFirstAxis = 0.005 {
        willSet {
            firstAxisKdValueLabel.text = "kd: \(newValue)"
        }
    }
    
    var integralErrorFirstAxis = 0
    
    var actualErrorFirstAxis = 0.0
    var oldErrorFirstAxis = 0.0
    
    
    // Proporcional -- Kp
    
    func getProportionalValueFirstAxis() -> Double {
        return kpFirstAxis * Double(desiredValueFirstAxis - actualValueFirstAxis)
    }
    
    
    // Integral -- Ki
    
    func getIntegralValueFirstAxis() -> Double {
        integralErrorFirstAxis += desiredValueFirstAxis - actualValueFirstAxis
        return kiFirstAxis * Double(integralErrorFirstAxis) * readTime
    }
    
    
    // Derivative -- kd
    
    func getDerivativeValueFirstAxis() -> Double {
        oldErrorFirstAxis = actualErrorFirstAxis
        actualErrorFirstAxis = Double(desiredValueFirstAxis - actualValueFirstAxis)
        let derivativeError = actualErrorFirstAxis - oldErrorFirstAxis
        return kdFirstAxis * (derivativeError / readTime)
    }
    
    
    
    //Second Axis
    
    var desiredValueSecondAxis: Int = 90
    var actualValueSecondAxis: Int = 0
    
    var positionForSecondAxis: Int = 90
    var actualPositionForSecondAxis: Int = 90
    
    var kpSecondAxis = 0.209 {
        willSet {
            secondAxisKpValueLabel.text = "kp: \(newValue)"
        }
    }
    var kiSecondAxis = 0.05 {
        willSet {
            secondAxisKiValueLabel.text = "ki: \(newValue)"
        }
    }
    var kdSecondAxis = 0.007 {
        willSet {
            secondAxiskdValueLabel.text = "kd: \(newValue)"
        }
    }
    
    var integralErrorSecondAxis = 0
    
    var actualErrorSecondAxis = 0.0
    var oldErrorSecondAxis = 0.0
    
    
    // Proporcional -- Kp
    
    func getProportionalValueSecondAxis() -> Double {
        return kpSecondAxis * Double(desiredValueSecondAxis - actualValueSecondAxis)
    }
    
    
    // Integral -- Ki
    
    func getIntegralValueSecondAxis() -> Double {
        integralErrorSecondAxis += desiredValueSecondAxis - actualValueSecondAxis
        return kiSecondAxis * Double(integralErrorSecondAxis) * readTime
    }
    
    
    // Derivative -- kd
    
    func getDerivativeValueSecondAxis() -> Double {
        oldErrorSecondAxis = actualErrorSecondAxis
        actualErrorSecondAxis = Double(desiredValueSecondAxis - actualValueSecondAxis)
        let derivativeError = actualErrorSecondAxis - oldErrorSecondAxis
        return kdSecondAxis * (derivativeError / readTime)
    }
    
    
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        manager = CBCentralManager(delegate: self, queue: nil)
        
        setUpSteppers()
        startAccelerometerData()
        startTimer()
    }
    
    
    func setUpSteppers(){
        //First Axis
        firstAxisKpValueLabel.text = "kp: \(kpFirstAxis)"
        firstAxisKiValueLabel.text = "ki: \(kiFirstAxis)"
        firstAxisKdValueLabel.text = "kd: \(kdFirstAxis)"
        
        firstAxisKpStepper.value = kpFirstAxis
        firstAxisKiStepper.value = kiFirstAxis
        firstAxisKdStepper.value = kdFirstAxis
        
        //Second Axis
        secondAxisKpValueLabel.text = "kp: \(kpSecondAxis)"
        secondAxisKiValueLabel.text = "ki: \(kiSecondAxis)"
        secondAxiskdValueLabel.text = "kd: \(kdSecondAxis)"
        
        secondAxisKpStepper.value = kpSecondAxis
        secondAxisKiStepper.value = kiSecondAxis
        secondAxisKdStepper.value = kdSecondAxis
        
        
    }
    
    func startAccelerometerData(){
        motionManager.accelerometerUpdateInterval = 0.05
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){
            [unowned self] (data, error) in
            
            if let accelerometerData = data {
                
                self.angleXY = Int(self.accelerationIntoDegrees(accelerometerData.acceleration.x, accelerometerData.acceleration.y))
                self.angleXZ = Int(self.accelerationIntoDegrees(accelerometerData.acceleration.x, accelerometerData.acceleration.z))
                self.angleYZ = Int(self.accelerationIntoDegrees(accelerometerData.acceleration.y, accelerometerData.acceleration.z))
                
                DispatchQueue.main.async {
                    self.actualValueSecondAxis = abs(self.angleXY)
                    self.xAngleLabel.text = "\(self.actualValueSecondAxis)"
                    
                    self.actualValueFirstAxis = abs(self.angleXZ)
                    self.yAngleLabel.text = "\(self.actualValueFirstAxis)"
                }
                
            }
        }
    }
    
    
    func accelerationIntoDegrees(_ axis1Acceleration: Double, _ axis2Acceleration: Double) -> Double{
        let angle = atan2(axis1Acceleration, axis2Acceleration)
        return (angle * 180/Double.pi)
    }
    
    func startTimer(){
        if timer == nil {
            timer = Timer.scheduledTimer(
                                            timeInterval: readTime,
                                            target: self,
                                            selector: #selector(sendData),
                                            userInfo: nil,
                                            repeats: true
                                        )
        }
    }
    
    
    @objc func sendData(){
        
        
        
        let pidValueFirstAxis = Int(getProportionalValueFirstAxis() + getIntegralValueFirstAxis() + getDerivativeValueFirstAxis())
        
        let newValueFirstAxis = positionForFirstAxis - pidValueFirstAxis
        
        
        if newValueFirstAxis > 0 && newValueFirstAxis < 180 {
            positionForFirstAxis = newValueFirstAxis
        }
        
        
        
        let pidValueSecondAxis = Int(getProportionalValueSecondAxis() + getIntegralValueSecondAxis() + getDerivativeValueSecondAxis())
        
        let newValueSecondAxis = positionForSecondAxis - pidValueSecondAxis
        
        if newValueSecondAxis > 0 && newValueSecondAxis < 180 {
            positionForSecondAxis = newValueSecondAxis
        }
       
        actualPositionForSecondAxis = (positionForSecondAxis * 90) / 110
        
        
        writeValue()
    }
    
    
    @IBAction func changedFirstAxisPIDValue(_ sender: UIStepper) {
        
        integralErrorFirstAxis = 0
        actualErrorFirstAxis = 0.0
        oldErrorFirstAxis = 0.0
        
        switch sender.tag {
        case 0:
            kpFirstAxis = sender.value
        case 1:
            kiFirstAxis = sender.value
        case 2:
            kdFirstAxis = sender.value
        default:
            return
        }
        
    }
    
    
    @IBAction func changedSecondAxisPIDValue(_ sender: UIStepper) {
        
        integralErrorSecondAxis = 0
        actualErrorSecondAxis = 0.0
        oldErrorSecondAxis = 0.0
        
        switch sender.tag {
        case 0:
            kpSecondAxis = sender.value
        case 1:
            kiSecondAxis = sender.value
        case 2:
            print(sender.value)
            kdSecondAxis = sender.value
        default:
            return
        }
        
    }
    
    @IBAction func changeValue(_ sender: Any) {
        
        if appState == .controlling {
            
            appState = .changing
            
            variablesView.isHidden = false
            changeValueButton.setTitle("Start", for: .normal)
            
            timer?.invalidate()
            timer = nil
            
            integralErrorFirstAxis = 0
            actualErrorFirstAxis = 0.0
            oldErrorFirstAxis = 0.0
            
            integralErrorSecondAxis = 0
            actualErrorSecondAxis = 0.0
            oldErrorSecondAxis = 0.0
        }
        
        else if appState == .changing {
            appState = .controlling
            
            changeValueButton.setTitle("Stop", for: .normal)
            variablesView.isHidden = false
            
            startTimer()
        }
        
        
        
    }
    


}

extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var msg = ""
        
        switch central.state {
            
        case .poweredOff:
            msg = "Bluetooth is Off"
        case .poweredOn:
            msg = "Bluetooth is On"
            manager.scanForPeripherals(withServices: nil, options: nil)
        case .unsupported:
            msg = "Not Supported"
        default:
            msg = "😔"
            
        }
        
        print("STATE: " + msg)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Name: \(peripheral.name)")
        
        if peripheral.name == "BT05" {
            
            self.myBluetoothPeripheral = peripheral
            self.myBluetoothPeripheral.delegate = self
            
            manager.stopScan()
            manager.connect(myBluetoothPeripheral, options: nil)
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isMyPeripheralConected = true
        print("Conectado correctamente con: \(peripheral.name ?? "no tiene nombre...")")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isMyPeripheralConected = false
        print("Se perdió la conexión con el dispositivo")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let servicePeripheral = peripheral.services as [CBService]! {
            
            for service in servicePeripheral {
                
                peripheral.discoverCharacteristics(nil, for: service)
                
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let characterArray = service.characteristics as [CBCharacteristic]! {
            
            for cc in characterArray {
                
                if(cc.uuid.uuidString == "FFE1") {
                    
                    myCharacteristic = cc
                    
                    peripheral.readValue(for: cc)
                }
                
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if (characteristic.uuid.uuidString == "FFE1") {
            
            let readValue = characteristic.value
            
            let value = (readValue! as NSData).bytes.bindMemory(to: Int.self, capacity: readValue!.count).pointee
            
            print (value)
        }
    }
    
    
    func writeValue() {
        
        if isMyPeripheralConected {
            var dataToSend: Data
            //angleXY
            let info = "\(abs(actualPositionForSecondAxis)):\(abs(positionForFirstAxis))\n"
            dataToSend = info.data(using: String.Encoding.utf8)!
            
            if let characteristic = myCharacteristic {
                myBluetoothPeripheral.writeValue(dataToSend, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
            }
        } else {
            print("Not connected")
        }
    }
    
    
    
    
    
}

