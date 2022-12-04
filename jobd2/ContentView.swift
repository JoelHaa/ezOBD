//
//  ContentView.swift
//  jobd2
//
//  Created by Joel Haapaniemi on 4.12.2022.
//

import SwiftUI
import CoreBluetooth


class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    
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
    
    
    
        var body: some View {
        NavigationView {
            VStack {
                List(bluetoothViewModel.peripheralNames, id: \.self, selection: $selection) { peripheral in
                    Text(peripheral)
                }
                Text("\(selection ?? "No bluetooth device selected")").padding([.top, .leading, .bottom], 20)
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
