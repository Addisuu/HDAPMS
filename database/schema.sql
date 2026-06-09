-- HDAPMS PostgreSQL Schema
-- Health Data Analytics & Performance Monitoring System
-- Complete database schema with all tables, relationships, and constraints

-- Drop existing objects (for fresh setup)
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- CORE ENTITIES
-- ============================================================

-- Roles Table
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_roles_name ON roles(name);
CREATE INDEX idx_roles_is_active ON roles(is_active);

-- Permissions Table
CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    resource VARCHAR(100),
    action VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_permissions_name ON permissions(name);
CREATE INDEX idx_permissions_resource_action ON permissions(resource, action);

-- Role Permissions Junction Table
CREATE TABLE role_permissions (
    id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);

-- ============================================================
-- ORGANIZATION HIERARCHY
-- ============================================================

-- Organization Unit Types
CREATE TABLE organization_unit_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    level INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_org_unit_types_level ON organization_unit_types(level);

-- Organization Units (Hierarchical)
CREATE TABLE organization_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES organization_units(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    organization_unit_type_id INTEGER NOT NULL REFERENCES organization_unit_types(id),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    contact_person VARCHAR(255),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_org_units_parent_id ON organization_units(parent_id);
CREATE INDEX idx_org_units_code ON organization_units(code);
CREATE INDEX idx_org_units_type_id ON organization_units(organization_unit_type_id);
CREATE INDEX idx_org_units_is_active ON organization_units(is_active);
CREATE INDEX idx_org_units_deleted_at ON organization_units(deleted_at);

-- ============================================================
-- USERS
-- ============================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_unit_id UUID NOT NULL REFERENCES organization_units(id),
    email VARCHAR(100) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    job_title VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    password_changed_at TIMESTAMP,
    last_login_at TIMESTAMP,
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    email_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMP,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_organization_unit_id ON users(organization_unit_id);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_deleted_at ON users(deleted_at);

-- User Roles Junction Table
CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, role_id)
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);

-- ============================================================
-- INDICATORS
-- ============================================================

CREATE TABLE indicator_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    code VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_indicator_categories_code ON indicator_categories(code);
CREATE INDEX idx_indicator_categories_is_active ON indicator_categories(is_active);

CREATE TABLE indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    indicator_category_id UUID NOT NULL REFERENCES indicator_categories(id),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    numerator VARCHAR(255),
    denominator VARCHAR(255),
    formula TEXT,
    calculation_type VARCHAR(50),
    unit VARCHAR(50),
    frequency VARCHAR(50),
    data_type VARCHAR(50) DEFAULT 'numeric',
    disaggregation_type VARCHAR(100),
    is_composite BOOLEAN DEFAULT FALSE,
    parent_indicator_id UUID REFERENCES indicators(id) ON DELETE SET NULL,
    target_value DECIMAL(15, 2),
    baseline_value DECIMAL(15, 2),
    baseline_year INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_indicators_code ON indicators(code);
CREATE INDEX idx_indicators_category_id ON indicators(indicator_category_id);
CREATE INDEX idx_indicators_is_composite ON indicators(is_composite);
CREATE INDEX idx_indicators_is_active ON indicators(is_active);
CREATE INDEX idx_indicators_deleted_at ON indicators(deleted_at);

-- ============================================================
-- REPORTING PERIODS
-- ============================================================

CREATE TABLE reporting_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    period_type VARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    due_date DATE,
    submission_deadline DATE,
    is_locked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    UNIQUE(name, start_date, end_date)
);

CREATE INDEX idx_reporting_periods_type ON reporting_periods(period_type);
CREATE INDEX idx_reporting_periods_start_date ON reporting_periods(start_date);
CREATE INDEX idx_reporting_periods_end_date ON reporting_periods(end_date);

-- ============================================================
-- TARGETS
-- ============================================================

CREATE TABLE targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    indicator_id UUID NOT NULL REFERENCES indicators(id) ON DELETE CASCADE,
    organization_unit_id UUID NOT NULL REFERENCES organization_units(id),
    reporting_period_id UUID NOT NULL REFERENCES reporting_periods(id),
    target_value DECIMAL(15, 2) NOT NULL,
    baseline_value DECIMAL(15, 2),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    UNIQUE(indicator_id, organization_unit_id, reporting_period_id)
);

CREATE INDEX idx_targets_indicator_id ON targets(indicator_id);
CREATE INDEX idx_targets_organization_unit_id ON targets(organization_unit_id);
CREATE INDEX idx_targets_reporting_period_id ON targets(reporting_period_id);

-- ============================================================
-- DATA VALUES
-- ============================================================

