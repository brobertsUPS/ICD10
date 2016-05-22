/*
*  DatabaseManager.swift
*  A class to manage the database connection. Allows for opening and closing of the database so only one connection is open at one time.
*  Any functions that need to be in multiple pages are placed in this class. Any other database functions that are only used in one place are kept 
*  in their local class.
*
*  Created by Brandon S Roberts on 6/9/15.
*  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit


class DatabaseManager {
    
    var db:COpaquePointer!
    
    // MARK: - Database File Management
    
    /**
    *   Checks that the database file is on the device. If not, copies the database file to the device.
    *   Connects to the database after file is verified to be in the right spot.
    **/
    func checkDatabaseFileAndOpen(){
        
        NSUserDefaults.standardUserDefaults().setInteger(1, forKey:"DATABASE_VERSION")
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            let theFileManager = NSFileManager.defaultManager()
            
            let filePath = dataFilePath()
            if theFileManager.fileExistsAtPath(filePath) {  //login with password
                db = openDBPath(filePath)
                
            } else {                                        //set password for the database
                
                let pathToBundledDB = NSBundle.mainBundle().pathForResource("testDML", ofType: "sqlite3")// Copy the file from the Bundle and write it to the Device
                let pathToDevice = dataFilePath()
                var error:NSError?
                
                if (theFileManager.copyItemAtPath(pathToBundledDB!, toPath:pathToDevice, error: nil)) {
                    println("Open copied")
                    db = openDBPath(pathToDevice)
                } else {
                    println("database failure")
                }
            }
    }
    
    /**
    *   Gets the path of the database file on the device
    **/
    func dataFilePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let cachesDirectory = paths[0] as! NSString
        return cachesDirectory.stringByAppendingPathComponent("testDML.sqlite3") as String
    }
    
    /**
    *   Makes a connection to the database file located at the provided filePath
    **/
    func openDBPath(filePath:String) -> COpaquePointer {
        
        var db:COpaquePointer  = nil
        var result = sqlite3_open(filePath, &db)
        
        if result != SQLITE_OK {
            sqlite3_close(db)
            println("Failed To Open Database")
            return nil
        }else {
            return db
        }
    }
    
    func closeDB() -> String{
        var closeResult = sqlite3_close(db)
        return "Close result \(closeResult)"
    }
    
    // MARK: - Adding information to the database
    
    func addAppointmentToDatabase(patientID:Int, date:String, placeID:Int, roomID:Int, codeType:Int, billComplete:Int) -> (Int, String){
        
        var aptID:Int = 0
        var result = ""
        let insertAPTQuery = "INSERT INTO Appointment (aptID, pID, date, placeID, roomID, code_type, complete) VALUES (NULL, \(patientID), '\(date)', \(placeID), \(roomID), \(codeType), \(billComplete));"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, insertAPTQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                aptID = Int(sqlite3_last_insert_rowid(db))
                result = "Successful Appointment save patientID:\(patientID) date:\(date) placeID:\(placeID) roomID:\(roomID) AptID: \(aptID) codeType:\(codeType)"
            }else {
                result = "Failed appointment save patientID:\(patientID) date:\(date) placeID:\(placeID) roomID:\(roomID) codeType:\(codeType)"
            }
        }
        sqlite3_finalize(statement)
        return (aptID, result)
    }
    
    func addPatientToDatabase(inputPatient:String, dateOfBirth:String, email:String) -> String{
        
        var (firstName, lastName) = split(inputPatient)
        var result = ""
        firstName = firstName.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        lastName = lastName!.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        
        if lastName == "" {
            result = "No last name input was detected. Please enter a first and last name for the patient."
        }else{
            let query = "INSERT INTO Patient (pID,date_of_birth,f_name,l_name, email) VALUES (NULL, '\(dateOfBirth)', '\(firstName)', '\(lastName!)', '\(email)')"
            var statement:COpaquePointer = nil
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                var sqliteResult = sqlite3_step(statement)
                if sqliteResult == SQLITE_DONE {
                    result = "Saved \(firstName) \(lastName!)"
                }else {
                    result = "Add patient failed \(sqliteResult)"
                }
            }
            sqlite3_finalize(statement)
        }
        return result
    }
    
    func addDoctorToDatabase(inputDoctor:String, email:String, type:Int) -> String{
        
        println("Adding doc")
        var (firstName, lastName) = split(inputDoctor)
        var result = ""
        println("First name \(firstName) last name \(lastName)")
        
        firstName = firstName.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        lastName = lastName!.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        
        if lastName == "" {
            result = "No last name input was detected. Please enter a first and last name for the doctor."
        }else{
            var firstPart = "INSERT INTO Doctor (dID,f_name,l_name, email, type) VALUES (NULL,'" +  firstName + "', '"
            let query =  firstPart + lastName! + "', '" + email + "', \(type))"
            var statement:COpaquePointer = nil
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                var sqliteResult = sqlite3_step(statement)
                if sqliteResult == SQLITE_DONE {
                    result = "Saved \(firstName) \(lastName!)"
                }else {
                    result = "Add doctor failed for \(firstName) \(lastName!)"
                }
            }
            sqlite3_finalize(statement)
        }
        return result
    }
    
    func checkForDoctorAndAdd(doctorInput:String) -> String {
        
        var result = ""
        var (firstName, lastName) = split(doctorInput)
       
        firstName = firstName.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        lastName = lastName!.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        
        if lastName == "" {
            result = "No last name was detected. Please input a first and last name separated by a space."
        } else {
            let doctorQuery = "SELECT * FROM Doctor WHERE f_name='" + firstName + "' AND l_name='" + lastName! + "'"
            var statement:COpaquePointer = nil
            
            if sqlite3_prepare_v2(db, doctorQuery, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) != SQLITE_ROW {
                    self.addDoctorToDatabase(doctorInput, email: "", type: 0)
                }
            }
            sqlite3_finalize(statement)
        }
        println(result)
        return result
    }
    
    func addPlaceOfService(placeInput:String) -> String{
        let insertPlaceQuery = "INSERT INTO Place_of_service (placeID, place_description) VALUES (NULL, '\(placeInput)');"
        var statement:COpaquePointer = nil
        var result = ""
        if sqlite3_prepare_v2(db, insertPlaceQuery, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Saved \(placeInput)"
            }else if sqliteResult == SQLITE_ERROR {
                result = "Failed place of service save placeInput:\(placeInput)"
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func addRoom(roomInput:String) -> String{
        let insertPlaceQuery = "INSERT INTO Room (roomID, room_description) VALUES (NULL, '\(roomInput)');"
        var statement:COpaquePointer = nil
        var result = ""
        if sqlite3_prepare_v2(db, insertPlaceQuery, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Successful room save \(roomInput)"
            }else if sqliteResult == SQLITE_ERROR {
                result = "Failed room save \(roomInput)"
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func addHasType(aptID:Int, visitCodeText:String, icd10CodeID:Int, visitPriority:Int, icdPriority:Int, extensionCode:String) -> String{
        var result = ""
        let insertHasType = "INSERT INTO Has_type (aptID,apt_code, ICD10_ID, visit_priority, icd_priority, extension) VALUES (\(aptID),'\(visitCodeText)', \(icd10CodeID), \(visitPriority), \(icdPriority), '\(extensionCode)')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, insertHasType, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Successful visit code save:\(visitCodeText) icdCode: \(icd10CodeID) visitPriority: \(visitPriority)"
            }else {
               result = "Failed visit code save:\(visitCodeText) icdCode: \(icd10CodeID)"
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func addHasDoc(aptID:Int, dID:Int) -> String{
        
        var result = ""
        let insertDoc = "INSERT INTO Has_doc (aptID, dID) VALUES (\(aptID), \(dID))"
        
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, insertDoc, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                result = "Successful doc save aptID:\(aptID) dID:\(dID)"
            }else {
                result = "Failed apt doc save:\(aptID) doc: \(dID)"
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func addHasModifiers(aptID:Int, aptCode:String, modifierID:Int) -> String {
        
        var result = ""
        let insertHasModifier = "INSERT INTO Has_modifiers (aptID, apt_code, modifierID) VALUES (\(aptID), '\(aptCode)', \(modifierID))"
        
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, insertHasModifier, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                result = "Successful mod save aptID:\(aptID) aptCode \(aptCode) modifier \(modifierID)"
                
            }else {
                result = "Failed apt nod save:\(aptID) aptCode \(aptCode) modifier \(modifierID)"
            }
        }
        sqlite3_finalize(statement)
        return result

    }
    
    // MARK: - Remove From Database
    
    func removePatientFromDatabase(id:Int) -> String {
        
        var result = ""
        let removePatientQuery = "DELETE FROM Patient WHERE pID=\(id)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, removePatientQuery, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Removed patient with id \(id)"
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func removeDoctorFromDatabase(id:Int) -> String{
        
        var result = ""
        let removeDocQuery = "DELETE FROM Doctor WHERE dID=\(id)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, removeDocQuery, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Removed doc with id \(id)"
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func removeBillWithPatientID(id:Int) -> String{
        var result = ""
        
        let removeAptQuery = "DELETE FROM Appointment WHERE pID=\(id)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, removeAptQuery, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Removed appointment"
            }else {
                result = "Remove appointment failed"
            }
        }
        sqlite3_finalize(statement)
        return result        
    }
    
    func removeFavoriteFromDatabase(id:Int) -> String{
        var result = ""
        let removeFavoriteQuery = "DELETE FROM Sub_location WHERE LID=\(id) AND parent_locationID=0"
        
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, removeFavoriteQuery, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Removed Favorite with id \(id)"
            }else {
                result = "Favorite \(id) not removed"
            }
        }
        sqlite3_finalize(statement)
        return result

    }
    
    func removeAppointmentFromDatabase(aptID:Int) -> String{
        var result = ""
        let removeAptQuery = "DELETE FROM Appointment WHERE aptID=\(aptID)"
        
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, removeAptQuery, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Removed Apt with id \(aptID)"
            }else {
                result = "Apt \(aptID) not removed"
            }
        }
        sqlite3_finalize(statement)
        return result

    }
    
    func removeCodesFromDatabase(aptID:Int, aptCode:String) -> String{
        
        var result = "Error, the query did not run"
        
        let removeCodesQuery = "DELETE FROM Has_type WHERE aptID=\(aptID) AND apt_code='\(aptCode)'"
        var statement:COpaquePointer = nil

        var resultPrepare = sqlite3_prepare_v2(db, removeCodesQuery, -1, &statement, nil)
        if resultPrepare == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Removed codes with aptID=\(aptID) AND aptCode='\(aptCode)'"
            }else {
                result = "aptID=\(aptID) AND aptCode='\(aptCode)' not removed"
            }
        }
        sqlite3_finalize(statement)
        return result

    }
    
    func removeModifiersForBill(aptID:Int) -> String{
        var result = ""
        var removeModifiersQuery = "DELETE FROM Has_modifiers WHERE aptID=\(aptID)"
        
        var statement:COpaquePointer = nil
        
        var resultPrepare = sqlite3_prepare_v2(db, removeModifiersQuery, -1, &statement, nil)
        if resultPrepare == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Removed modifiers from aptID=\(aptID)"
            }else {
                result = "Modifiers for aptID=\(aptID) not removed"
            }
        }
        sqlite3_finalize(statement)
        return result

    }
    
    func removeHasDoc(aptID:Int) -> String{
        var result = ""
        var removeDocsQuery = "DELETE FROM Has_doc WHERE aptID=\(aptID)"
        
        var statement:COpaquePointer = nil
        
        var resultPrepare = sqlite3_prepare_v2(db, removeDocsQuery, -1, &statement, nil)
        if resultPrepare == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Removed docs from aptID=\(aptID)"
            }else {
                result = "Docs aptID=\(aptID) not removed"
            }
        }
        sqlite3_finalize(statement)
        return result

    }
    
    // MARK: - Update information in the database
    
    func updatePatient(firstName:String, lastName:String, dob:String, email:String, id:Int) -> String{
        
        var firstName = firstName.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        var lastName = lastName.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)

        let query = "UPDATE Patient SET date_of_birth='\(dob)', f_name='\(firstName)', l_name='\(lastName)', email='\(email)' WHERE pID='\(id)';"
        var result = ""
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                
                result = "Update succeeded for \(firstName) \(lastName) \(dob) \(email)"
            }else {
                result = "Update failed for \(firstName) \(lastName) \(dob) \(email)"
            }
            
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func updateDoctor(firstName:String, lastName:String, email:String, id:Int, type:Int) -> String {
        
        var firstName = firstName.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        var lastName = lastName.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        
        let query = "UPDATE Doctor SET email='\(email)', f_name='\(firstName)', l_name='\(lastName)', type=\(type) WHERE dID='\(id)';"
        var result = ""
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                result = "Doctor updated to \(email) \(firstName) \(lastName)"
            } else {
                result = "Doctor update failed: \(email) \(firstName) \(lastName)"

            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func updateAppointment(aptID:Int, pID:Int, placeID:Int, roomID:Int, code_type:Int, complete:Int, date:String){
        
        var updateQueryBuilder = "UPDATE Appointment SET "
        if pID != -1 {
            updateAppointment(aptID, attributeToUpdate: "pID", valueOfAttribute: pID)
        }
        
        if placeID != -1 {
            updateAppointment(aptID, attributeToUpdate: "placeID", valueOfAttribute: placeID)
        }
        
        if roomID != -1 {
            updateAppointment(aptID, attributeToUpdate: "roomID", valueOfAttribute: roomID)
        }
        
        updateAppointment(aptID, attributeToUpdate: "code_type", valueOfAttribute: code_type)
        updateAppointment(aptID, attributeToUpdate: "complete", valueOfAttribute: complete)
        
        updateAppointmentDate(aptID, date: date)
    }
    
    func updateAppointment(aptID:Int, attributeToUpdate:String, valueOfAttribute:Int) -> String{
        
        let updateAptQuery = "UPDATE Appointment SET \(attributeToUpdate)=\(valueOfAttribute) WHERE aptID=\(aptID)"
        
        var result = ""
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, updateAptQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                result = "Apt Succesful upate \(attributeToUpdate)=\(valueOfAttribute)"
            } else {
                result = "Apt update failed"
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func updateAppointmentDate(aptID:Int, date:String) -> String {
        
        let updateAptQuery = "UPDATE Appointment SET date='\(date)' WHERE aptID=\(aptID)"
        
        var result = ""
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, updateAptQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                result = "Apt Succesful upate date=\(date)"
            } else {
                result = "Apt update failed"
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    // MARK: - Retrieve information from the database

    func getPlaceOfServiceID(placeInput:String) -> Int {
        
        if placeInput == "" {
            return -1
        }
        
        var placeID = 0
        let placeQuery = "SELECT placeID FROM Place_of_service WHERE place_description='\(placeInput)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, placeQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                placeID = Int(sqlite3_column_int(statement, 0))
            } else {
                self.addPlaceOfService(placeInput)
                placeID = Int(sqlite3_last_insert_rowid(db))
            }
        }
        sqlite3_finalize(statement)
        return placeID
    }
    
    func getDoctorWithID(doctorID:Int) -> String{
        
        var fullName = ""
        let doctorQuery = "SELECT f_name, l_name FROM Doctor WHERE dID=\(doctorID);"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, doctorQuery, -1, &statement, nil) == SQLITE_OK {
            var result = sqlite3_step(statement)
            if result == SQLITE_DONE || result == SQLITE_ROW {
                
                let docFName = sqlite3_column_text(statement, 0)
                let docFNameString = String.fromCString(UnsafePointer<CChar>(docFName))
             
                let docLName = sqlite3_column_text(statement, 1)
                let docLNameString = String.fromCString(UnsafePointer<CChar>(docLName))
               
                fullName = docFNameString! + " " + docLNameString!
            }
        }
        sqlite3_finalize(statement)
        return fullName
    }

    func getPlaceWithID(placeID:Int) -> String{
        
        var place = ""
        
        let placeQuery = "SELECT place_description FROM Place_of_service WHERE placeID=\(placeID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, placeQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var retrievedPlace = sqlite3_column_text(statement, 0)
                place = String.fromCString(UnsafePointer<CChar>(retrievedPlace))!
            }
        }
        
        sqlite3_finalize(statement)
        return place
    }
    
    func getRoomWithID(roomID:Int) ->String{
        
        
        
        var room = ""
        let roomQuery = "SELECT room_description FROM Room WHERE roomID=\(roomID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, roomQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var retrievedRoom = sqlite3_column_text(statement, 0)
                room = String.fromCString(UnsafePointer<CChar>(retrievedRoom))!
            }
        }
        sqlite3_finalize(statement)
        return room
    }
    
    func getPatientID(patientInput:String, dateOfBirth:String) -> Int {
        
        if patientInput == "" {
            return -1
        }
        
        var pID = 0
        var (firstName, lastName) = split(patientInput)
        
        firstName = firstName.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        lastName = lastName!.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        
        let patientQuery = "SELECT pID FROM Patient WHERE f_name='\(firstName)' AND l_name='\(lastName!)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, patientQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW{
                pID = Int(sqlite3_column_int(statement, 0))
            } else {
                self.addPatientToDatabase(patientInput, dateOfBirth: dateOfBirth, email: "")
                pID = Int(sqlite3_last_insert_rowid(db))
            }
        }
        sqlite3_finalize(statement)
        return pID
    }
    
    func getDoctorID(doctorInput:String) -> Int {
        
        if doctorInput == "" {
            return -1
        }
        
        var dID = 0
        var (firstName, lastName) = split(doctorInput)
        
        firstName = firstName.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        lastName = lastName!.stringByReplacingOccurrencesOfString("'", withString: "''", options: nil, range: nil)
        
        let doctorQuery = "SELECT dID FROM Doctor WHERE f_name='\(firstName)' AND l_name='\(lastName!)';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, doctorQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                dID = Int(sqlite3_column_int(statement, 0))
            }  else {
                self.addDoctorToDatabase(doctorInput, email: "", type: 1)
                dID = Int(sqlite3_last_insert_rowid(db))
            }
        }
        sqlite3_finalize(statement)
        return dID
    }

    func getRoomID(roomInput:String) -> Int {
        
        if roomInput == "" {
            return -1
        }
        
        var roomID = 0
        let roomQuery = "SELECT roomID FROM Room WHERE room_description='\(roomInput)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, roomQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {                                  //if we found a room grab it's id
                roomID = Int(sqlite3_column_int(statement, 0))
            } else {
                self.addRoom(roomInput)                                                 //input the room and then get the id
                roomID = Int(sqlite3_last_insert_rowid(db))
            }
        }
        sqlite3_finalize(statement)
        return roomID
    }
    
    func getVisitCodesForBill(aptID:Int) -> ([String:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)]], [String]) {
        
        var codesForBill:[String:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)]] = [:]
        var visitCodePriority:[String] = []
        
        let cptQuery = "SELECT apt_code, visit_priority FROM Appointment NATURAL JOIN Has_type NATURAL JOIN Apt_type WHERE aptID=\(aptID) GROUP BY apt_code ORDER BY visit_priority"
        
        var statement:COpaquePointer = nil
        
        var result = sqlite3_prepare_v2(db,cptQuery, -1, &statement, nil)
        if  result == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                var icdCodesForVisitCode:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)] = []
                
                var visitCode = sqlite3_column_text(statement, 0)
                var visitCodeString = String.fromCString(UnsafePointer<CChar>(visitCode))
                
                var visitPriority = Int(sqlite3_column_int(statement, 1))
                
                if visitPriority >= visitCodePriority.count {
                    visitCodePriority.append(visitCodeString!)
                }else {
                    visitCodePriority[visitPriority] = visitCodeString!
                }
                
                icdCodesForVisitCode = getDiagnosesCodesForVisitCode(aptID, visitCode: visitCodeString!)
                
                codesForBill[visitCodeString!] = icdCodesForVisitCode
            }
        }
        sqlite3_finalize(statement)
        return (codesForBill, visitCodePriority)
    }
    
    func getDiagnosesCodesForVisitCode(aptID:Int, visitCode:String) -> [(icd10:String, icd9:String, icd10id:Int, extensionCode:String)] {
        
        var conditionDiagnosed:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)] = []
        
        let conditionQuery = "SELECT ICD10_code, ICD9_code, ICD10_ID, extension FROM Has_type NATURAL JOIN Appointment NATURAL JOIN ICD10_Condition NATURAL JOIN Characterized_by WHERE aptID=\(aptID) AND apt_code='\(visitCode)' ORDER BY icd_priority"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, conditionQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var conditionICD10 = sqlite3_column_text(statement, 0)
                var conditionString = String.fromCString(UnsafePointer<CChar>(conditionICD10))
                
                var conditionICD9 = sqlite3_column_text(statement, 1)
                var conditionICD9String = String.fromCString(UnsafePointer<CChar>(conditionICD9))
                
                var icd10ID = Int(sqlite3_column_int(statement, 2))
                
                var extensionCode = sqlite3_column_text(statement, 3)
                var extensionString = String.fromCString(UnsafePointer<CChar>(extensionCode))
                
                var tuple = (icd10:conditionString!, icd9:conditionICD9String!, icd10ID:icd10ID, extensionCode:extensionString!)
                conditionDiagnosed += [(tuple)]
            }
        }
        sqlite3_finalize(statement)
        return conditionDiagnosed
    }
    
    func getICD10WithID(ICD10ID:Int) ->String {
        var icd10CodeString = ""
        
        let icdQuery = "SELECT ICD10_code FROM ICD10_condition WHERE ICD10_ID=\(ICD10ID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, icdQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var icd10Code = sqlite3_column_text(statement, 0)
                icd10CodeString = String.fromCString(UnsafePointer<CChar>(icd10Code))!
            }
        }
        
        sqlite3_finalize(statement)
        return icd10CodeString
    }
    
    func getConditionLocationWithID(lID:Int) -> String {
        
        var locationName = ""
        
        let locationQuery = "SELECT location_name FROM Condition_location WHERE LID=\(lID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, locationQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var location = sqlite3_column_text(statement, 0)
                locationName = String.fromCString(UnsafePointer<CChar>(location))!
            }
        }
        sqlite3_finalize(statement)
        
        return locationName
    }
    
    func getVisitCodeDescription(visitCode:String) -> String {
        var codeDescriptionString = ""
        let cptQuery = "SELECT code_description FROM Apt_type WHERE apt_code='\(visitCode)'"
        
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db,cptQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var codeDescription = sqlite3_column_text(statement, 0)
                codeDescriptionString = String.fromCString(UnsafePointer<CChar>(codeDescription))!
            }
        }
        sqlite3_finalize(statement)
        return codeDescriptionString
    }
    
    func getBillsForDate(date:String) -> (patientBills:[(id:Int, dob:String, name:String)], IDs:[(aptID:Int, placeID:Int, roomID:Int)], codeType:[Int], complete:[Int]){
        
        var patientBills:[(id:Int, dob:String, name:String)] = []
        var IDs:[(aptID:Int, placeID:Int, roomID:Int)] = []
        var codeType:[Int] = []
        var complete:[Int] = []
        
        let billsQuery = "SELECT pID,date_of_birth, f_name, l_name, aptID, placeID, roomID, code_type, complete FROM Patient NATURAL JOIN Appointment WHERE date='\(date)'"
        
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, billsQuery, -1, &statement, nil) == SQLITE_OK {
            
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let patientID = Int(sqlite3_column_int(statement, 0))
                
                let patientDOB = sqlite3_column_text(statement, 1)
                let patientDOBString = String.fromCString(UnsafePointer<CChar>(patientDOB))
                
                let patientFName = sqlite3_column_text(statement, 2)
                let patientFNameString = String.fromCString(UnsafePointer<CChar>(patientFName))
                
                let patientLName = sqlite3_column_text(statement, 3)
                let patientLNameString = String.fromCString(UnsafePointer<CChar>(patientLName))
                
                let aptID = Int(sqlite3_column_int(statement, 4))
                
                let placeID = Int(sqlite3_column_int(statement, 5))
                let roomID = Int(sqlite3_column_int(statement, 6))
                let billCodeType = Int(sqlite3_column_int(statement, 7))
                let billComplete = Int(sqlite3_column_int(statement, 8))
                
                
                let patientFullName = patientFNameString! + " " + patientLNameString!
                patientBills.append(id: patientID,dob: patientDOBString!, name: patientFullName)
                IDs.append(aptID:aptID, placeID:placeID, roomID:roomID )
                codeType.append(billCodeType)
                complete.append(billComplete)
            }
        }
        sqlite3_finalize(statement)
        
        let tuple:(patientBills:[(id:Int, dob:String, name:String)], IDs:[(aptID:Int, placeID:Int, roomID:Int)], codeType:[Int], complete:[Int]) = (patientBills, IDs, codeType, complete)
        return tuple
    }
    
    func getDateForApt(aptID:Int) -> String{
        
        var dateString = ""
    
        let dateQuery = "SELECT date FROM Appointment WHERE aptID=\(aptID)"
        
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db,dateQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var date = sqlite3_column_text(statement, 0)
                dateString = String.fromCString(UnsafePointer<CChar>(date))!
            }
        }
        sqlite3_finalize(statement)
        return dateString

    }
    
    func getModifers() -> [(modID:Int, modifier:String, modifierDescription:String)] {
        var modifiers:[(modID:Int, modifier:String, modifierDescription:String)] = []
        
        let modifierQuery = "SELECT modifierID, modifier, modifier_description FROM Modifier ORDER BY modifierID"
        
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, modifierQuery, -1, &statement, nil) == SQLITE_OK {
            
            while sqlite3_step(statement) == SQLITE_ROW {
                
                var modID = Int(sqlite3_column_int(statement, 0))
                
                var modifier = sqlite3_column_text(statement, 1)
                var modifierString = String.fromCString(UnsafePointer<CChar>(modifier))!
                
                var modifierDescription = sqlite3_column_text(statement, 2)
                var modifierDescriptionString = String.fromCString(UnsafePointer<CChar>(modifierDescription))!
                
                let tuple:(modID:Int, modifier:String, modifierDescription:String) = (modID, modifierString, modifierDescriptionString)
                modifiers.append(tuple)
            }
        }
        
        sqlite3_finalize(statement)
        return modifiers
    }
    
    func getModifierWithID(modID:Int) -> String{
        
        var modifier = ""
        let modifierQuery = "SELECT modifier FROM Modifier WHERE modifierID=\(modID)"
        
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db,modifierQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var mod = sqlite3_column_text(statement, 0)
                modifier = String.fromCString(UnsafePointer<CChar>(mod))!
            }
        }
        sqlite3_finalize(statement)
        return modifier
    }
    
    func getModifiersForBill(aptID:Int) -> [String:Int] {
        var modifiers:[String:Int] = [:]
        
        let modifierQuery = "SELECT modifierID, apt_code FROM Modifier NATURAL JOIN Has_modifiers WHERE aptID=\(aptID)"
        
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, modifierQuery, -1, &statement, nil) == SQLITE_OK {
            
            while sqlite3_step(statement) == SQLITE_ROW {
                
                var modID = Int(sqlite3_column_int(statement, 0))
                
                var visitCode = sqlite3_column_text(statement, 1)
                var visitCodeString = String.fromCString(UnsafePointer<CChar>(visitCode))!
                
                modifiers[visitCodeString] = modID
            }
        }
        sqlite3_finalize(statement)
        return modifiers

    }
    
    // MARK: - Searches
    /**
    *   Searches matching the text that was input into the textfield.
    *   @return a list of matching the user input
    **/
    
    func patientSearch(inputPatient:String) ->[(String, String)] {
        
        var patients:[(String, String)] = []
        
        let patientSearch = "SELECT * FROM Patient WHERE f_name LIKE '%\(inputPatient)%' OR l_name LIKE '%\(inputPatient)%';"//search and update the patients array
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, patientSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let id = sqlite3_column_int(statement, 0)
                
                let patientDOB = sqlite3_column_text(statement, 1)
                let patientDOBString = String.fromCString(UnsafePointer<CChar>(patientDOB))
                
                let patientFName = sqlite3_column_text(statement, 2)
                let patientFNameString = String.fromCString(UnsafePointer<CChar>(patientFName))
                
                let patientLName = sqlite3_column_text(statement, 3)
                let patientLNameString = String.fromCString(UnsafePointer<CChar>(patientLName))
                
                let patientFullName = patientFNameString! + " " + patientLNameString!
                
                let tuple = (patientDOBString!, patientFullName)
                patients.append(tuple)
            }
        }
        sqlite3_finalize(statement)
        return patients
    }
    
    func doctorSearch(inputDoctor:String, type:Int) -> [String] {
        
        var doctors:[String] = []
        let doctorSearch = "SELECT dID, f_name, l_name FROM Doctor WHERE type=\(type) AND (f_name LIKE '%\(inputDoctor)%' OR l_name LIKE '%\(inputDoctor)%');"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, doctorSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int(statement, 0)
                
                let doctorFName = sqlite3_column_text(statement, 1)
                let doctorFNameString = String.fromCString(UnsafePointer<CChar>(doctorFName))
                
                let doctorLName = sqlite3_column_text(statement, 2)
                let doctorLNameString = String.fromCString(UnsafePointer<CChar>(doctorLName))
                
                let doctorFullName = doctorFNameString! + " " + doctorLNameString!
                doctors.append(doctorFullName)
            }
        }
        sqlite3_finalize(statement)
        return doctors
    }
    
    func codeSearch(codeType:String, cptTextFieldText:String, mcTextFieldText:String, pcTextFieldText:String) -> [(String,String)]{
        
        var visitCodes:[(String,String)] = []
        var inputSearch = ""
        
        switch codeType {
        case "C":inputSearch = cptTextFieldText
        case "M":inputSearch = mcTextFieldText
        case "P":inputSearch = pcTextFieldText
        default:break
        }
        
        let codeSearch = "SELECT apt_code, code_description FROM Apt_type WHERE type_description='\(codeType)' AND (code_description LIKE '%\(inputSearch)%' OR apt_code LIKE '%\(inputSearch)%');"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, codeSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let apt_code = sqlite3_column_text(statement, 0)
                let apt_codeString = String.fromCString(UnsafePointer<CChar>(apt_code))
                
                let code_description = sqlite3_column_text(statement, 1)
                let code_descriptionString = String.fromCString(UnsafePointer<CChar>(code_description))
                
                let tuple = (apt_codeString!, code_descriptionString!)
                visitCodes.append(tuple)
            }
        }
        sqlite3_finalize(statement)
        return visitCodes
    }
    
    func siteSearch(siteInput:String) -> [String] {
        
        var siteResults:[String] = []
        
        let siteSearchQuery = "SELECT place_description FROM Place_of_service WHERE place_description LIKE '%\(siteInput)%'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, siteSearchQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                var description = sqlite3_column_text(statement, 0)
                var descriptionString = String.fromCString(UnsafePointer<CChar>(description))
                siteResults.append(descriptionString!)
            }
        }
        return siteResults
    }
    
    func roomSearch(roomInput:String) -> [String] {
        var roomResults:[String] = []
        let roomSearchQuery = "SELECT room_description FROM Room WHERE room_description LIKE '%\(roomInput)%'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, roomSearchQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                var description = sqlite3_column_text(statement, 0)
                var descriptionString = String.fromCString(UnsafePointer<CChar>(description))
                roomResults.append(descriptionString!)
            }
        }
        return roomResults
    }

    // MARK: - Helper
    
    /**
    *   Splits a string with a space delimeter
    **/
    func split(splitString:String) -> (String, String?){
        
        let fullNameArr = splitString.componentsSeparatedByString(" ")
        if fullNameArr.count >= 2{
            var firstName: String = fullNameArr[0]
            var lastName: String =  fullNameArr[1]
            return (firstName, lastName)
        }
        return ("","")
    }
}