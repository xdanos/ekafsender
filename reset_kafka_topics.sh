#!/bin/bash
/home/securitycloud/kafka/kafka_2.9.2-0.8.2.1/bin/kafka-topics.sh --zookeeper sc7:2181 --delete --topic tst
/home/securitycloud/kafka/kafka_2.9.2-0.8.2.1/bin/kafka-topics.sh --zookeeper sc7:2181 --delete --topic out
/home/securitycloud/kafka/kafka_2.9.2-0.8.2.1/bin/kafka-topics.sh --zookeeper sc7:2181 --create --topic tst --partitions 100 --replication-factor 2
/home/securitycloud/kafka/kafka_2.9.2-0.8.2.1/bin/kafka-topics.sh --zookeeper sc7:2181 --create --topic out --partitions 1 --replication-factor 2
