-- Clustering for Redis
IP Address : 
Master : 192.168.159.164 (Redis_Master_CentOS_7)
Slave  : 192.168.159.165 (Redis_Slave_1_CentOS_7)
Slave  : 192.168.159.166 (Redis_Slave_2_CentOS_7)

-- Pre on each node
[root@localhost ~]# yum update
[root@localhost ~]# yum install vim
[root@localhost ~]# yum install telnet
[root@localhost ~]# yum install firewalld
[root@localhost ~]# yum install net-tools
[root@localhost ~]# netstat -tupan

-- Step to Installing Redis (Redis_Master_CentOS_7)
1. We can install EPEL using yum on each node:
[root@localhost ~]# sudo yum install epel-release

2. Once the EPEL installation has finished you can install Redis, again using yum on each node:
[root@localhost ~]# sudo yum install redis -y

3.Setup required directories on each node
[root@localhost etc]# mkdir -p /etc/redis /var/run/redis /var/log/redis /var/redis/6379
[root@localhost etc]# cp redis.conf redis.conf.bak
[root@localhost etc]# cp redis-sentinel.conf redis-sentinel.conf.bak
[root@localhost etc]# cp redis.conf /etc/redis/6379.conf
[root@localhost etc]# cp redis-sentinel.conf /etc/redis/sentinel.conf

4.Add non-privileged user on each node
[root@localhost etc]# adduser redis -M -g redis
[root@localhost etc]# passwd -l redis
[root@localhost etc]# chown -R redis:redis /usr/local/bin/
[root@localhost etc]# chown -R redis:redis /var/run/redis
[root@localhost etc]# chown -R redis:redis /var/log/redis
[root@localhost etc]# chown -R redis:redis /var/redis/
[root@localhost etc]# chown -R redis:redis redis/
[root@localhost etc]# chmod -R 750 /usr/local/bin/
[root@localhost etc]# chmod -R 750 /var/run/redis
[root@localhost etc]# chmod -R 750 /var/log/redis
[root@localhost etc]# chmod -R 750 /var/redis/
[root@localhost etc]# chmod -R 750 redis/

5.Edit System settings on each node: /etc/sysctl.conf
[root@localhost etc]# vim /etc/sysctl.conf
/*
net.core.somaxconn = 4096
fs.file-max = 65536
vm.overcommit_memory = 1
*/

6.Disable transparent hugepage (transparent_hugepage=never) on each node: /etc/default/grub
[root@localhost etc]# vim /etc/default/grub
/*
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto transparent_hugepage=never rd.lvm.lv=centos/root rd.lvm.lv=centos/swap rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
*/

7.Apply grub config and reboot each node:
[root@localhost etc]# grub2-mkconfig -o /boot/grub2/grub.cfg
[root@localhost etc]# reboot

8.Setup required directories on each node:
[root@localhost etc]# mkdir -p /var/run/redis
[root@localhost etc]# chown -R redis:redis /var/run/redis
[root@localhost etc]# chmod -R 750 /var/run/redis

9.Master Node: /etc/redis/6379.conf
[root@localhost etc]# vim /etc/redis/6379.conf
/*
bind 192.168.159.164 127.0.0.1
port 6379
daemonize yes
supervised systemd
pidfile /var/run/redis.pid
loglevel notice
logfile "/var/log/redis/redis_6379.log"
dir /var/redis/6379
#masterauth password
#requirepass password
maxclients 65504
appendonly yes
appendfilename "redis-staging-ao.aof"
*/
--appendfilename "appendonly.aof"

10.Slave1 Node: /etc/redis/6379.conf
[root@localhost etc]# vim /etc/redis/6379.conf
/*
bind 192.168.159.165 127.0.0.1
port 6379
daemonize yes
supervised systemd
pidfile /var/run/redis.pid
loglevel notice
logfile "/var/log/redis/redis_6379.log"
dir /var/redis/6379
slaveof 192.168.159.164 6379
#masterauth password
#requirepass password
maxclients 65504
appendonly yes
appendfilename "redis-staging-ao.aof"
*/
--appendfilename "appendonly.aof"

