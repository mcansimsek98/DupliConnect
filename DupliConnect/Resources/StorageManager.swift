//
//  StorageManager.swift
//  DupliConnect
//
//  Created by Mehmet Can Şimşek on 29.08.2023.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias uploadPictureCompletion = (Result<String, Error>)-> Void
    public typealias downloadPictureCompletion = (Result<URL, Error>)-> Void
    
    /// Upload Picture to firebase storage and returns completion with url string download
    public func uploadProfilePicture(with data: Data, fileName: String, complation: @escaping uploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                complation(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    complation(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                complation(.success(urlString))
            })
        })
    }
    
    
    /// Upload image that will be sent a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, complation: @escaping uploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                complation(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    complation(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                complation(.success(urlString))
            })
        })
    }
    
    /// Upload video thatt will be sent a conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, complation: @escaping uploadPictureCompletion) {
        do {
            let videoData = try Data(contentsOf: fileUrl)
            storage.child("message_videos/\(fileName)").putData(videoData, completion: { [weak self] metadata, error in
                guard error == nil else {
                    complation(.failure(StorageErrors.failedToUpload))
                    return
                }
                
                self?.storage.child("message_videos/\(fileName)").downloadURL(completion: {url, error in
                    guard let url = url else {
                        complation(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    let urlString = url.absoluteString
                    complation(.success(urlString))
                })
            })
        } catch {
            print("-- Error: \(error)")
        }
    }
    
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadUrl(for path: String, complation: @escaping downloadPictureCompletion) {
        let referance = storage.child(path)
        
        referance.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                complation(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            complation(.success(url))
        })
    }
}
