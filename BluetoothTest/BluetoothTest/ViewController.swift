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
    
    private var peripheralServiceUUID: CBUUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureAttributes()
        self.configureIntializing()
        self.configurePeripheralService()
    }
    
    @IBAction func tapButton(_ sender: UIButton) {
        self.startAdvertising()
    }
}

// Peripheral 관련 Delegate
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
        
        if let peripheralManager {
            let isRight = (peripheralManager === peripheral)
            print("Start Advertising: \(isRight)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        let sendString: String = "F-15K"
        let data: Data? = sendString.data(using: .utf8)
        
        if let data {
            self.sendDataToCentral(which: data, with: central)
        }
    }
}

// Central 관련 Delegate
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
            
            guard let peripheralServiceUUID else { return }
            
            let options = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            // 검색 중인 서비스의 UUID를 전달
            self.centralManager?.scanForPeripherals(withServices: [peripheralServiceUUID], options: options)
            
        @unknown default:
            print("State is ---")
        }
    }
    
    // 장치를 찾았을 때 실행되는 이벤트
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 신호 감도
        guard RSSI.intValue >= -50 else {
            print("Discovered perhiperal not in expected range, at \(RSSI.intValue)")
            return
        }
        
        guard peripheral.services?.first?.uuid.uuidString == peripheralServiceUUID?.uuidString else {
            print("Discovered perhiperal not equal service uuid, it is \(String(describing: peripheral.services?.first?.uuid.uuidString))")
            return
        }
        
        centralManager?.connect(peripheral, options: nil)
    }
    
    // 올바른 장치에 연결되었는지 확인
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected peripheral: \(peripheral.identifier.uuidString)")
    }
    
    // 연결된 peripheral에서 characteristic이 업데이트되었을 때
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristicData = characteristic.value, let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        if stringFromData.contains("F-15K") {
            DispatchQueue.main.async {
                let label: UILabel = .init()
                label.text = stringFromData
                label.font = .systemFont(ofSize: 15)
                label.sizeToFit()
                
                self.otherIDStackView.addArrangedSubview(label)
            }
        }
    }
}

private extension ViewController {
    
    func startAdvertising() {
        guard let peripheralServiceUUID else { return }
        
        self.peripheralManager?.startAdvertising([CBAdvertisementDataLocalNameKey: "푸코", CBAdvertisementDataServiceUUIDsKey: [peripheralServiceUUID]])
    }
    
    // 최초로 데이터를 보낼 때?? 새로 만드는 것도 이걸로 되려나??
    func sendDataToCentral(which stringData: Data, with subscribedCentral: CBCentral) {
        // 여러개의 이미지를 보내기 위해서는 이미지 별로 characteristic이 필요
        let characteristic = self.dataCharacteristics[0]
        characteristic.value = stringData
        
        peripheralManager?.updateValue(stringData, for: characteristic, onSubscribedCentrals: [subscribedCentral])
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
        self.peripheralServiceUUID = .init(string: "F00987F2-64A0-4127-8C46-594C45D36A63")
    }
    
    func configurePeripheralService() {
        guard let peripheralServiceUUID else { return }
        
        let uuid: UUID = .init()
        self.service = .init(type: peripheralServiceUUID, primary: true)
        let characteristic: CBMutableCharacteristic = .init(type: .init(nsuuid: uuid), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        self.characteristicsUUIDs = [uuid]
        
        self.dataCharacteristics = [characteristic]
        
        guard let service else { return }
        
        service.characteristics = dataCharacteristics
        self.peripheralManager?.add(service)
    }
}