CREATE TABLE data_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    indicator_id UUID NOT NULL REFERENCES indicators(id),
    organization_unit_id UUID NOT NULL REFERENCES organization_units(id),
    reporting_period_id UUID NOT NULL REFERENCES reporting_periods(id),
    numerator_value DECIMAL(15, 2),
    denominator_value DECIMAL(15, 2),
    calculated_value DECIMAL(15, 2),
    data_value TEXT,
    comment TEXT,
    approval_status VARCHAR(50) DEFAULT 'draft',
    approval_status_updated_at TIMESTAMP,
    approval_comment TEXT,
    approved_by UUID,
    approved_at TIMESTAMP,
    submitted_at TIMESTAMP,
    submitted_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    deleted_at TIMESTAMP,
    UNIQUE(indicator_id, organization_unit_id, reporting_period_id)
);

CREATE INDEX idx_data_values_indicator_id ON data_values(indicator_id);
CREATE INDEX idx_data_values_organization_unit_id ON data_values(organization_unit_id);
CREATE INDEX idx_data_values_reporting_period_id ON data_values(reporting_period_id);
CREATE INDEX idx_data_values_approval_status ON data_values(approval_status);
CREATE INDEX idx_data_values_created_at ON data_values(created_at);
CREATE INDEX idx_data_values_deleted_at ON data_values(deleted_at);

-- ============================================================
-- DATA QUALITY
-- ============================================================

CREATE TABLE data_quality_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    check_type VARCHAR(100),
    rule_definition JSONB,
    severity_level VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID
);

CREATE INDEX idx_data_quality_checks_type ON data_quality_checks(check_type);

CREATE TABLE data_quality_issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_value_id UUID REFERENCES data_values(id) ON DELETE CASCADE,
    data_quality_check_id UUID NOT NULL REFERENCES data_quality_checks(id),
    issue_type VARCHAR(100),
    severity_level VARCHAR(50),
    description TEXT,
    resolution_status VARCHAR(50) DEFAULT 'pending',
    resolved_at TIMESTAMP,
    resolved_by UUID,
    resolution_note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_data_quality_issues_data_value_id ON data_quality_issues(data_value_id);
CREATE INDEX idx_data_quality_issues_status ON data_quality_issues(resolution_status);

CREATE TABLE data_quality_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_unit_id UUID NOT NULL REFERENCES organization_units(id),
    reporting_period_id UUID NOT NULL REFERENCES reporting_periods(id),
    completeness_score DECIMAL(5, 2),
    timeliness_score DECIMAL(5, 2),
    consistency_score DECIMAL(5, 2),
    overall_score DECIMAL(5, 2),
    calculated_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_unit_id, reporting_period_id)
);

CREATE INDEX idx_data_quality_scores_org_unit ON data_quality_scores(organization_unit_id);
CREATE INDEX idx_data_quality_scores_period ON data_quality_scores(reporting_period_id);

-- ============================================================
-- DASHBOARDS
-- ============================================================

CREATE TABLE dashboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    dashboard_type VARCHAR(100),
    layout JSONB,
    created_by UUID NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_dashboards_type ON dashboards(dashboard_type);
CREATE INDEX idx_dashboards_created_by ON dashboards(created_by);
CREATE INDEX idx_dashboards_is_public ON dashboards(is_public);

CREATE TABLE dashboard_widgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dashboard_id UUID NOT NULL REFERENCES dashboards(id) ON DELETE CASCADE,
    widget_type VARCHAR(100),
    title VARCHAR(255),
    description TEXT,
    position_x INTEGER,
    position_y INTEGER,
    width INTEGER,
    height INTEGER,
    widget_config JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dashboard_widgets_dashboard_id ON dashboard_widgets(dashboard_id);

-- ============================================================
-- REPORTS
-- ============================================================

CREATE TABLE report_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    template_type VARCHAR(100),
    template_config JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID
);

CREATE INDEX idx_report_templates_type ON report_templates(template_type);

CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_template_id UUID REFERENCES report_templates(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    report_type VARCHAR(100),
    organization_unit_id UUID REFERENCES organization_units(id),
    reporting_period_id UUID REFERENCES reporting_periods(id),
    generated_by UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    file_path VARCHAR(500),
    file_size INTEGER,
    error_message TEXT,
    scheduled_at TIMESTAMP,
    generated_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_reports_template_id ON reports(report_template_id);
CREATE INDEX idx_reports_organization_unit_id ON reports(organization_unit_id);
CREATE INDEX idx_reports_reporting_period_id ON reports(reporting_period_id);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_generated_at ON reports(generated_at);

-- ============================================================
-- APPROVAL WORKFLOWS
-- ============================================================

CREATE TABLE approval_workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    workflow_type VARCHAR(100),
    levels JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID
);

CREATE TABLE approval_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    approval_workflow_id UUID NOT NULL REFERENCES approval_workflows(id),
    reference_type VARCHAR(100),
    reference_id UUID NOT NULL,
    current_level INTEGER,
    total_levels INTEGER,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX idx_approval_instances_workflow_id ON approval_instances(approval_workflow_id);
CREATE INDEX idx_approval_instances_status ON approval_instances(status);

