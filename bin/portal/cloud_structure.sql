/*
Navicat MariaDB Data Transfer

Source Server         : root@192.168.100.201
Source Server Version : 100116
Source Host           : 192.168.100.201:3306
Source Database       : cloud

Target Server Type    : MariaDB
Target Server Version : 100116
File Encoding         : 65001

Date: 2017-11-30 22:01:50
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for application_tag
-- ----------------------------
DROP TABLE IF EXISTS `application_tag`;
CREATE TABLE `application_tag` (
  `id` varchar(255) NOT NULL,
  `create_time` datetime DEFAULT NULL,
  `creator` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `enabled` bit(1) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for disk
-- ----------------------------
DROP TABLE IF EXISTS `disk`;
CREATE TABLE `disk` (
  `disk_id` varchar(255) NOT NULL,
  `attach_point` varchar(255) DEFAULT NULL,
  `attach_time` datetime DEFAULT NULL,
  `capacity` int(11) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `creator` varchar(255) DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `disk_name` varchar(255) NOT NULL,
  `manager` varchar(255) DEFAULT NULL,
  `modify_time` datetime DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `valid_time` datetime DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `host_id` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`disk_id`),
  KEY `FK_iqnavjwp3hfr7fg1o8u91ftd1` (`host_id`),
  CONSTRAINT `FK_iqnavjwp3hfr7fg1o8u91ftd1` FOREIGN KEY (`host_id`) REFERENCES `virtual_machine` (`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for external_ip
-- ----------------------------
DROP TABLE IF EXISTS `external_ip`;
CREATE TABLE `external_ip` (
  `ip` varchar(16) NOT NULL,
  `device_id` varchar(64) DEFAULT NULL,
  `device_owner` varchar(255) DEFAULT NULL,
  `domain_id` varchar(64) DEFAULT NULL,
  `status` varchar(255) NOT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for monitor
-- ----------------------------
DROP TABLE IF EXISTS `monitor`;
CREATE TABLE `monitor` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `default_threshold` float DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `monitor_name` varchar(255) DEFAULT NULL,
  `monitor_source` varchar(255) DEFAULT NULL,
  `monitor_type` varchar(255) DEFAULT NULL,
  `severity_level` varchar(255) DEFAULT NULL,
  `threshold_unit` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for monitor_log
-- ----------------------------
DROP TABLE IF EXISTS `monitor_log`;
CREATE TABLE `monitor_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `check_time` datetime DEFAULT NULL,
  `message` varchar(255) DEFAULT NULL,
  `monitor_name` varchar(255) DEFAULT NULL,
  `monitor_source` varchar(255) DEFAULT NULL,
  `monitor_status` varchar(255) DEFAULT NULL,
  `monitor_type` varchar(255) DEFAULT NULL,
  `severity_level` varchar(255) DEFAULT NULL,
  `source_id` varchar(255) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for monitor_result
-- ----------------------------
DROP TABLE IF EXISTS `monitor_result`;
CREATE TABLE `monitor_result` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `monitor_name` varchar(255) DEFAULT NULL,
  `monitor_source` varchar(255) DEFAULT NULL,
  `monitor_status` varchar(255) DEFAULT NULL,
  `monitor_type` varchar(255) DEFAULT NULL,
  `source_id` varchar(255) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for monitor_setting
-- ----------------------------
DROP TABLE IF EXISTS `monitor_setting`;
CREATE TABLE `monitor_setting` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `create_time` datetime DEFAULT NULL,
  `enabled` bit(1) DEFAULT NULL,
  `monitor_name` varchar(255) DEFAULT NULL,
  `monitor_source` varchar(255) DEFAULT NULL,
  `monitor_type` varchar(255) DEFAULT NULL,
  `os_alarm_id` varchar(255) DEFAULT NULL,
  `severity_level` varchar(255) DEFAULT NULL,
  `source_id` varchar(255) DEFAULT NULL,
  `threshold` float DEFAULT NULL,
  `threshold_unit` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for operation_log
-- ----------------------------
DROP TABLE IF EXISTS `operation_log`;
CREATE TABLE `operation_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `object_id` varchar(255) DEFAULT NULL,
  `operation` varchar(255) DEFAULT NULL,
  `operation_result` varchar(255) DEFAULT NULL,
  `operation_status` varchar(255) DEFAULT NULL,
  `operation_time` datetime DEFAULT NULL,
  `operator` varchar(255) DEFAULT NULL,
  `service_name` varchar(255) DEFAULT NULL,
  `severity_level` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for physical_machine
-- ----------------------------
DROP TABLE IF EXISTS `physical_machine`;
CREATE TABLE `physical_machine` (
  `host_id` varchar(255) NOT NULL,
  `cpu_number` int(11) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `disk_size` float DEFAULT NULL,
  `host_name` varchar(255) DEFAULT NULL,
  `hypervisor_id` varchar(255) DEFAULT NULL,
  `ip_address` varchar(255) DEFAULT NULL,
  `memory_size` float DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `verified` bit(1) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for physical_machine_load
-- ----------------------------
DROP TABLE IF EXISTS `physical_machine_load`;
CREATE TABLE `physical_machine_load` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `bytes_in` float DEFAULT NULL,
  `bytes_out` float DEFAULT NULL,
  `cpu_idle` float DEFAULT NULL,
  `cpu_load` float DEFAULT NULL,
  `cpu_system` float DEFAULT NULL,
  `cpu_user` float DEFAULT NULL,
  `free_disk` float DEFAULT NULL,
  `free_memory` float DEFAULT NULL,
  `host_name` varchar(255) DEFAULT NULL,
  `report_time` datetime DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19395 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for physical_machine_physical_machine_type
-- ----------------------------
DROP TABLE IF EXISTS `physical_machine_physical_machine_type`;
CREATE TABLE `physical_machine_physical_machine_type` (
  `host_id` varchar(255) NOT NULL,
  `type_id` varchar(255) NOT NULL,
  PRIMARY KEY (`host_id`,`type_id`),
  KEY `FK_4o1y1ykout1ply623immaoxu6` (`type_id`),
  CONSTRAINT `FK_4o1y1ykout1ply623immaoxu6` FOREIGN KEY (`type_id`) REFERENCES `physical_machine_type` (`type_id`),
  CONSTRAINT `FK_k6qnaagh5sgkg9ni2beh6wopg` FOREIGN KEY (`host_id`) REFERENCES `physical_machine` (`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for physical_machine_type
-- ----------------------------
DROP TABLE IF EXISTS `physical_machine_type`;
CREATE TABLE `physical_machine_type` (
  `type_id` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `type_name` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for role
-- ----------------------------
DROP TABLE IF EXISTS `role`;
CREATE TABLE `role` (
  `role_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `description` varchar(255) DEFAULT NULL,
  `role_name` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for snapshot
-- ----------------------------
DROP TABLE IF EXISTS `snapshot`;
CREATE TABLE `snapshot` (
  `snapshot_id` varchar(255) NOT NULL,
  `create_time` datetime DEFAULT NULL,
  `creator` varchar(255) DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `size` bigint(20) NOT NULL,
  `snapshot_name` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `host_id` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`snapshot_id`),
  KEY `FK_sef57rjbc5u7148r3vyral0ee` (`host_id`),
  CONSTRAINT `FK_sef57rjbc5u7148r3vyral0ee` FOREIGN KEY (`host_id`) REFERENCES `virtual_machine` (`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `user_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `create_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  `department` varchar(255) DEFAULT NULL,
  `disable_time` datetime DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `enable_time` datetime DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `real_name` varchar(255) DEFAULT NULL,
  `session_id` varchar(255) DEFAULT NULL,
  `snapshot_quota` int(11) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `role_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  KEY `FK_qleu8ddawkdltal07p8e6hgva` (`role_id`),
  CONSTRAINT `FK_qleu8ddawkdltal07p8e6hgva` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for virtual_machine
-- ----------------------------
DROP TABLE IF EXISTS `virtual_machine`;
CREATE TABLE `virtual_machine` (
  `host_id` varchar(255) NOT NULL,
  `cpu` int(11) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `creator` varchar(255) DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `disk` int(11) DEFAULT NULL,
  `domain_id` varchar(255) DEFAULT NULL,
  `floating_ip` varchar(255) DEFAULT NULL,
  `group_id` varchar(255) DEFAULT NULL,
  `host_name` varchar(255) DEFAULT NULL,
  `hypervisor_name` varchar(255) DEFAULT NULL,
  `image_name` varchar(255) DEFAULT NULL,
  `manager` varchar(255) DEFAULT NULL,
  `memory` int(11) DEFAULT NULL,
  `modify_time` datetime DEFAULT NULL,
  `private_ip` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `task_status` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for virtual_machine_application_tag
-- ----------------------------
DROP TABLE IF EXISTS `virtual_machine_application_tag`;
CREATE TABLE `virtual_machine_application_tag` (
  `host_id` varchar(255) NOT NULL,
  `app_id` varchar(255) NOT NULL,
  PRIMARY KEY (`host_id`,`app_id`),
  KEY `FK_nnatq6y72k411p3h4kukiy2km` (`app_id`),
  CONSTRAINT `FK_4mp5rpnyi0m6qp46t40xtol7l` FOREIGN KEY (`host_id`) REFERENCES `virtual_machine` (`host_id`),
  CONSTRAINT `FK_nnatq6y72k411p3h4kukiy2km` FOREIGN KEY (`app_id`) REFERENCES `application_tag` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for virtual_machine_domain
-- ----------------------------
DROP TABLE IF EXISTS `virtual_machine_domain`;
CREATE TABLE `virtual_machine_domain` (
  `domain_id` varchar(255) NOT NULL,
  `cpu` int(11) NOT NULL,
  `create_time` datetime NOT NULL,
  `creator` varchar(255) NOT NULL,
  `delete_time` datetime DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `disk` int(11) NOT NULL,
  `domain_name` varchar(255) NOT NULL,
  `instances` int(11) NOT NULL,
  `memory` int(11) NOT NULL,
  `status` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`domain_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for virtual_machine_group
-- ----------------------------
DROP TABLE IF EXISTS `virtual_machine_group`;
CREATE TABLE `virtual_machine_group` (
  `group_id` varchar(255) NOT NULL,
  `cpu` int(11) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `creator` varchar(255) DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `disk` int(11) DEFAULT NULL,
  `domain_id` varchar(255) DEFAULT NULL,
  `group_name` varchar(255) DEFAULT NULL,
  `instances` int(11) DEFAULT NULL,
  `memory` int(11) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  PRIMARY KEY (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
