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
    private var connectedPeripheral: CBPeripheral?
    @Published var connected: Bool = false
    @Published var connectedPeripheralName: String?
    
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
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.log("Discovered services")
    }
    
    func connect(selection: String){
        if selection == nil ?? "no device"{
        }
        else{
            logger.log("Current selection = \(selection)")
            var selectedDevice: CBPeripheral
            selectedDevice = peripherals.first(where:  {$0.name == selection}) ?? placeholderPeripheral!
            logger.log("Trying to connect to \(selectedDevice)")
            centralManager?.connect(selectedDevice, options: nil)
            
        }
        
        
    }
    
    func disconnect(selection: String){
        if selection == nil ?? "no device"{
        }
        else{
            logger.log("Current selection = \(selection)")
            var selectedDevice: CBPeripheral
            selectedDevice = peripherals.first(where:  {$0.name == selection}) ?? placeholderPeripheral!
            logger.log("Trying to disconnect from \(selectedDevice)")
            centralManager?.cancelPeripheralConnection(selectedDevice)
            connected = false
            
        }    }
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.log("Failed to connect to \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.log("connected to \(peripheral)")
        peripheral.discoverServices(nil)
        connectedPeripheral = peripheral
        connectedPeripheralName = connectedPeripheral?.name
        centralManager?.stopScan()
        connected = true
        
        logger.log("CONNECTED = \(self.connected)")
        logger.log("The services of the connected device: \(self.connectedPeripheral?.services?.description ?? "no services available")")
    }
    
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.log("Disconnected from \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber){
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
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
    category: "Log")
    
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
