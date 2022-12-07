//
//  ContentView.swift
//  jobd2
//
//  Created by Joel Haapaniemi on 4.12.2022.
//

import SwiftUI
import CoreBluetooth
import os


class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    private var placeholderPeripheral: CBPeripheral?
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
    category: "Log")
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func connect(selection: String){
        if selection == nil ?? "no device"{
            logger.log("No device for connection")
        }
        else{
            logger.log("Current selection = \(selection)")
            var selectedDevice: CBPeripheral
            selectedDevice = peripherals.first(where:  {$0.name == selection}) ?? placeholderPeripheral!
            logger.log("Trying to connect to \(selectedDevice)")
            centralManager!.connect(selectedDevice)
            
        }
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.log("connected to \(peripheral)")
        centralManager?.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.log("Disconnected from \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber){
        if !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)
            self.peripheralNames.append(peripheral.name ?? "unnamed device")
            let unnamed : [String] = ["unnamed device"]
            self.peripheralNames.removeAll(where: { unnamed.contains($0)})
        }
        
        
    }
    
}

struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    
    @State private var selection : String?
    
    @StateObject fileprivate var selectedDevice = BluetoothViewModel()
    
    
        var body: some View {
        NavigationView {
            VStack {
                List(bluetoothViewModel.peripheralNames, id: \.self, selection: $selection) { peripheral in
                    Text(peripheral)
                }
                Text("\(selection ?? "No bluetooth device selected")").padding([.top, .leading, .bottom], 20)
                    var _ = bluetoothViewModel.connect(selection: selection ?? "no device")
            }
            .navigationTitle("Bluetooth devices")
            .toolbar {
                EditButton()
            }
                
            }
            
        }
                        
        }

    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
