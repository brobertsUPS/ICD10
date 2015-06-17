//
//  BillsTableViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/15/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class BillsTableViewController: UITableViewController {
    
    var dbManager:DatabaseManager!
    var patientsInfo:[(id:Int,dob:String, name:String)] = [] //the pID maps to the date of birth and the patient name
    var IDs:[(aptID:Int, dID:Int, placeID:Int, roomID:Int)] = []
    var date:String = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        var indexPath = self.tableView.indexPathForSelectedRow()
        var (id, dob, name) = patientsInfo[indexPath!.row]
        var (aptID, dID, placeID, roomID) = IDs[indexPath!.row]
        
        if segue.identifier == "showBill" {
            let controller = segue.destinationViewController as! BillViewController
            
            let doctorName = getDoctorForBill(dID)//doctor
            let place = getPlaceForBill(placeID)//place
            let room = getRoomForBill(roomID)//room
            let (cpt, mc, pc) = getVisitCodesForBill(aptID)//cpt, mc, pc
            let icd10Codes:[(icd10:String,icd9:String)] = getDiagnosesCodesForBill(aptID)//ICD10
            
            controller.textFieldText.append(name)
            controller.textFieldText.append(dob)
            controller.textFieldText.append(doctorName)
            controller.textFieldText.append(place)
            controller.textFieldText.append(room)
            controller.textFieldText.append(cpt)
            controller.textFieldText.append(mc)
            controller.textFieldText.append(pc)
            
            controller.icdCodes = icd10Codes
        }
    }
    
    func getDoctorForBill(dID:Int) -> String{
        var nameString = ""
        dbManager.checkDatabaseFileAndOpen()
        let doctorQuery = "SELECT f_name, l_name FROM Doctor WHERE dID=\(dID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, doctorQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var firstName = sqlite3_column_text(statement, 0)
                var firstNameString = String.fromCString(UnsafePointer<CChar>(firstName))
                
                var lastName = sqlite3_column_text(statement, 1)
                var lastNameString = String.fromCString(UnsafePointer<CChar>(lastName))
                nameString = "\(firstNameString!) \(lastNameString!)"
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return nameString
    }
    
    func getPlaceForBill(placeID:Int) -> String {
        dbManager.checkDatabaseFileAndOpen()
        var place = ""
        println("placeID \(placeID)")
        let placeQuery = "SELECT place_description FROM Place_of_service WHERE placeID=\(placeID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, placeQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                
                var resultPlace = sqlite3_column_text(statement, 0)
                place = String.fromCString(UnsafePointer<CChar>(resultPlace))!
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return place
    }
    
    func getRoomForBill(roomID:Int) -> String {
        dbManager.checkDatabaseFileAndOpen()
        var room = ""
        println("RoomID \(roomID)")
        let roomQuery = "SELECT room_description FROM Room WHERE roomID=\(roomID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, roomQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var resultRoom = sqlite3_column_text(statement, 0)
                room = String.fromCString(UnsafePointer<CChar>(resultRoom))!
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return room
    }
    
    func getVisitCodesForBill(aptID:Int) -> (String, String, String) {
        
        var cpt = ""
        var mc = ""
        var pc = ""
        dbManager.checkDatabaseFileAndOpen()
        println("aptID: \(aptID)")
        let cptQuery = "SELECT apt_code, type_description FROM Appointment NATURAL JOIN Has_type NATURAL JOIN Apt_type WHERE aptID=\(aptID)"
        
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db,cptQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var visitCode = sqlite3_column_text(statement, 0)
                var visitCodeString = String.fromCString(UnsafePointer<CChar>(visitCode))
                var visitType = sqlite3_column_text(statement, 1)
                var visitTypeString = String.fromCString(UnsafePointer<CChar>(visitType))
                switch visitTypeString! {
                    case "C":cpt = visitCodeString!
                    case "M":mc = visitCodeString!
                    case "P":pc = visitCodeString!
                default:break
                }

            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return (cpt, mc, pc)
    }
    
    func getDiagnosesCodesForBill(aptID:Int) -> [(icd10:String, icd9:String)] {
        
        dbManager.checkDatabaseFileAndOpen()
        
        var conditionDiagnosed:[(icd10:String, icd9:String)] = []
    
        let conditionQuery = "SELECT ICD10_code, ICD9_code FROM Diagnosed_with NATURAL JOIN Appointment NATURAL JOIN Characterized_by WHERE aptID=\(aptID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, conditionQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var conditionICD10 = sqlite3_column_text(statement, 0)
                var conditionString = String.fromCString(UnsafePointer<CChar>(conditionICD10))
                
                var conditionICD9 = sqlite3_column_text(statement, 0)
                var conditionICD9String = String.fromCString(UnsafePointer<CChar>(conditionICD9))
                
                var tuple = (icd10:conditionString!, icd9:conditionICD9String!)
                conditionDiagnosed += [(tuple)]
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        
        return conditionDiagnosed
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return patientsInfo.count }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("billCell", forIndexPath: indexPath) as! UITableViewCell
        var (id, dob, name) = patientsInfo[indexPath.row]
        cell.textLabel!.text = name
        cell.detailTextLabel!.text = dob
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("showBill", sender: self)
    }


    

}
