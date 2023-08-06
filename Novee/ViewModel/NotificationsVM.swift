//
//  NotificationsVM.swift
//  Novee
//
//  Created by Nick on 2023-08-03.
//

import Foundation
import UserNotifications

class NotificationsVM: ObservableObject {
    static let shared = NotificationsVM()
    
    @Published var notifications: [LocalNotification] = []
    
    @Published var isMuted: Bool = UserDefaults.standard.bool(forKey: "isMuted") {
        willSet {
            UserDefaults.standard.set(newValue, forKey: "isMuted")
        }
    }
    
    var hasNotifications: Bool {
        !notifications.isEmpty
    }
    
    func addNotification(title: String, subtitle: String, sound: UNNotificationSound = UNNotificationSound.default, displayNotif: Bool = true) async {
        Task { @MainActor in
            notifications.append(LocalNotification(title: title, body: subtitle, date: Date.now))
        }

        if displayNotif && !isMuted {
            do {
                let content = UNMutableNotificationContent()
                content.title = title
                content.subtitle = subtitle
                content.sound = sound
                
                // show this notification 1 second from now
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                // choose a random identifier
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
                // add our notification request
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                Log.shared.error(error)
            }
        }
    }
}