CREATE TABLE approval_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    approval_instance_id UUID NOT NULL REFERENCES approval_instances(id) ON DELETE CASCADE,
    step_level INTEGER NOT NULL,
    approver_id UUID REFERENCES users(id),
    approver_role_id INTEGER REFERENCES roles(id),
    status VARCHAR(50) DEFAULT 'pending',
    comment TEXT,
    action_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_steps_instance_id ON approval_steps(approval_instance_id);
CREATE INDEX idx_approval_steps_level ON approval_steps(step_level);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(100),
    action_url VARCHAR(500),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    email_on_report_due BOOLEAN DEFAULT TRUE,
    email_on_approval_required BOOLEAN DEFAULT TRUE,
    email_on_data_quality_issue BOOLEAN DEFAULT TRUE,
    email_on_target_achievement BOOLEAN DEFAULT FALSE,
    in_app_notifications BOOLEAN DEFAULT TRUE,
    notification_frequency VARCHAR(50) DEFAULT 'immediate',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- AUDIT LOGS
-- ============================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    status VARCHAR(50) DEFAULT 'success',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_resource_id ON audit_logs(resource_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

CREATE TABLE login_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    username VARCHAR(100),
    email VARCHAR(100),
    login_status VARCHAR(50),
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    device_info JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_login_logs_user_id ON login_logs(user_id);
CREATE INDEX idx_login_logs_status ON login_logs(login_status);
CREATE INDEX idx_login_logs_created_at ON login_logs(created_at);

-- ============================================================
-- ATTACHMENTS
-- ============================================================

CREATE TABLE attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference_type VARCHAR(100),
    reference_id UUID,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER,
    file_type VARCHAR(50),
    s3_key VARCHAR(500),
    uploaded_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_attachments_reference_type ON attachments(reference_type);
CREATE INDEX idx_attachments_reference_id ON attachments(reference_id);

-- ============================================================
-- SETTINGS
-- ============================================================

CREATE TABLE settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(255) NOT NULL UNIQUE,
    setting_value TEXT,
    setting_type VARCHAR(50),
    description TEXT,
    organization_unit_id UUID REFERENCES organization_units(id),
    is_global BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID
);

CREATE INDEX idx_settings_key ON settings(setting_key);
CREATE INDEX idx_settings_organization_unit_id ON settings(organization_unit_id);

-- ============================================================
-- SEED INITIAL DATA
-- ============================================================

-- Insert Organization Unit Types
INSERT INTO organization_unit_types (name, level, description) VALUES
('National', 1, 'National Health Authority'),
('Region', 2, 'Regional Health Bureau'),
('Zone', 3, 'Zonal Health Office'),
('Woreda', 4, 'Woreda Health Office'),
('Health Facility', 5, 'Public or Private Health Facility'),
('Department', 6, 'Health Department');

-- Insert Roles
INSERT INTO roles (name, description) VALUES
('Super Admin', 'Complete system access'),
('National Admin', 'National level management'),
('Regional Admin', 'Regional level management'),
('Zone Admin', 'Zonal level management'),
('Woreda Admin', 'Woreda level management'),
('Facility User', 'Data entry at facility level'),
('Data Analyst', 'Analytics and reporting'),
('Viewer', 'Read-only access'),
('Auditor', 'Audit trail access');

-- Insert Permissions
INSERT INTO permissions (name, description, resource, action) VALUES
('view_dashboard', 'View dashboards', 'dashboard', 'read'),
('create_dashboard', 'Create dashboards', 'dashboard', 'create'),
('edit_dashboard', 'Edit dashboards', 'dashboard', 'update'),
('delete_dashboard', 'Delete dashboards', 'dashboard', 'delete'),
('view_data', 'View data values', 'data', 'read'),
('create_data', 'Create data entries', 'data', 'create'),
('edit_data', 'Edit data entries', 'data', 'update'),
('delete_data', 'Delete data entries', 'data', 'delete'),
('approve_data', 'Approve data values', 'data', 'approve'),
('view_reports', 'View reports', 'report', 'read'),
('create_reports', 'Create reports', 'report', 'create'),
('manage_users', 'Manage users', 'user', 'manage'),
('manage_indicators', 'Manage indicators', 'indicator', 'manage'),
('view_audit_logs', 'View audit logs', 'audit', 'read'),
('manage_organization', 'Manage organization', 'organization', 'manage'),
('manage_settings', 'Manage system settings', 'settings', 'manage');

-- Insert Indicator Categories
INSERT INTO indicator_categories (name, code, description) VALUES
('Maternal Health', 'MATERNAL', 'Maternal health indicators'),
('Child Health', 'CHILD', 'Child health indicators'),
('Communicable Diseases', 'CD', 'Communicable disease indicators'),
('Immunization', 'IMMUN', 'Immunization coverage indicators'),
('Family Planning', 'FP', 'Family planning indicators'),
('Nutrition', 'NUTR', 'Nutrition indicators'),
('HIV/AIDS', 'HIV', 'HIV/AIDS related indicators');