11.Slave2 Node: /etc/redis/6379.conf
[root@localhost etc]# vim /etc/redis/6379.conf
/*
bind 192.168.159.166 127.0.0.1
port 6379
daemonize yes
supervised systemd
pidfile /var/run/redis.pid
loglevel notice
logfile "/var/log/redis/redis_6379.log"
dir /var/redis/6379
slaveof 192.168.159.164 6379
#masterauth password
#requirepass password
maxclients 65504
appendonly yes
appendfilename "redis-staging-ao.aof"
*/
--appendfilename "appendonly.aof"

12.Master Node: /etc/redis/sentinel.conf
[root@localhost etc]# vim /etc/redis/sentinel.conf
/*
bind 192.168.159.164
port 26379
sentinel monitor mymaster 192.168.159.164 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
#sentinel auth-pass mymaster password
logfile "/var/log/redis/sentinel.log"
*/

13.Slave1 Node: /etc/redis/sentinel.conf
[root@localhost etc]# vim /etc/redis/sentinel.conf
/*
bind 192.168.159.165
port 26379
sentinel monitor mymaster 192.168.159.164 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
#sentinel auth-pass mymaster password
logfile "/var/log/redis/sentinel.log"
*/

14.Slave2 Node: /etc/redis/sentinel.conf
[root@localhost etc]# vim /etc/redis/sentinel.conf
/*
bind 192.168.159.166
port 26379
sentinel monitor mymaster 192.168.159.164 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
#sentinel auth-pass mymaster password
logfile "/var/log/redis/sentinel.log"
*/

15.Copy the required file from sousrce to destination folder for each node
[root@localhost etc]# cp -r /usr/bin/redis-* /usr/local/bin/
[root@localhost etc]# chown -R redis:redis /usr/local/bin/

16.To start the Redis service and sentinel services:
[root@localhost ~]# systemctl enable redis
[root@localhost ~]# systemctl enable redis-sentinel

17.Each Node: /etc/systemd/system/multi-user.target.wants/redis.service
[root@localhost etc]# cd /etc/systemd/system/multi-user.target.wants/
[root@localhost multi-user.target.wants]# cp redis.service redis.service.bak
[root@localhost multi-user.target.wants]# vim /etc/systemd/system/multi-user.target.wants/redis.service
/*
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
Type=forking
User=redis
Group=redis
LimitNOFILE=65536
Environment=statedir=/var/run/redis
Environment=NOTIFY_SOCKET=""
PermissionsStartOnly=true
PIDFile=/var/run/redis/redis.pid
ExecStartPre=/bin/touch /var/log/redis/redis_6379.log
ExecStartPre=/bin/chown redis:redis /var/log/redis/redis_6379.log
ExecStartPre=/bin/mkdir -p ${statedir}
ExecStartPre=/bin/chown -R redis:redis ${statedir}
ExecStartPre=/usr/bin/echo never > /sys/kernel/mm/transparent_hugepage/enabled
ExecStart=/usr/local/bin/redis-server /etc/redis/6379.conf
ExecStop=/usr/local/bin/redis-cli shutdown
ExecReload=/bin/kill -USR2 $MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
*/

18.Each Node: /etc/systemd/system/multi-user.target.wants/redis-sentinel.service
[root@localhost etc]# cd /etc/systemd/system/multi-user.target.wants/
[root@localhost multi-user.target.wants]# cp redis-sentinel.service redis-sentinel.service.bak
[root@localhost multi-user.target.wants]# vim /etc/systemd/system/multi-user.target.wants/redis-sentinel.service
/*
[Unit]
Description=Redis Sentinel
After=network.target

[Service]
User=redis
Group=redis
Environment=statedir=/var/run/sentinel
PermissionsStartOnly=true
PIDFile=/var/run/sentinel/redis.pid
ExecStartPre=/bin/touch /var/log/redis/redis-sentinel.log
ExecStartPre=/bin/chown redis:redis /var/log/redis/redis-sentinel.log
ExecStartPre=/bin/mkdir -p ${statedir}
ExecStartPre=/bin/chown -R redis:redis ${statedir}
ExecStart=/usr/local/bin/redis-sentinel /etc/redis/sentinel.conf --daemonize no
ExecStop=/usr/local/bin/redis-cli -p 26379 shutdown
ExecReload=/bin/kill -USR2 $MAINPID
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
*/

