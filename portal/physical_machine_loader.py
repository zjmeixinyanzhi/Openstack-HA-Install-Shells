#
# run the script after deploy cloud portal to initialize physical machine setting
# 1. physical machine data, including hypervisor id for compute node
# 2. physical machine type
# 3. physical machine monitor setting
# 4. physical machine alarm setting
#
# NOTE: run .keystome_admin before the script

import MySQLdb
import uuid
import os_client_config
import datetime

database_host = '192.168.2.211'
database_name = 'cloud'
database_username = 'root'
database_password = 'Gugong123'

def get_hypervisor_id(hostname): 
	# construct legancy client, using OS_ environment variables
	nova = os_client_config.make_client('compute')
	h = nova.hypervisors.find(hypervisor_hostname = hostname)
	return h.id

def main():
	conn = MySQLdb.connect(host = database_host, db = database_name, user = database_username, passwd = database_password, port = 3306, charset = 'utf8')
	cursor = conn.cursor()

	physical_machine_type_dict = {}
	sql = 'SELECT type_name, type_id FROM physical_machine_type'
	cursor.execute(sql)
	for row in cursor.fetchall():
		physical_machine_type_dict[row[0]] = row[1]

	machineFile = open('physical_machine_list.txt')
	for line in machineFile:
		prop = line.strip().split('|')
		host_name = prop[0].strip()
		machine_types = prop[1].strip().split(",")
		cpu_number = prop[2].strip()
		memory_size = prop[3].strip()
		disk_size = prop[4].strip()
		ip_address = prop[5].strip()
		services = prop[6].strip().split(",")

		sql = 'SELECT host_name FROM physical_machine WHERE host_name = %s' 
		n = cursor.execute(sql, host_name)
		if n > 0:
			print '%s already exist' % host_name
			continue

		# save version otherwise hibernate will add new record in merge() call
		hypervisor_id = ""
		if 'COMPUTE_NODE' in machine_types:
			hypervisor_id = get_hypervisor_id(host_name)

		print '%s, %s, %s, %s, %s, %s, %s, %s' % (host_name, machine_types, cpu_number, memory_size, disk_size, ip_address, services, hypervisor_id)

		print '\tmachine configuration'
		sql = 'INSERT INTO physical_machine(host_id, host_name, cpu_number, memory_size, disk_size, ip_address, hypervisor_id, status, create_time, version) VALUES(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)'
		host_id = uuid.uuid4()
		cursor.execute(sql, (host_id, host_name, cpu_number, memory_size, disk_size, ip_address, hypervisor_id, "ACTIVE", datetime.datetime.now(), 0))

		print '\tmachine type'
		for typeName in machine_types:
			typeId = physical_machine_type_dict[typeName]
			if (typeName == 'CONTROLLER_NODE') or (typeName == 'NETWORK_NODE') or (typeName == 'COMPUTE_NODE'):
				sql = 'INSERT INTO physical_machine_physical_machine_type(host_id, type_id) VALUES(%s, %s)'
				cursor.execute(sql, (host_id, typeId))

		print '\tmachine service monitor setting'
		for service in services:
			sql = "INSERT INTO monitor_setting(monitor_source, source_id, monitor_type, monitor_name, threshold, threshold_unit, severity_level, os_alarm_id, enabled, create_time, version) VALUES(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
			cursor.execute(sql, ("PHYSICAL_MACHINE", host_id, "SERVICE", service, None, None, 'NORMAL', None, 1, datetime.datetime.now(), 0))

		print '\tmachine load monitor setting'
		sql = 'SELECT monitor_name, default_threshold, threshold_unit, severity_level FROM monitor WHERE monitor_source = "PHYSICAL_MACHINE" AND monitor_type = "LOAD"'
		cursor.execute(sql)
		for row in cursor.fetchall():
			monitor_name = row[0]
			default_threshold = row[1]
			threshold_unit = row[2]
			severity_level = row[3]

			sql = "INSERT INTO monitor_setting(monitor_source, source_id, monitor_type, monitor_name, threshold, threshold_unit, severity_level, os_alarm_id, enabled, create_time, version) VALUES(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
			cursor.execute(sql, ("PHYSICAL_MACHINE", host_id, "LOAD", monitor_name, default_threshold, threshold_unit, severity_level, None, 1, datetime.datetime.now(), 0))

	cursor.close()

	conn.commit()
	conn.close()

if __name__ == "__main__": 
	main()
