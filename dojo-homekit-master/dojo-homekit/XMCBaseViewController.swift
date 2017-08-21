//
//  XMCBaseViewController.swift
//  dojo-homekit
//
//  Created by David McGraw on 2/11/15.
//  Copyright (c) 2015 David McGraw. All rights reserved.
//

import UIKit
import HomeKit

class XMCBaseViewController: UITableViewController, HMHomeManagerDelegate {
    
    let homeManager = HMHomeManager()
    var activeHome: HMHome?
    var activeRoom: HMRoom?
    
    var lastSelectedIndexRow = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        homeManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    func updateControllerWithHome(_ home: HMHome) {
        if let room = home.rooms.first as HMRoom? {
            activeRoom = room
            title = room.name + " Devices"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showServicesSegue" {
            let vc = segue.destination as! XMCAccessoryViewController
            if let accessories = activeRoom?.accessories {
                vc.accessory = accessories[lastSelectedIndexRow] as HMAccessory?
            }
        }
    }
    
    // MARK: - Table Delegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let accessories = activeRoom?.accessories {
            return accessories.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceId") as UITableViewCell?
        let accessory = activeRoom!.accessories[indexPath.row] as HMAccessory
        cell?.textLabel?.text = accessory.name
        
        // ignore the information service
        cell?.detailTextLabel?.text = "\(accessory.services.count - 1) service(s)"
        
        return (cell != nil) ? cell! : UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        lastSelectedIndexRow = indexPath.row
    }
    
    // MARK: - Home Delegate
    
    // Homes are not loaded right away. Monitor the delegate so we catch the loaded signal.
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        
    }
    
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        
    }
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        if let home = homeManager.primaryHome {
            activeHome = home
            updateControllerWithHome(home)
        } else {
            initialHomeSetup()
        }
        tableView.reloadData()
    }
    
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        
    }
    
    // MARK: - Setup
    
    // Create our primary home if it doens't exist yet
    fileprivate func initialHomeSetup() {
        homeManager.addHome(withName: "Porter Ave", completionHandler: { (home, error) in
            if error != nil {
                print("Something went wrong when attempting to create our home. \(String(describing: error?.localizedDescription))")
            } else {
                if let discoveredHome = home {
                    // Add a new room to our home
                    discoveredHome.addRoom(withName: "Office", completionHandler: { (room, error) in
                        if error != nil {
                            print("Something went wrong when attempting to create our room. \(String(describing: error?.localizedDescription))")
                        } else {
                            self.updateControllerWithHome(discoveredHome)
                        }
                    })
                    
                    // Assign this home as our primary home
                    self.homeManager.updatePrimaryHome(discoveredHome, completionHandler: { (error) in
                        if error != nil {
                            print("Something went wrong when attempting to make this home our primary home. \(String(describing: error?.localizedDescription))")
                        }
                    })
                } else {
                    print("Something went wrong when attempting to create our home")
                }
                
            }
        })
    }
}

