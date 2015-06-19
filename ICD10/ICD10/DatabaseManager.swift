/*
*  DatabaseManager.swift
*  A class to manage the database connection. Allows for opening and closing of the database so only one connection is open at one time.
*
*  Created by Brandon S Roberts on 6/9/15.
*  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit

class DatabaseManager {
    
    var db:COpaquePointer!
    
    init(){
        
    }
    
    /**
    *   Checks that the database file is on the device. If not, copies the database file to the device.
    *   Connects to the database after file is verified to be in the right spot.
    **/
    func checkDatabaseFileAndOpen(){
        let theFileManager = NSFileManager.defaultManager()
        let filePath = dataFilePath()
        if theFileManager.fileExistsAtPath(filePath) {
            db = openDBPath(filePath)
        } else {
            
            let pathToBundledDB = NSBundle.mainBundle().pathForResource("testDML", ofType: "sqlite3")// Copy the file from the Bundle and write it to the Device
            let pathToDevice = dataFilePath()
            var error:NSError?
            
            if (theFileManager.copyItemAtPath(pathToBundledDB!, toPath:pathToDevice, error: nil)) {
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
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory = paths[0] as! NSString
        return documentsDirectory.stringByAppendingPathComponent("testDML.sqlite3") as String
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
    
    func closeDB() {
        var closeResult = sqlite3_close_v2(db)
        
        if closeResult == SQLITE_OK {
            //success
        }
    }
    
    //Adding information to the database*************************************************************************************************************
    
    func addAppointmentToDatabase(patientID:Int, doctorID:Int, date:String, placeID:Int, roomID:Int) -> (Int, String){
        
        var aptID:Int = 0
        var result = ""
        let insertAPTQuery = "INSERT INTO Appointment (aptID, pID, dID, date, placeID, roomID) VALUES (NULL, \(patientID),\(doctorID), '\(date)', \(placeID), \(roomID));"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, insertAPTQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                aptID = Int(sqlite3_last_insert_rowid(db))
                result = "Successful Appointment save patientID:\(patientID) doctorID:\(doctorID) date:\(date) placeID:\(placeID) roomID:\(roomID) AptID: \(aptID)"
            }else {
                result = "Failed appointment save patientID:\(patientID) doctorID:\(doctorID) date:\(date) placeID:\(placeID) roomID:\(roomID)"
            }
        }
        sqlite3_finalize(statement)
        return (aptID, result)
    }
    
    func addPatientToDatabase(inputPatient:String, dateOfBirth:String, email:String) -> String{
        
        var (firstName, lastName) = split(inputPatient)
        var result = ""
        
        println(dateOfBirth)
        let query = "INSERT INTO Patient (pID,date_of_birth,f_name,l_name, email) VALUES (NULL, '\(dateOfBirth)', '\(firstName)', '\(lastName!)', '\(email)')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Saved \(firstName) \(lastName!)"
                println("Saved \(firstName) \(lastName!)")
            }else {
                result = "Add patient failed \(sqliteResult)"
                println("Add patient failed \(sqliteResult)")
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func addDoctorToDatabase(inputDoctor:String, email:String, type:Int) -> String{
        var (firstName, lastName) = split(inputDoctor)
        var result = ""
        let query = "INSERT INTO Doctor (dID,f_name,l_name, email, type) VALUES (NULL,'\(firstName)', '\(lastName!)', '\(email)', \(type))"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            var sqliteResult = sqlite3_step(statement)
            if sqliteResult == SQLITE_DONE {
                result = "Saved \(firstName) \(lastName!)"
            }else {
                result = "Add doctor failed for \(firstName) \(lastName!) with error \(sqliteResult)"
            }
        }
        sqlite3_finalize(statement)
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
    
    func addHasType(aptID:Int, visitCodeText:String) {
        let insertHasType = "INSERT INTO Has_type (aptID,apt_code) VALUES (\(aptID),'\(visitCodeText)')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, insertHasType, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                println("Successful vist code save:\(visitCodeText) aptID:\(aptID)")
            }else {
                println("Failed visit code save:\(visitCodeText)")
            }
        }
        sqlite3_finalize(statement)
    }
    
    func addDiagnosedWith(aptID:Int, ICD10Text:String){
        let diagnosedWith = "INSERT INTO Diagnosed_with (aptID, ICD10_code) VALUES (\(aptID), '\(ICD10Text)')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, diagnosedWith, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                println("Successful ICD10 Save aptID:\(aptID) ICD10:\(ICD10Text)")
            } else {
                println("Failed ICD10 save aptID:\(aptID) ICD10:\(ICD10Text)")
            }
            
        }
        sqlite3_finalize(statement)

    }
    
    //Update information in the database
    func updatePatient(firstName:String, lastName:String, dob:String, email:String, id:Int) -> String{
        let query = "UPDATE Patient SET date_of_birth='\(dob)', f_name='\(firstName)', l_name='\(lastName)', email='\(email)' WHERE pID='\(id)';"
        var result = ""
        var statement:COpaquePointer = nil
        println("Selected")
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
        
        let query = "UPDATE Doctor SET email='\(email)', f_name='\(firstName)', l_name='\(lastName)', type=\(type) WHERE dID='\(id)';"
        var result = ""
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                result = "Doctor updated to \(email) \(firstName) \(lastName) \(type)"
            } else {
                result = "Doctor update failed: \(email) \(firstName) \(lastName)"

            }
            //popup saying it worked
        }
        sqlite3_finalize(statement)
        return result
    }
    
    //Retrieve information from the database*************************************************************************************************************
    
    /**
    *   Returns the id of the place of service. Adds place of service if it did not match any in the database.
    **/
    func getPlaceOfServiceID(placeInput:String) -> Int {
        
        var placeID = 0
        let placeQuery = "SELECT placeID FROM Place_of_service WHERE place_description='\(placeInput)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, placeQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                placeID = Int(sqlite3_column_int(statement, 0))
                
                println("Found place:\(placeID)")
            } else {
                self.addPlaceOfService(placeInput)
                placeID = Int(sqlite3_last_insert_rowid(db))
                println("Added place:\(placeID)")
            }
        }
        sqlite3_finalize(statement)
        return placeID
    }
    
    /**
    *   Returns the id of the room. Adds the room if it did not match any in the database.
    **/
    func getRoomID(roomInput:String) -> Int {
        
        var roomID = 0
        let roomQuery = "SELECT roomID FROM Room WHERE room_description='\(roomInput)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, roomQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {                                  //if we found a room grab it's id
                roomID = Int(sqlite3_column_int(statement, 0))
                println("Found room:\(roomID)")
            } else {
                self.addRoom(roomInput)                                                 //input the room and then get the id
                roomID = Int(sqlite3_last_insert_rowid(db))
                println("Added room\(roomID)")
            }
        }
        sqlite3_finalize(statement)
        return roomID
    }
    
    
    /**
    *   Returns the id of the doctor. Adds the doctor if it did not match any in the database.
    **/
    func getDoctorID(doctorInput:String) -> Int {
        
        var dID = 0
        let (firstName, lastName) = split(doctorInput)
        let doctorQuery = "SELECT dID FROM Doctor WHERE f_name='\(firstName)' AND l_name='\(lastName!)';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, doctorQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                dID = Int(sqlite3_column_int(statement, 0))
                println("Found doctor:\(dID)")
            }  else {
                self.addDoctorToDatabase(doctorInput, email: "", type: 1)
                dID = Int(sqlite3_last_insert_rowid(db))
                println("Added doctor:\(dID)")
            }
        }
        sqlite3_finalize(statement)
        return dID
    }
    
    func getAdminDoc() -> String{
        var adminDoc = ""
        
        let adminQuery = "SELECT f_name, l_name FROM Doctor WHERE type=0"
        var statement:COpaquePointer = nil
        println("Ran adminQuery")
        if sqlite3_prepare_v2(db, adminQuery, -1, &statement, nil) == SQLITE_OK {
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let doctorFName = sqlite3_column_text(statement, 0)
                let doctorFNameString = String.fromCString(UnsafePointer<CChar>(doctorFName))
                
                let doctorLName = sqlite3_column_text(statement, 1)
                let doctorLNameString = String.fromCString(UnsafePointer<CChar>(doctorLName))
                println("\(doctorFNameString!)")
                adminDoc = "\(doctorFNameString!) \(doctorLNameString!)"
            }
        }
        sqlite3_finalize(statement)
        return adminDoc
    }
    
    /**
    *   Returns the id of the patient. Adds the patient if it did not match any in the database.
    **/
    func getPatientID(patientInput:String, dateOfBirth:String) -> Int {
        
        var pID = 0
        let (firstName, lastName) = split(patientInput)
        let patientQuery = "SELECT pID FROM Patient WHERE f_name='\(firstName)' AND l_name='\(lastName!)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(db, patientQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW{
                pID = Int(sqlite3_column_int(statement, 0))
                println("Found patient:\(pID)")
            } else {
                println("Added \(patientInput)")
                self.addPatientToDatabase(patientInput, dateOfBirth: dateOfBirth, email: "")
                pID = Int(sqlite3_last_insert_rowid(db))
                println("Added patient:\(pID)")
            }
        }
        sqlite3_finalize(statement)
        return pID
    }
    
    //****************************************** Searches ******************************************************************************
    
    /**
    *   Searches for any patients matching the text that was input into the patient textfield.
    *   @return patients, a list of patients matching the user input
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
    
    /**
    *   Searches for any doctors matching the text that was input into the doctor textfield.
    *   @return doctors, a list of doctors matching the user input
    **/
    func doctorSearch(inputDoctor:String) -> [String] {
        
        var doctors:[String] = []
        
        let doctorSearch = "SELECT dID, f_name, l_name FROM Doctor WHERE f_name LIKE '%\(inputDoctor)%' OR l_name LIKE '%\(inputDoctor)%';"
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
    
    /**
    *   Searches for any code matching the text or code that was input into the visit code textField
    *   @return visitCodes, a list of code tuples (code, description)
    **/
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


    /**
    *   Splits a string with a space delimeter
    **/
    func split(splitString:String) -> (String, String?){
        
        let fullNameArr = splitString.componentsSeparatedByString(" ")
        var firstName: String = fullNameArr[0]
        var lastName: String =  fullNameArr[1]
        return (firstName, lastName)
    }


}
