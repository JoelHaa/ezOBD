//
//  ContentView.swift
//  ezOBD
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
    @Published var loadMainView: Bool = false
    @Published var connectedPeripheralName: String?
    
    // Characteristics UUIDs
    let modelNumberString = CBUUID(string: "2A24")
    let manufacturerNameString = CBUUID(string: "2A29")
    let elmCodeNotify = CBUUID(string: "AE02")
    let elmCodeRead = CBUUID(string: "AE10")
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
   }
}

extension BluetoothViewModel: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private func ModelNumberString(from characteristic: CBCharacteristic) -> String {
      guard let characteristicData = characteristic.value,
        let byte = characteristicData.first else { return "Error" }

      // Trying to parse the returning data
      switch byte {
        case 0: return "2"
        case 1: return "J"
        case 2: return "C"
        case 3: return "I"
        case 4: return "E"
        case 5: return "-"
        case 6: return "B"
        case 7: return "L"
        case 8: return "0"
        case 9: return "1"
        default:
          return "Reserved for future use"
      }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
      switch characteristic.uuid {
        case modelNumberString:
          let macbookModelString = ModelNumberString(from: characteristic)
          print(macbookModelString)
      case manufacturerNameString:
          print(manufacturerNameString)
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
            peripheral.setNotifyValue(true, for: characteristic)
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
    
    func goToMainView(){
        connected = true
        loadMainView = true
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
        loadMainView = false
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

// This is the main view
struct ContentView: View {
    
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    @State private var selection : String?
    
    @State private var showingAlert = false

        
        func connect(){
            return
        }

        
            var body: some View {
                
            // View is primarily controlled with an if clause stack, perhaps not the most eloquent
            // method, but for the scale of this project, should do the trick
            NavigationView {
                
                    
                    VStack{
                        
                        
                        // The View to confirm bluetooth device connection and to allow disconnection
                        if(bluetoothViewModel.connected == true && bluetoothViewModel.loadMainView == false){
                            Text("Connected to \(bluetoothViewModel.connectedPeripheralName ?? " ")").padding(.all, 20)
                            
                            Button("Disconnect"){
                                showingAlert = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .padding(.all, 5)
                            .alert("Are you sure you want to disconnect?", isPresented: $showingAlert) {
                                Button("Yes", role: .cancel) {
                                    var _ = bluetoothViewModel.disconnect(selection: bluetoothViewModel.connectedPeripheralName ?? "no device")
                                }
                                
                            }
                            
                            Button("Continue"){
                                var _ = bluetoothViewModel.goToMainView()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.all, 5)
                            
                        // The view after a connection to a device has been made
                        }else if(bluetoothViewModel.loadMainView == true && bluetoothViewModel.connected == true){
                            
                            Text("Connected device: \(bluetoothViewModel.connectedPeripheralName ?? " ")")
                                .padding(.all, 20)
                                .font(.headline)
                            
                            Button("Disconnect"){
                                showingAlert = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .padding(.all, 5)
                            .alert("Are you sure you want to disconnect?", isPresented: $showingAlert) {
                                Button("Yes", role: .cancel) {
                                    var _ = bluetoothViewModel.disconnect(selection: bluetoothViewModel.connectedPeripheralName ?? "no device")
                                }
                                
                            }
                            
                        }
                        
    
                        // The default view when the application is run
                        else{
                            
                            Text("Bluetooth devices")
                                .padding(.all, 20)
                                .font(.headline)
                            
                            List(bluetoothViewModel.peripheralNames, id: \.self, selection: $selection) { peripheral in
                                Text(peripheral)
                            }
                            
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