19.Privide necessary privilages on each node
[root@localhost etc]# chmod -R 755 /var/log/redis/

20.To disable firewall
[root@localhost etc]# systemctl disable firewalld

21.After creating service files reload systemd and enable,start related services on each node:
[root@localhost etc]# systemctl daemon-reload
[root@localhost etc]# systemctl enable redis.service && systemctl start redis.service
[root@localhost etc]# systemctl enable redis-sentinel.service && systemctl start redis-sentinel.service
[root@localhost etc]# systemctl status redis.service
[root@localhost etc]# systemctl status redis-sentinel.service

22.To Restrat the server on each node
[root@localhost etc]# reboot

23.To Verify the Master Node: (redis)
[root@localhost etc]# redis-cli -h 192.168.159.164 -p 6379
192.168.159.164:6379> info replication
/*
# Replication
role:master
connected_slaves:2
slave0:ip=192.168.159.165,port=6379,state=online,offset=237329,lag=1
slave1:ip=192.168.159.166,port=6379,state=online,offset=237329,lag=1
master_repl_offset:237343
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:2
repl_backlog_histlen:237342
*/
192.168.159.164:6379> exit

24.To Verify the Master Node: (sentinel)
[root@localhost etc]# redis-cli -h 192.168.159.164 -p 26379
192.168.159.164:26379> sentinel master mymaster
/*
 1) "name"
 2) "mymaster"
 3) "ip"
 4) "192.168.159.164"
 5) "port"
 6) "6379"
 7) "runid"
 8) "2cdf110771fb0b53cc847595a618948390309631"
 9) "flags"
10) "master"
11) "link-pending-commands"
12) "0"
13) "link-refcount"
14) "1"
15) "last-ping-sent"
16) "0"
17) "last-ok-ping-reply"
18) "672"
19) "last-ping-reply"
20) "672"
21) "down-after-milliseconds"
22) "5000"
23) "info-refresh"
24) "1592"
25) "role-reported"
26) "master"
27) "role-reported-time"
28) "1173460"
29) "config-epoch"
30) "4"
31) "num-slaves"
32) "2"
33) "num-other-sentinels"
34) "2"
35) "quorum"
36) "2"
37) "failover-timeout"
38) "60000"
39) "parallel-syncs"
40) "1"
*/
192.168.159.164:26379>exit


25.To Verify the Slave Node: (redis)
[root@localhost etc]# redis-cli -h 192.168.159.165 -p 6379
192.168.159.165:6379> info replication
/*
# Replication
role:slave
master_host:192.168.159.164
master_port:6379
master_link_status:up
master_last_io_seconds_ago:0
master_sync_in_progress:0
slave_repl_offset:275716
slave_priority:100
slave_read_only:1
connected_slaves:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
*/
192.168.159.165:6379>

26.To Verify the Slave Node: (sentinel)
[root@localhost etc]# redis-cli -h 192.168.159.165 -p 26379
192.168.159.165:26379> sentinel slaves mymaster
/*
1)  1) "name"
    2) "192.168.159.165:6379"
    3) "ip"
    4) "192.168.159.165"
    5) "port"
    6) "6379"
    7) "runid"
    8) "3a734ee57f364c5c8d114555e481e82cb60293b7"
    9) "flags"
   10) "slave"
   11) "link-pending-commands"
   12) "0"
   13) "link-refcount"
   14) "1"
   15) "last-ping-sent"
   16) "0"
   17) "last-ok-ping-reply"
   18) "1002"
   19) "last-ping-reply"
   20) "1002"
   21) "down-after-milliseconds"
   22) "5000"
   23) "info-refresh"
   24) "4190"
   25) "role-reported"
   26) "slave"
   27) "role-reported-time"
   28) "1440157"
   29) "master-link-down-time"
   30) "0"
   31) "master-link-status"
   32) "ok"
   33) "master-host"
   34) "192.168.159.164"
   35) "master-port"
   36) "6379"
   37) "slave-priority"
   38) "100"
   39) "slave-repl-offset"
   40) "309435"
2)  1) "name"
    2) "192.168.159.166:6379"
    3) "ip"
    4) "192.168.159.166"
    5) "port"
    6) "6379"
    7) "runid"
    8) "78f5aaf47f6f3698f2a25a7012695ea64e338e83"
    9) "flags"
   10) "slave"
   11) "link-pending-commands"
   12) "0"
   13) "link-refcount"
   14) "1"
   15) "last-ping-sent"
   16) "0"
   17) "last-ok-ping-reply"
   18) "1002"
   19) "last-ping-reply"
   20) "1002"
   21) "down-after-milliseconds"
   22) "5000"
   23) "info-refresh"
   24) "7526"
   25) "role-reported"
   26) "slave"
   27) "role-reported-time"
   28) "1420063"
   29) "master-link-down-time"
   30) "0"
   31) "master-link-status"
   32) "ok"
   33) "master-host"
   34) "192.168.159.164"
   35) "master-port"
   36) "6379"
   37) "slave-priority"
   38) "100"
   39) "slave-repl-offset"
   40) "308710"
*/
192.168.159.165:26379>exit


