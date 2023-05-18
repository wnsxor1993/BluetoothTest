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
    
    // MARK: Central
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var connectedPeripheral: CBPeripheral?
    
    // MARK: Peripheral
    private var peripheralManager: CBPeripheralManager?
    private var service: CBMutableService?
    private var dataCharacteristics: [CBMutableCharacteristic] = []
    private var characteristicsUUIDs: [UUID] = []
    
    private var serviceUUID: CBUUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureAttributes()
        self.configureIntializing()
    }
    
    @IBAction func tapButton(_ sender: UIButton) {
        self.addPeripheralService()
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("Peripheral State is unknown")
            
        case .resetting:
            print("Peripheral State is resetting")
            
        case .unsupported:
            print("Peripheral State is unsupported")
            
        case .unauthorized:
            print("Peripheral State is unauthorized")
            
        case .poweredOff:
            print("Peripheral State is poweredOff")
            
        case .poweredOn:
            print("Peripheral State is poweredOn")
            
        @unknown default:
            print("State is ---")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            print("Get Error: \(error.localizedDescription)")
        }
        
        print("Start Advertising")
        self.peripheralManager?.startAdvertising([CBAdvertisementDataLocalNameKey: "푸코", CBAdvertisementDataServiceUUIDsKey: "F00987F2-64A0-4127-8C46-594C45D36A63"])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        let data: Data = .init()
        self.sendDataToCentral(which: data, with: central)
    }
}

extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Central State is unknown")
            
        case .resetting:
            print("Central State is resetting")
            
        case .unsupported:
            print("Central State is unsupported")
            
        case .unauthorized:
            print("Central State is unauthorized")
            
        case .poweredOff:
            print("Central State is poweredOff")
            
        case .poweredOn:
            print("Central State is poweredOn")
            
            guard let serviceUUID else { return }
            
            let options = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            self.centralManager?.scanForPeripherals(withServices: [serviceUUID], options: options)
            
        @unknown default:
            print("State is ---")
        }
    }
    
    //장치를 찾았을 때 실행되는 이벤트
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Name: \(advertisementData[CBAdvertisementDataLocalNameKey]), ID: \(advertisementData[CBAdvertisementDataServiceUUIDsKey])")
    }
    
    //올바른 장치에 연결되었는지 확인
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
    }
    
    //
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
    }
}

private extension ViewController {
    
    func addPeripheralService() {
        guard let serviceUUID else { return }
        
        let uuid: UUID = .init()
        self.service = .init(type: serviceUUID, primary: true)
        let characteristic: CBMutableCharacteristic = .init(type: .init(nsuuid: uuid), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        self.characteristicsUUIDs = [uuid]
        
        self.dataCharacteristics = [characteristic]
        
        guard let service else { return }
        
        service.characteristics = dataCharacteristics
        self.peripheralManager?.add(service)
    }
    
    // 최초로 데이터를 보낼 때
    func sendDataToCentral(which imageData: Data, with subscribedCentral: CBCentral) {
        guard subscribedCentral.identifier.uuidString == "43637A62-FDFF-48F3-8816-F6B141DE7FC9" else {
            print("Error: Subscribed UUID is \(subscribedCentral.identifier.uuidString)")
            
            return
        }
        
        // 여러개의 이미지를 보내기 위해서는 이미지 별로 characteristic이 필요
        let characteristic = self.dataCharacteristics[0]
        characteristic.value = imageData
        
        peripheralManager?.updateValue(imageData, for: characteristic, onSubscribedCentrals: [subscribedCentral])
    }
}

private extension ViewController {
    
    func configureAttributes() {
        self.actionButton.layer.cornerRadius = 15
        self.bluetoothIDLabel.sizeToFit()
    }
    
    func configureIntializing() {
        self.centralManager = .init(delegate: self, queue: .global(qos: .background))
        self.peripheralManager = .init(delegate: self, queue: .global(qos: .background))
        self.serviceUUID = .init(string: "F00987F2-64A0-4127-8C46-594C45D36A63")
    }
}
