//
//  ViewController.swift
//  BluetoothTest
//
//  Created by juntaek.oh on 2023/05/15.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    @IBOutlet weak var bluetoothIDLabel: UILabel!
    @IBOutlet weak var otherIDStackView: UIStackView!
    @IBOutlet weak var actionButton: UIButton!
    
    // MARK: Peripheral
    private var peripheralManager: CBPeripheralManager?
    private var service: CBMutableService?
    private var characteristic: CBMutableCharacteristic?
    
    private var serviceUUID: CBUUID?
    private var characteristicUUID: CBUUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureAttributes()
        self.configureIntializing()
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("State is unknown")
            
        case .resetting:
            print("State is resetting")
            
        case .unsupported:
            print("State is unsupported")
            
        case .unauthorized:
            print("State is unauthorized")
            
        case .poweredOff:
            print("State is poweredOff")
            
        case .poweredOn:
            print("State is poweredOn")
            
            self.addPeripheralService()
            
        @unknown default:
            print("State is ---")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            print("Get Error: \(error.localizedDescription)")
        }
        
        print("Start Advertising")
    }
}

private extension ViewController {
    
    func addPeripheralService() {
        guard let serviceUUID, let characteristicUUID else { return }
        
        self.service = .init(type: serviceUUID, primary: true)
        // 일단은 읽기만 가능한 형태로?
        self.characteristic = .init(type: characteristicUUID, properties: [.read], value: nil, permissions: [.readable])
        
        guard let service, let characteristic else { return }
        
        service.characteristics = [characteristic]
        self.peripheralManager?.add(service)
    }
}

private extension ViewController {
    
    func configureAttributes() {
        self.actionButton.layer.cornerRadius = 15
        self.bluetoothIDLabel.sizeToFit()
    }
    
    func configureIntializing() {
        self.peripheralManager = .init(delegate: self, queue: .global(qos: .background))
        self.serviceUUID = .init(nsuuid: .init())
        self.characteristicUUID = .init(nsuuid: .init())
    }
}
