//
//  DBInterface.swift
//  iMoojigae
//
//  Created by dykim on 2020/09/22.
//  Copyright © 2020 dykim. All rights reserved.
//

import Foundation
import SQLite3

class DBInterface {
    
    func dbPath() -> String {
        let fileman = FileManager.default
        let paths = fileman.urls(for: .documentDirectory, in: .userDomainMask)
        let fullPath = paths[0].appendingPathComponent("moojigae.sqlite")
        
        if !fileman.fileExists(atPath: fullPath.path) {
            createTable(filePath: fullPath.path)
        }
        return fullPath.path
    }

    func createTable(filePath: String) {
        var db: OpaquePointer? = nil
        if sqlite3_open(filePath, &db) != SQLITE_OK {
            print("Unable to open database. Verify that you created the directory described " +
                "in the Getting Started section.")
        }
        // 1
        var createTableStatement: OpaquePointer? = nil
        // 2
        let createTableString = "CREATE TABLE IF NOT EXISTS article ( boardId TEXT, boardNo TEXT, cr_date DATE DEFAULT (datetime('now','localtime')), PRIMARY KEY (boardId, boardNo))"
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            // 3
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Contact table created.")
            } else {
                print("Contact table could not be created.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        // 4
        sqlite3_finalize(createTableStatement)
    }
    
    func search(boardId: String, boardNo: String) -> Int {
        var queryStatement: OpaquePointer? = nil
        var db: OpaquePointer? = nil
        var result = 0
        let dbPath = self.dbPath()
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            if sqlite3_prepare_v2(db, "SELECT count(*) FROM article WHERE boardId = \"\(boardId)\" AND boardNo = \"\(boardNo)\";", -1, &queryStatement, nil) == SQLITE_OK {
                // 2
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    // 3
                    result = Int(sqlite3_column_int(queryStatement, 0))
                } else {
                    print("Query returned no results")
                }
            } else {
                print("SELECT statement could not be prepared")
            }
            sqlite3_finalize(queryStatement)
        }
        return result
    }
    
    func insert(boardId: String, boardNo: String) {
        var insertStatement: OpaquePointer? = nil
        var db: OpaquePointer? = nil
        let dbPath = self.dbPath()
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            if sqlite3_prepare_v2(db, "INSERT INTO article (boardId, boardNo) VALUES (?, ?)", -1, &insertStatement, nil) == SQLITE_OK {
                let nsBoardId: NSString = boardId as NSString
                let nsBoardNo: NSString = boardNo as NSString

                sqlite3_bind_text(insertStatement, 1, nsBoardId.utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 2, nsBoardNo.utf8String, -1, nil)
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    print("Successfully inserted row.")
                } else {
                    print("Could not insert row.")
                }
            } else {
                print("INSERT statement could not be prepared.")
            }
            sqlite3_finalize(insertStatement)
        }
    }
    
    func delete() {
        var insertStatement: OpaquePointer? = nil
        var db: OpaquePointer? = nil
        let dbPath = self.dbPath()
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            if sqlite3_prepare_v2(db, "delete from article where cr_date <= datetime('now', '-6 month', 'localtime')", -1, &insertStatement, nil) == SQLITE_OK {
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    print("Successfully deleted row.")
                } else {
                    print("Could not delete row.")
                }
            } else {
                print("DELETE statement could not be prepared.")
            }
            sqlite3_finalize(insertStatement)
        }
    }
}