27.To Verify the Slave Node: (redis)
[root@localhost etc]# redis-cli -h 192.168.159.166 -p 6379
192.168.159.166:6379> info replication
/*
# Replication
role:slave
master_host:192.168.159.164
master_port:6379
master_link_status:up
master_last_io_seconds_ago:1
master_sync_in_progress:0
slave_repl_offset:355998
slave_priority:100
slave_read_only:1
connected_slaves:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:2
repl_backlog_histlen:1792
*/
192.168.159.166:6379>exit

28.To Verify the Slave Node: (sentinel)
[root@localhost etc]# redis-cli -h 192.168.159.166 -p 26379
192.168.159.166:26379> sentinel slaves mymaster
/*
1)  1) "name"
    2) "192.168.159.165:6379"
    3) "ip"
    4) "192.168.159.165"
    5) "port"
    6) "6379"
    7) "runid"
    8) "3a734ee57f364c5c8d114555e481e82cb60293b7"
    9) "flags"
   10) "slave"
   11) "link-pending-commands"
   12) "0"
   13) "link-refcount"
   14) "1"
   15) "last-ping-sent"
   16) "0"
   17) "last-ok-ping-reply"
   18) "466"
   19) "last-ping-reply"
   20) "466"
   21) "down-after-milliseconds"
   22) "5000"
   23) "info-refresh"
   24) "8612"
   25) "role-reported"
   26) "slave"
   27) "role-reported-time"
   28) "1713990"
   29) "master-link-down-time"
   30) "0"
   31) "master-link-status"
   32) "ok"
   33) "master-host"
   34) "192.168.159.164"
   35) "master-port"
   36) "6379"
   37) "slave-priority"
   38) "100"
   39) "slave-repl-offset"
   40) "366653"
2)  1) "name"
    2) "192.168.159.166:6379"
    3) "ip"
    4) "192.168.159.166"
    5) "port"
    6) "6379"
    7) "runid"
    8) "78f5aaf47f6f3698f2a25a7012695ea64e338e83"
    9) "flags"
   10) "slave"
   11) "link-pending-commands"
   12) "0"
   13) "link-refcount"
   14) "1"
   15) "last-ping-sent"
   16) "0"
   17) "last-ok-ping-reply"
   18) "544"
   19) "last-ping-reply"
   20) "544"
   21) "down-after-milliseconds"
   22) "5000"
   23) "info-refresh"
   24) "5903"
   25) "role-reported"
   26) "slave"
   27) "role-reported-time"
   28) "1703851"
   29) "master-link-down-time"
   30) "0"
   31) "master-link-status"
   32) "ok"
   33) "master-host"
   34) "192.168.159.164"
   35) "master-port"
   36) "6379"
   37) "slave-priority"
   38) "100"
   39) "slave-repl-offset"
   40) "367378"
*/
192.168.159.166:26379>exit

