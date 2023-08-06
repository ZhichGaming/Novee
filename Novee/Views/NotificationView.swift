//
//  NotificationView.swift
//  Novee
//
//  Created by Nick on 2023-08-03.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var notificationsVM: NotificationsVM
    
    @State private var hovered: UUID? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Notifications")
                    .font(.headline)
                
                Spacer()
                
                Button("Dismiss all") {
                    notificationsVM.notifications = []
                }
                
                Button {
                    notificationsVM.isMuted.toggle()
                } label: {
                    Text(notificationsVM.isMuted ? "Unmute notifications" : "Mute notifications")
                }
            }
            
            Group {
                if notificationsVM.hasNotifications {
                    ScrollView {
                        ForEach(notificationsVM.notifications) { notification in
                            NotificationListItemView(notification: notification) {
                                notificationsVM.notifications.removeAll { $0.id == notification.id }
                            }
                            
                            Divider()
                        }
                    }
                } else {
                    Text("Nothing to see here for now...")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(width: 350, height: 400)
    }
}

struct NotificationListItemView: View {
    var notification: LocalNotification
    @State private var hovered = false
    
    var removeNotification: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                Text(notification.body)
                    .font(.footnote)
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                if !hovered {
                    Text(notification.date.formatted(date: .abbreviated, time: .omitted))
                    Text(notification.date.formatted(date: .omitted, time: .shortened))
                } else {
                    Button("×") {
                        removeNotification()
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundColor(.secondary)
            .multilineTextAlignment(.trailing)
            .frame(width: 80, alignment: .trailing)
        }
        .onHover { isHovered in
            hovered = isHovered
        }
    }
}

struct NotificationToolbarButton: View {
    @EnvironmentObject var notificationsVM: NotificationsVM
    
    @Binding var isPopupShown: Bool
    
    var body: some View {
        Button {
            isPopupShown.toggle()
        } label: {
            Group {
                if notificationsVM.isMuted {
                    Image(systemName: "bell.slash")
                } else if notificationsVM.hasNotifications {
                    Image(systemName: "bell.badge")
                } else {
                    Image(systemName: "bell")
                }
            }
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
