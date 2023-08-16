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
    @Published var engineRPM: String = ""
    @Published var vehicleSpeed: String = ""
    
    // Characteristics UUIDs //These were intended for bluetooth communication
    let modelNumberStringCBUUID = CBUUID(string: "2A24")
    let manufacturerNameStringCBUUID = CBUUID(string: "2A29")
    let elmCodeNotifyCBUUID = CBUUID(string: "AE02")
    let engineRPMCBUUID = CBUUID(string: "AE10")
    let vehicleSpeedCBUUID = CBUUID(string: "FFF1")
    

    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
   }
}

 /*  This extension/function holds all the subfunctions that control bluetooth states
     and UI navigation/functionality, most likely not the proper way but I'm keeping
     it simple as this is my first SwiftUI project.
 */
extension BluetoothViewModel: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private func ModelNumberString(from characteristic: CBCharacteristic) -> String {
        let unicodeString = String(data: characteristic.value!, encoding: String.Encoding.utf8) ?? "n/a"
        modelNumberString = unicodeString
        return unicodeString
    }
    
    private func engineRPM(from characteristic: CBCharacteristic) -> String {
        let unicodeString = String(data: characteristic.value!, encoding: String.Encoding.utf8) ?? "n/a"
        engineRPM = unicodeString
        return unicodeString
    }
    
    private func vehicleSpeed(from characteristic: CBCharacteristic) -> String {
        let unicodeString = String(data: characteristic.value!, encoding: String.Encoding.utf8) ?? "n/a"
        vehicleSpeed = unicodeString
        return unicodeString
    }
 
    /*  This function is triggered in the UI when the user has succesfully connected
        to a bluetooth device, as of now doesn't work as I don't know
        how I should format my http calls to the python obd2 elm327 emulator
        running in my local network. The calls go through but only met with
        with 'Invalid request'.
        010C is the OBD2 PID for Engine RPM
        010D is the OBD2 PID for Vehicle Speed
     */
    func getEngineRPM()-> Int{
        var engineRPM = 0
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
        
        /*  Response conversion to decimal, the response should be a string
            as in 7E8 04 41 01 14 46, 7E8 is the header, 04 is the byte size and
            41 01 14 46 is the response, with 14 & 46 the values we need for the
            conversion to a decimal value.
         */
        var responseData: String = "7E804411446"
        
        let start = responseData.index(responseData.startIndex, offsetBy: 7)
        let end = responseData.index(responseData.endIndex, offsetBy: -2)
        let range = start..<end
         
        let hexByte1 = responseData[range]
        
        let start2 = responseData.index(responseData.startIndex, offsetBy: 9)
        let end2 = responseData.index(responseData.endIndex, offsetBy: 0)
        let range2 = start2..<end2
         
        let hexByte2 = responseData[range2]
        
        
        var decByte1 = Int(hexByte1, radix: 16)!
        var decByte2 = Int(hexByte2, radix: 16)!
        
        print("hexByte1 = \(hexByte1) decByte1 = \(decByte1)")
        print("hexByte2 = \(hexByte2) decByte2 = \(decByte2)")
        
        /*  Formula for getting the engine rpm ((256*A)+B))/4
            where A = decByte1 and B = decByte2
         */
        engineRPM = ((256*decByte1 + decByte2) / 4)
        
        print("EngineRPM = \(engineRPM)")
        
        task.resume()
        return engineRPM
    }
    
    func getVehicleSpeed()-> Int{
        var vehicleSpeed = 0
        let url = URL(string: "http://192.168.1.104:35000")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Request": "010D"
        ]
        
        print("Sent request: \(String(describing: request.allHTTPHeaderFields))")

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                print("Received data: \(data.description)")
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        
        /*  Response conversion to decimal, the response should be a string
            as in 7E8 03 41 0D 5C, 7E8 is the header, 03 is the byte size and
            41 0D 5C is the response, with 5C being the value we need for the
            conversion to a decimal value.
         */
        var responseData: String = "7E803410D5C"
        
        let start = responseData.index(responseData.startIndex, offsetBy: 9)
        let end = responseData.index(responseData.endIndex, offsetBy: 0)
        let range = start..<end
         
        let hexByte1 = responseData[range]
        
        var decByte1 = Int(hexByte1, radix: 16)!
        
        print("hexByte1 = \(hexByte1) decByte1 = \(decByte1)")
        
        /*  Formula for getting the vehicle speed is A
            where A = decByte1
         */
        vehicleSpeed = decByte1
        
        print("Vehicle speed = \(vehicleSpeed)")
        
        task.resume()
        return vehicleSpeed
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
            case engineRPMCBUUID:
                print(engineRPMCBUUID)
                engineRPM = engineRPM(from: characteristic)
            case vehicleSpeedCBUUID:
                print(vehicleSpeedCBUUID)
                vehicleSpeed = vehicleSpeed(from: characteristic)
          
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
    
    /*  Basic connect function, checks if selected device exists
        and then tries to form a connection
     */
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
        //getEngineRPM()
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
                
             /*  View is primarily controlled with an if clause stack, perhaps not the most eloquent
                 method, but for the scale of this project, should do the trick, also calling
                 of functions is probably not meant to do as I did. This would need refactoring
                 in the future.
             */
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
                            
                            /*
                            Text("Connected device: \(bluetoothViewModel.connectedPeripheralName ?? " ")")
                                .padding(.all, 20)
                                .font(.headline)
                             */
                        
                            // This is just for the sake of the demo
                            Text("Connected device: OBD2 Vehicle")
                                .padding(.all, 20)
                                .font(.headline)
                            
                            /* This was just to check if we can fetch data through
                            the bluetooth protocol
                             
                            Text("ModelNumber: \(bluetoothViewModel.modelNumberString )")
                                .padding(.all, 5)
                            */
                            
                            Text("Engine RPM: \(bluetoothViewModel.getEngineRPM() )")
                                .padding(.all, 5)
                            
                            Text("Vehicle Speed (km/h): \(bluetoothViewModel.getVehicleSpeed() )")
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
