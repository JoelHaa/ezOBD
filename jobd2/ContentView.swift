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
    private var connectedPeripheral: CBPeripheral?
    @Published var connected: Bool = false
    @Published var connectedPeripheralName: String?
    let macbookName = CBUUID(string: "2A24")
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
   }
}

extension BluetoothViewModel: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
      switch characteristic.uuid {
        case macbookName:
          print(characteristic.value ?? "no value")
        default:
          print("Unhandled Characteristic UUID: \(characteristic.uuid)")
      }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("The services of the connected device: \(peripheral.services?.description ?? "no services available")")
        discoverCharacteristics(peripheral: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
      guard let characteristics = service.characteristics else { return }

      for characteristic in characteristics {
          print(characteristic)
          if characteristic.properties.contains(.read) {
            print("\(characteristic.uuid): properties contains .read")
            peripheral.readValue(for: characteristic)
          }
          if characteristic.properties.contains(.notify) {
            print("\(characteristic.uuid): properties contains .notify")
          }
      }
    }
    
    func discoverCharacteristics(peripheral: CBPeripheral) {
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func connect(selection: String){
        if selection == "no device" {
            return
        }
        print("Current selection = \(selection)")
        guard let selectedDevice = peripherals.first(where:  {$0.name == selection}) else {
            print("Could not find selected device")
            return
        }
        print("Trying to connect to \(selectedDevice)")
        self.centralManager?.connect(selectedDevice, options: nil)
    }
    
    func disconnect(selection: String){
        if selection == "no device" {
            return
        }
        print("Current selection = \(selection)")
        guard let selectedDevice = peripherals.first(where:  {$0.name == selection}) else {
            print("Could not find selected device")
            return
        }
        print("Trying to disconnect from \(selectedDevice)")
        self.centralManager?.cancelPeripheralConnection(selectedDevice)
        connected = false
    }
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to \(peripheral)")
        peripheral.delegate = self // set the delegate property to self
        peripheral.discoverServices(nil)
        connectedPeripheral = peripheral
        connectedPeripheralName = connectedPeripheral?.name
        self.centralManager?.stopScan()
        connected = true
        
        print("CONNECTED = \(self.connected)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber){
        if !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)
            if let name = peripheral.name, !name.isEmpty && name != "unknown" {
                self.peripheralNames.append(name)
            }
        }
    }
}

struct ContentView: View {
    
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    @State private var selection : String?

        
        func connect(){
            return
        }

        
            var body: some View {
                
                
            NavigationView {
                
                    
                    VStack{
                        
                        
                        
                        if(bluetoothViewModel.connected == true){
                            Text("Connected to \(bluetoothViewModel.connectedPeripheralName ?? " ")").padding(.all, 20)
                            
                            Button("Disconnect"){
                                var _ = bluetoothViewModel.disconnect(selection: bluetoothViewModel.connectedPeripheralName ?? "no device")
                                
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.all, 5)
                            
                        
                        }else{
                            
                            List(bluetoothViewModel.peripheralNames, id: \.self, selection: $selection) { peripheral in
                                Text(peripheral)
                            }
                            .navigationTitle("Bluetooth devices")
                            
                            Button("Connect"){
                                var _ = bluetoothViewModel.connect(selection: selection ?? "no device")
                                
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.all, 5)
                            
                            Text("\(selection ?? "No bluetooth device selected")").padding(.all, 20)
                            
                            
                            
                            
                        }
                        
                            
                    }
                
                        
                }
                
                
            }
                
                
                    
                }
                
                            
            

        
        struct ContentView_Previews: PreviewProvider {
            static var previews: some View {
                ContentView()
            }
        }
