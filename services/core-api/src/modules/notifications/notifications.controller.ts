import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../identity/jwt-auth.guard';

@Controller('v1/notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @Get()
  async getMyNotifications(@Req() req: any) {
    const customerId = req.user.sub;
    const notifications =
      await this.notificationsService.getCustomerNotifications(customerId);
    return { notifications };
  }

  @Get('unread-count')
  async getUnreadCount(@Req() req: any) {
    const customerId = req.user.sub;
    const count = await this.notificationsService.getUnreadCount(customerId);
    return { count };
  }

  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  async markAsRead(@Req() req: any, @Param('id') notificationId: string) {
    const customerId = req.user.sub;
    const success = await this.notificationsService.markAsRead(
      customerId,
      notificationId,
    );
    return { success };
  }

  @Post('mark-all-read')
  @HttpCode(HttpStatus.OK)
  async markAllAsRead(@Req() req: any) {
    const customerId = req.user.sub;
    const count = await this.notificationsService.markAllAsRead(customerId);
    return { count };
  }
}
