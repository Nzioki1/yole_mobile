import { Injectable } from '@nestjs/common';

export interface Notification {
  id: string;
  customerId: string;
  type: 'payment' | 'kyc' | 'system';
  title: string;
  message: string;
  read: boolean;
  createdAt: Date;
  data?: any;
}

@Injectable()
export class NotificationsService {
  private notifications: Map<string, Notification[]> = new Map();
  private notificationCounter = 0;

  /**
   * Get all notifications for a customer
   */
  async getCustomerNotifications(customerId: string): Promise<Notification[]> {
    const notifications = this.notifications.get(customerId) || [];
    return notifications.sort(
      (a, b) => b.createdAt.getTime() - a.createdAt.getTime(),
    );
  }

  /**
   * Add a notification for a customer
   */
  async addNotification(
    customerId: string,
    type: Notification['type'],
    title: string,
    message: string,
    data?: any,
  ): Promise<Notification> {
    const notification: Notification = {
      id: `notif_${++this.notificationCounter}`,
      customerId,
      type,
      title,
      message,
      read: false,
      createdAt: new Date(),
      data,
    };

    const customerNotifs = this.notifications.get(customerId) || [];
    customerNotifs.push(notification);
    this.notifications.set(customerId, customerNotifs);

    return notification;
  }

  /**
   * Mark a notification as read
   */
  async markAsRead(
    customerId: string,
    notificationId: string,
  ): Promise<boolean> {
    const notifications = this.notifications.get(customerId);
    if (!notifications) return false;

    const notification = notifications.find((n) => n.id === notificationId);
    if (!notification) return false;

    notification.read = true;
    return true;
  }

  /**
   * Mark all notifications as read for a customer
   */
  async markAllAsRead(customerId: string): Promise<number> {
    const notifications = this.notifications.get(customerId);
    if (!notifications) return 0;

    let count = 0;
    for (const notification of notifications) {
      if (!notification.read) {
        notification.read = true;
        count++;
      }
    }
    return count;
  }

  /**
   * Get unread count for a customer
   */
  async getUnreadCount(customerId: string): Promise<number> {
    const notifications = this.notifications.get(customerId) || [];
    return notifications.filter((n) => !n.read).length;
  }

  /**
   * Seed a welcome notification for new customers
   */
  async seedWelcomeNotification(customerId: string): Promise<void> {
    await this.addNotification(
      customerId,
      'system',
      'Welcome to Poste Finance! 🎉',
      'Your account is ready. Start sending money, paying bills, and more.',
    );
  }
}
