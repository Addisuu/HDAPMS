import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { RolesModule } from './modules/roles/roles.module';
import { PermissionsModule } from './modules/permissions/permissions.module';
import { OrganizationUnitsModule } from './modules/organization-units/organization-units.module';
import { IndicatorsModule } from './modules/indicators/indicators.module';
import { DataValuesModule } from './modules/data-values/data-values.module';
import { ReportingPeriodsModule } from './modules/reporting-periods/reporting-periods.module';
import { TargetsModule } from './modules/targets/targets.module';
import { DashboardsModule } from './modules/dashboards/dashboards.module';
import { ReportsModule } from './modules/reports/reports.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AuditLogsModule } from './modules/audit-logs/audit-logs.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      username: process.env.DB_USERNAME || 'hdapms_user',
      password: process.env.DB_PASSWORD || 'hdapms_secure_password',
      database: process.env.DB_NAME || 'hdapms_db',
      entities: [__dirname + '/database/entities/**/*.entity{.ts,.js}'],
      migrations: [__dirname + '/database/migrations/**/*{.ts,.js}'],
      migrationsRun: false,
      synchronize: false,
      logging: process.env.NODE_ENV === 'development',
      ssl: process.env.DB_SSL === 'true',
    }),
    AuthModule,
    UsersModule,
    RolesModule,
    PermissionsModule,
    OrganizationUnitsModule,
    IndicatorsModule,
    DataValuesModule,
    ReportingPeriodsModule,
    TargetsModule,
    DashboardsModule,
    ReportsModule,
    NotificationsModule,
    AuditLogsModule,
    AnalyticsModule,
  ],
})
export class AppModule {}