//
//  NetworkService.swift
//  likeVKontakte
//
//  Created by Антон Голубейков on 20.06.2022.
//

import Foundation
import Alamofire
import RealmSwift

// MARK: - Доступ к API VK
class VKService {
    let token: String
    let user_id: String
    
    init(token: String, user_id: String) {
        self.token = token
        self.user_id = user_id
    }
    //MARK: - getFriends URL Session подгружаем json и парсим сразу
    func getFriends(completion: @escaping (Result<[FriendJSON], JSONError>) -> Void) {
        
        var urlConstructor = URLComponents()
        urlConstructor.scheme = "https"
        urlConstructor.host = "api.vk.com"
        urlConstructor.path = "/method/friends.get"
        urlConstructor.queryItems = [
            //URLQueryItem(name: "lang", value: "en"),
            URLQueryItem(name: "user_id", value: user_id),
            URLQueryItem(name: "order_id", value: "name"),
            URLQueryItem(name: "count", value: "5"),
            URLQueryItem(name: "fields", value: "city, country, photo_200, universities"),
            URLQueryItem(name: "name_case", value: "nom"),
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "v", value: "5.131")
        ]
        guard let url = urlConstructor.url else { return }
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                completion(.failure(.serverError))
                return
            }
            guard let data = data else {
                completion(.failure(.noData))
                print("Не пришли данные")
                return
            }
            do {
                let friends = try JSONDecoder().decode(RootFriendJSON.self, from: data).response.items
                completion(.success(friends))
            } catch {
                print("Ошибка декодирования")
                print(error)
                completion(.failure(.decodeError))
            }
            
        }
        task.resume()
    }
    
    //MARK: - getFriendPhotos Сохраняем json в FileStorage после загрузки
    func getFriendsPhotos(for friend: Friend, completion: @escaping (Result<URL, JSONError>) -> Void) {
        
        var urlConstructor = URLComponents()
        urlConstructor.scheme = "https"
        urlConstructor.host = "api.vk.com"
        urlConstructor.path = "/method/photos.getAll"
        urlConstructor.queryItems = [
            //URLQueryItem(name: "lang", value: "en"),
            URLQueryItem(name: "owner_id", value: friend.id),
            URLQueryItem(name: "count", value: "5"),
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "v", value: "5.131")
        ]
        guard let url = urlConstructor.url else { return }
        
        let session = URLSession(configuration: .default)
        let downloadTask = session.downloadTask(with: url) { urlFile, response, error in
            guard error == nil else {
                print(error!.localizedDescription)
                completion(.failure(.serverError))
                return
            }
            if urlFile != nil {
                do {
                    let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]+"/\(friend.name)PhotosData.json"
                    let urlPath = URL(fileURLWithPath: path)
                    
                    if !FileManager.default.fileExists(atPath: path) {
                        try FileManager.default.copyItem(at: urlFile!, to: urlPath)
                        completion(.success(urlPath))
                    } else {
                        completion(.success(urlPath))
                    }
                } catch {
                    print(error)
                    completion(.failure(.savingToFileManagerError))
                    return
                }
            } else {
                completion(.failure(.noData))
                print("Не пришли данные")
                return
            }
        }
        downloadTask.resume()
        
    }
    
    //MARK: - Alamofire getGroups
    func getGroupsAF(completion: @escaping (Result<[Group], JSONError>) -> Void) {
        var urlConstructor = URLComponents()
        urlConstructor.scheme = "https"
        urlConstructor.host = "api.vk.com"
        urlConstructor.path = "/method/groups.get"
        urlConstructor.queryItems = [
            URLQueryItem(name: "user_id", value: user_id),
            URLQueryItem(name: "extended", value: "1"),
            URLQueryItem(name: "fields", value: "members_count"),
            URLQueryItem(name: "count", value: "5"),
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "v", value: "5.131")
        ]
        guard let url = urlConstructor.url else { return }
        
        AF.request(url).responseJSON { (response) in
            if let error = response.error {
                completion(.failure(.serverError))
                print(error)
            }
            guard let data = response.data else {
                completion(.failure(.noData))
                return
            }
            do {
                let groups = try JSONDecoder().decode(RootGroupJSON.self, from: data).response.items
                self.saveGroupsInRealm(groups)
                completion(.success(groups))
                print("GROUPS COUNT", groups.count)
            } catch {
                print("Ошибка декодирования")
                print(error)
                completion(.failure(.decodeError))
            }
        }
    }
    
    func saveGroupsInRealm (_ groups: [Group]) {
        // На бою так не делаем, чтобы не положить базу)) Это чисто для теста
        Realm.Configuration.defaultConfiguration = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
        do {
            let realm = try Realm()
            print("REALM PATH:", realm.configuration.fileURL)
            realm.beginWrite()
            realm.add(groups)
            try realm.commitWrite()
        } catch {
            print("Ошибка сохранения данных в Realm")
            print(error)
        }
    }
    
    
    enum JSONError: Error {
        case decodeError
        case noData
        case serverError
        case savingToFileManagerError
    }
}
