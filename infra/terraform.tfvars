region      = "us-gov-west-1"
name_prefix = "mountport-dsd"
vpc_name    = "mountport-core"

broker_count         = 3
broker_instance_type = "kafka.m5.large"
broker_storage_gb    = 200

database_instance_class = "db.m6g.large"
database_storage_gb     = 100
