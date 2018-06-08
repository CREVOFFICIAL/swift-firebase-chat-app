//
//  ViewController.swift
//  chat_app
//
//  Created by 김민수 on 2018. 5. 20..
//  Copyright © 2018년 김민수. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ViewController: JSQMessagesViewController {
    
    var messages = [JSQMessage]()
    
    // 프로퍼티에 저장된 lazy로된 초기 값은 이 프로퍼티가 제일 처음 호출되었을때 계산된다
    // jsq에서 지원하는 이미지
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }()
    
    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()
    
    
    // 파이어베이스 데이터 불러오기, 보통 willappear 에서 불러온다.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // 쿼리 초기화 및 제한 (최대 10명)
        let query = Constants.refs.databaseChats.queryLimited(toLast: 10)
        
        // 새로운 object 생성될 때 마다, 해당 closuer 실행
        // snapshot 통해 파이어베이스의 return 된 데이터가 찍히게 된다.
        _ = query.observe(.childAdded, with: { [weak self] snapshot in
            
            if  let data        = snapshot.value as? [String: String],
                let id          = data["sender_id"],
                let name        = data["name"],
                let text        = data["text"],
                !text.isEmpty
            {
                if let message = JSQMessage(senderId: id, displayName: name, text: text)
                {
                    self?.messages.append(message)
                    
                    self?.finishReceivingMessage()
                }
            }
        })
        
    }
    
    // 뷰가 생성되기 맨 처음 실행되는 메소드
    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderId = "[yourId]"
        senderDisplayName = "[yourname]"
        
        inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        
        
        let defaults = UserDefaults.standard
        
        if  let id = defaults.string(forKey: "jsq_id"),
            let name = defaults.string(forKey: "jsq_name")
        {
            senderId = id
            senderDisplayName = name
        }
        else
        {
            senderId = String(arc4random_uniform(999999))
            senderDisplayName = ""
            
            defaults.set(senderId, forKey: "jsq_id")
            defaults.synchronize()
            
            showDisplayNameDialog()
        }
        
        title = "Chat: \(senderDisplayName!)"
        
        // custom 으로 임의로 메소드를 만들어 탭바를 클릭시 실행 시키게끔 만듬
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showDisplayNameDialog))
        tapGesture.numberOfTapsRequired = 1
        
        navigationController?.navigationBar.addGestureRecognizer(tapGesture)
        
    }
    
    // 다이얼 로그
    @objc func showDisplayNameDialog()
    {
        //NSUserdeafult 에서 지원해주는 임시 데이터 저장 메소드
        
        let defaults = UserDefaults.standard
        
        // alert 뷰를 이용한 alert 내용 기입
        let alert = UIAlertController(title: "당신의 이름은?", message: "채팅을 하기전에, 당신의 보여줄 이름을 선택하거나 기입해주세요. 탭바를 다시 클릭하면 이름을 변경할수 있습니다.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            
            if let name = defaults.string(forKey: "jsq_name")
            {
                textField.text = name
            }
            else
            {
                let names = ["민수님", "태준님", "용진사마", "동수님", "지원님", "정훈님", "피규어님"]
                textField.text = names[Int(arc4random_uniform(UInt32(names.count)))]
            }
        }
        
        // alert 창에 확인 메소드
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] _ in
            
            if let textField = alert?.textFields?[0],
                !textField.text!.isEmpty {
                
                self?.senderDisplayName = textField.text
                
                self?.title = "Chat: \(self!.senderDisplayName!)"
                
                defaults.set(textField.text, forKey: "jsq_name")
                defaults.synchronize()
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
}

extension ViewController {
    // collectionview delegate method
    // 한 아이템당 메시지 데이터
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData!{
        return messages[indexPath.item]
    }
    
    //한 섹션당 아이템 갯수
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return messages.count
    }
    
    // 한 아이템 당 이미지 버블을 넣기(조건에 따라)
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource!{
        return messages[indexPath.item].senderId == senderId ? outgoingBubble : incomingBubble
    }
    
    // 아바타 이미지 넣기
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource!{
        return nil
    }
    
    // 버튼을 눌렀을 때 동작하는 메소드
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!)
    {
        let ref = Constants.refs.databaseChats.childByAutoId()
        
        let message = ["sender_id": senderId, "name": senderDisplayName, "text": text]
        
        ref.setValue(message)
        
        finishSendingMessage()
    }
}