29.Replication testing
   1.Connect with Master
     [root@localhost ~]# redis-cli -h 192.168.159.164 -p 6379
     192.168.159.164:6379> set rptest 1234
     OK
     192.168.159.164:6379>
   2.Connect with Slave Node 1 and verify the key
     [root@localhost ~]# redis-cli -h 192.168.159.165 -p 6379
     192.168.159.165:6379> get rptest
     "1234"
     192.168.159.165:6379>
   3.Connect with Slave Node 2 and verify the key
     [root@localhost ~]# redis-cli -h 192.168.159.166 -p 6379
     192.168.159.166:6379> get rptest
     "1234"
     192.168.159.166:6379>


30.Fail-over testing
   1.Connect with Master
     [root@localhost ~]# redis-cli -h 192.168.159.164 -p 26379
     192.168.159.164:26379> sentinel failover mymaster
     OK
     192.168.159.164:26379> sentinel masters
     /*
     1)  1) "name"
         2) "mymaster"
         3) "ip"
         4) "192.168.159.165"
         5) "port"
         6) "6379"
         7) "runid"
         8) "3a734ee57f364c5c8d114555e481e82cb60293b7"
         9) "flags"
        10) "master"
        11) "link-pending-commands"
        12) "0"
        13) "link-refcount"
        14) "1"
        15) "last-ping-sent"
        16) "0"
        17) "last-ok-ping-reply"
        18) "932"
        19) "last-ping-reply"
        20) "932"
        21) "down-after-milliseconds"
        22) "5000"
        23) "info-refresh"
        24) "4685"
        25) "role-reported"
        26) "master"
        27) "role-reported-time"
        28) "224002"
        29) "config-epoch"
        30) "5"
        31) "num-slaves"
        32) "2"
        33) "num-other-sentinels"
        34) "2"
        35) "quorum"
        36) "2"
        37) "failover-timeout"
        38) "60000"
        39) "parallel-syncs"
        40) "1"
     */
     192.168.159.164:26379>exit

     [root@localhost ~]# redis-cli -h 192.168.159.164 -p 6379
     192.168.159.164:6379> info replication
     /*
     # Replication
     role:slave
     master_host:192.168.159.165
     master_port:6379
     master_link_status:up
     master_last_io_seconds_ago:1
     master_sync_in_progress:0
     slave_repl_offset:489927
     slave_priority:100
     slave_read_only:1
     connected_slaves:0
     master_repl_offset:0
     repl_backlog_active:0
     repl_backlog_size:1048576
     repl_backlog_first_byte_offset:2
     repl_backlog_histlen:465076
     */
     192.168.159.164:6379>

   2.Connect with Slave Node 1 and verify
     [root@localhost ~]# redis-cli -h 192.168.159.165 -p 6379
     192.168.159.165:6379> info replication
     /*
     # Replication
     role:master
     connected_slaves:2
     slave0:ip=192.168.159.166,port=6379,state=online,offset=534011,lag=0
     slave1:ip=192.168.159.164,port=6379,state=online,offset=534011,lag=0
     master_repl_offset:534011
     repl_backlog_active:1
     repl_backlog_size:1048576
     repl_backlog_first_byte_offset:462875
     repl_backlog_histlen:71137
     */
     192.168.159.165:6379>exit

     [root@localhost ~]# redis-cli -h 192.168.159.165 -p 26379
     192.168.159.165:26379> sentinel masters
     /*
     1)  1) "name"
         2) "mymaster"
         3) "ip"
         4) "192.168.159.165"
         5) "port"
         6) "6379"
         7) "runid"
         8) "3a734ee57f364c5c8d114555e481e82cb60293b7"
         9) "flags"
        10) "master"
        11) "link-pending-commands"
        12) "0"
        13) "link-refcount"
        14) "1"
        15) "last-ping-sent"
        16) "0"
        17) "last-ok-ping-reply"
        18) "258"
        19) "last-ping-reply"
        20) "258"
        21) "down-after-milliseconds"
        22) "5000"
        23) "info-refresh"
        24) "2808"
        25) "role-reported"
        26) "master"
        27) "role-reported-time"
        28) "494541"
        29) "config-epoch"
        30) "5"
        31) "num-slaves"
        32) "2"
        33) "num-other-sentinels"
        34) "2"
        35) "quorum"
        36) "2"
        37) "failover-timeout"
        38) "60000"
        39) "parallel-syncs"
        40) "1"
     */
     192.168.159.165:26379>exit

   3.Connect with Slave Node 2 and verify
     [root@localhost ~]# redis-cli -h 192.168.159.166 -p 6379
     192.168.159.166:6379> info replication
     /*
     # Replication
     role:slave
     master_host:192.168.159.165
     master_port:6379
     master_link_status:up
     master_last_io_seconds_ago:0
     master_sync_in_progress:0
     slave_repl_offset:586402
     slave_priority:100
     slave_read_only:1
     connected_slaves:0
     master_repl_offset:0
     repl_backlog_active:0
     repl_backlog_size:1048576
     repl_backlog_first_byte_offset:2
     repl_backlog_histlen:1792
     */
     192.168.159.166:6379>exit

     [root@localhost ~]# redis-cli -h 192.168.159.166 -p 26379
     192.168.159.166:26379> sentinel slaves mymaster
     /*
     1)  1) "name"
         2) "192.168.159.164:6379"
         3) "ip"
         4) "192.168.159.164"
         5) "port"
         6) "6379"
         7) "runid"
         8) "2cdf110771fb0b53cc847595a618948390309631"
         9) "flags"
        10) "slave"
        11) "link-pending-commands"
        12) "0"
        13) "link-refcount"
        14) "1"
        15) "last-ping-sent"
        16) "0"
        17) "last-ok-ping-reply"
        18) "299"
        19) "last-ping-reply"
        20) "299"
        21) "down-after-milliseconds"
        22) "5000"
        23) "info-refresh"
        24) "4219"
        25) "role-reported"
        26) "slave"
        27) "role-reported-time"
        28) "637796"
        29) "master-link-down-time"
        30) "0"
        31) "master-link-status"
        32) "ok"
        33) "master-host"
        34) "192.168.159.165"
        35) "master-port"
        36) "6379"
        37) "slave-priority"
        38) "100"
        39) "slave-repl-offset"
        40) "599246"
     2)  1) "name"
         2) "192.168.159.166:6379"
         3) "ip"
         4) "192.168.159.166"
         5) "port"
         6) "6379"
         7) "runid"
         8) "78f5aaf47f6f3698f2a25a7012695ea64e338e83"
         9) "flags"
        10) "slave"
        11) "link-pending-commands"
        12) "0"
        13) "link-refcount"
        14) "1"
        15) "last-ping-sent"
        16) "0"
        17) "last-ok-ping-reply"
        18) "300"
        19) "last-ping-reply"
        20) "300"
        21) "down-after-milliseconds"
        22) "5000"
        23) "info-refresh"
        24) "4218"
        25) "role-reported"
        26) "slave"
        27) "role-reported-time"
        28) "647941"
        29) "master-link-down-time"
        30) "0"
        31) "master-link-status"
        32) "ok"
        33) "master-host"
        34) "192.168.159.165"
        35) "master-port"
        36) "6379"
        37) "slave-priority"
        38) "100"
        39) "slave-repl-offset"
        40) "599246"
     */
     192.168.159.166:26379>

31.Rollback the Fail-over testing
   1.Connect with Master
    [root@localhost ~]# redis-cli -h 192.168.159.165 -p 26379
    192.168.159.165:26379> sentinel failover mymaster
    OK
    192.168.159.165:26379> sentinel masters
    /*
    1)  1) "name"
        2) "mymaster"
        3) "ip"
        4) "192.168.159.164"
        5) "port"
        6) "6379"
        7) "runid"
        8) ""
        9) "flags"
       10) "master"
       11) "link-pending-commands"
       12) "0"
       13) "link-refcount"
       14) "1"
       15) "last-ping-sent"
       16) "0"
       17) "last-ok-ping-reply"
       18) "206"
       19) "last-ping-reply"
       20) "206"
       21) "down-after-milliseconds"
       22) "5000"
       23) "info-refresh"
       24) "4909"
       25) "role-reported"
       26) "master"
       27) "role-reported-time"
       28) "4418"
       29) "config-epoch"
       30) "6"
       31) "num-slaves"
       32) "2"
       33) "num-other-sentinels"
       34) "2"
       35) "quorum"
       36) "2"
       37) "failover-timeout"
       38) "60000"
       39) "parallel-syncs"
       40) "1"
    */
    192.168.159.165:26379>