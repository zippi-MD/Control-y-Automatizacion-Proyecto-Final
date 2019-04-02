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

class ViewController: UIViewController {
    
    @IBOutlet weak var xAngleLabel: UILabel!
    
    @IBOutlet weak var yAngleLabel: UILabel!
    
    
    let motionManager = CMMotionManager()
    
    var manager: CBCentralManager!
    var myBluetoothPeripheral: CBPeripheral!
    var myCharacteristic: CBCharacteristic!
    
    var isMyPeripheralConected = false
    
    var timer: Timer? = nil
    
    var angleXY: Int = 0
    var angleXZ: Int = 0
    var angleYZ: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CBCentralManager(delegate: self, queue: nil)
        startAccelerometerData()
        startTimer()
    }
    
    func startAccelerometerData(){
        motionManager.accelerometerUpdateInterval = 0.1
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!){
            [unowned self] (data, error) in
            
            if let accelerometerData = data {
                
                self.angleXY = Int(self.accelerationIntoDegrees(accelerometerData.acceleration.x, accelerometerData.acceleration.y))
                self.angleXZ = Int(self.accelerationIntoDegrees(accelerometerData.acceleration.x, accelerometerData.acceleration.z))
                self.angleYZ = Int(self.accelerationIntoDegrees(accelerometerData.acceleration.y, accelerometerData.acceleration.z))
                
                DispatchQueue.main.async {
                    self.xAngleLabel.text = "\(self.angleXY)"
                    self.yAngleLabel.text = "\(self.angleXZ)"
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
                                            timeInterval: 0.5,
                                            target: self,
                                            selector: #selector(sendData),
                                            userInfo: nil,
                                            repeats: true
                                        )
        }
    }
    
    
    @objc func sendData(){
        print("Some data")
        writeValue()
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
            let info = "\(abs(angleXY)):\(abs(angleXZ)))\n"
            dataToSend = info.data(using: String.Encoding.utf8)!
            
            if let characteristic = myCharacteristic {
                myBluetoothPeripheral.writeValue(dataToSend, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                print("Sended")
            }
        } else {
            print("Not connected")
        }
    }
    
    
    
    
}

