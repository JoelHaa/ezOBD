//
//  ContentView.swift
//  ezOBD
//
//  Created by Joel Haapaniemi on 4.12.2022.
//

import SwiftUI
import CoreBluetooth
import os
import UIKit


class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    private var placeholderPeripheral: CBPeripheral?
    private var connectedPeripheral: CBPeripheral?
    
    @Published var peripheralNames: [String] = []
    @Published var connected: Bool = false
    @Published var loadMainView: Bool = false
    @Published var connectedPeripheralName: String?
    
    // Data variables
    @Published var modelNumberString: String = ""
    @Published var obdData1: String = ""
    @Published var obdData2: String = ""
    
    // Characteristics UUIDs //These were intended for bluetooth communication
    let modelNumberStringCBUUID = CBUUID(string: "2A24")
    let manufacturerNameStringCBUUID = CBUUID(string: "2A29")
    let elmCodeNotifyCBUUID = CBUUID(string: "AE02")
    let obdData1CBUUID = CBUUID(string: "AE10")
    let obdData2CBUUID = CBUUID(string: "FFF1")
    

    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
   }
}

// This extension/function holds all the subfunctions that control bluetooth states
// and UI navigation/functionality, most likely not the proper way but I'm keeping
// it simple as this is my first SwiftUI project.
extension BluetoothViewModel: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private func ModelNumberString(from characteristic: CBCharacteristic) -> String {
        let unicodeString = String(data: characteristic.value!, encoding: String.Encoding.utf8) ?? "n/a"
        modelNumberString = unicodeString
        return unicodeString
    }
    
    private func obdData1(from characteristic: CBCharacteristic) -> String {
        let unicodeString = String(data: characteristic.value!, encoding: String.Encoding.utf8) ?? "n/a"
        obdData1 = unicodeString
        return unicodeString
    }
    
    private func obdData2(from characteristic: CBCharacteristic) -> String {
        let unicodeString = String(data: characteristic.value!, encoding: String.Encoding.utf8) ?? "n/a"
        obdData2 = unicodeString
        return unicodeString
    }
 
    // This function is triggered in the UI when the user has succesfully connected
    // to a bluetooth device, as of now doesn't work as I don't know
    // how I should format my http calls to the python obd2 elm327 emulator
    // running in my local network. The calls go through but only met with
    // with 'Invalid request'
    func sendOBD2Command(){
        let url = URL(string: "http://192.168.1.104:35000")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Request": "010C"
        ]
        
        print("Sent request: \(String(describing: request.allHTTPHeaderFields))")

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                print("Received data: \(data.description)")
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        task.resume()
    }



    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        switch characteristic.uuid {
            
            case modelNumberStringCBUUID:
                print(modelNumberStringCBUUID)
                modelNumberString = ModelNumberString(from: characteristic)
            case manufacturerNameStringCBUUID:
                print(manufacturerNameStringCBUUID)
            case obdData1CBUUID:
                print(obdData1CBUUID)
                obdData1 = obdData1(from: characteristic)
            case obdData2CBUUID:
                print(obdData2CBUUID)
                obdData2 = obdData2(from: characteristic)
                
          
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
    
    // Basic connect function, checks if selected device exists
    // and then tries to form a connection
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
    
    // Simple function to return to the main view
    func goToMainView(){
        connected = true
        loadMainView = true
        sendOBD2Command()
    }
    
    // Simple function for disconnecting from a bluetooth device
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
        modelNumberString = ""
    }
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to \(peripheral)")
        peripheral.delegate = self
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
            // method, but for the scale of this project, should do the trick, also calling
            // of functions is probably not meant to do as I did. This would need refactoring
            // in the future.
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
                            
                            Text("ModelNumber: \(bluetoothViewModel.modelNumberString )")
                                .padding(.all, 5)
                            
                            Text("OBD-Data1: \(bluetoothViewModel.obdData1 )")
                                .padding(.all, 5)
                            
                            Text("OBD-Data2: \(bluetoothViewModel.obdData2 )")
                                .padding(.all, 5)
                            
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
