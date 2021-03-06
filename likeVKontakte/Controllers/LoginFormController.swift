//
//  LoginFormController.swift
//  likeVKontakte
//
//  Created by Антон Голубейков on 10.06.2022.
//

import UIKit

class LoginFormController: UIViewController {
    
    @IBOutlet weak var loginInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated)
    //MARK: - Подписываемся на уведомления
    //Подписываемся на два уведомления: одно приходит при появлении клавиатуры. #selector(self.keyboardWasShown) - функция, которая выполняется после получения события.
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWasShown), name: UIResponder.keyboardWillShowNotification, object: nil)
    // Второе — когда она пропадает
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK: - viewDidLoad (добавили Gesture Recognizer)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Жест нажатия
        let hideKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        // Присваиваем его UIScrollVIew
        scrollView?.addGestureRecognizer(hideKeyboardGesture)
    }
    
    // MARK: - Скрытие клавиатуры по тапу
    @objc func hideKeyboard() { self.scrollView?.endEditing(true)
    }
    
    //MARK: - Отписываемся от центра уведомлений после закрытия вьюхи
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK: - Нажатие кнопки логина
    @IBAction func loginButtonPressed(_ sender: Any) {
        // Получаем текст логина
        let login = loginInput.text!
        // Получаем текст-пароль
        let password = passwordInput.text!
        // Проверяем, верны ли они
        if login == "admin" && password == "admin" {
            print("Успешная авторизация")
            performSegue(withIdentifier: "loginEntered", sender: nil)
        } else {
            let alert = UIAlertController(title: "Ошибка", message: "Введены неверные данные пользователя", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: - Функции, которые вызываются после появления / исчезновения клавиатуры
    @objc func keyboardWasShown(notification: Notification) {
        // Получаем размер клавиатуры
        let info = notification.userInfo! as NSDictionary
        let kbSize = (info.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue).cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: kbSize.height, right: 0.0)
        // Добавляем отступ внизу UIScrollView, равный размеру клавиатуры
        self.scrollView?.contentInset = contentInsets
        scrollView?.scrollIndicatorInsets = contentInsets
        
    }
    //Когда клавиатура исчезает
    @objc func keyboardWillBeHidden(notification: Notification) {
        // Устанавливаем все Insets в ноль
        let contentInsets = UIEdgeInsets.zero
        scrollView?.contentInset = contentInsets
    }
}
