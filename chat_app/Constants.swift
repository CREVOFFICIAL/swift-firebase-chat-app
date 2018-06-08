//
//  Constants.swift
//  chat_app
//
//  Created by 김민수 on 2018. 5. 21..
//  Copyright © 2018년 김민수. All rights reserved.
//

import Firebase

// store variables
// need access to the reference for chat data -> Constants.refs.databaseChats
struct Constants {
    struct refs {
        static let databaseRoot = Database.database().reference()
        static let databaseChats = databaseRoot.child("chats")
    }
}
