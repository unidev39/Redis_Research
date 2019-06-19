--How to Install and Secure Redis on Centos7

-- Step 1 — Installing Redis
1. We can install EPEL using yum:
[root@localhost ~]# sudo yum install epel-release

2. Once the EPEL installation has finished you can install Redis, again using yum:
[root@localhost ~]# sudo yum install redis -y

3.This may take a few minutes to complete. After the installation finishes, start the Redis service:
[root@localhost ~]# sudo systemctl start redis.service

4.If you’d like Redis to start on boot, you can enable it with the enable command:
[root@localhost ~]# sudo systemctl enable redis
/*
Created symlink from /etc/systemd/system/multi-user.target.wants/redis.service to /usr/lib/systemd/system/redis.service.
*/
5.You can check Redis’s status by running the following:
[root@localhost ~]# sudo systemctl status redis.service
/*
? redis.service - Redis persistent key-value database
   Loaded: loaded (/usr/lib/systemd/system/redis.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/redis.service.d
           +-limit.conf
   Active: active (running) since Wed 2019-06-12 01:59:05 +0545; 45s ago
 Main PID: 7045 (redis-server)
   CGroup: /system.slice/redis.service
           +-7045 /usr/bin/redis-server 127.0.0.1:6379

Jun 12 01:59:05 localhost.localdomain systemd[1]: Starting Redis persistent key-value database...
Jun 12 01:59:05 localhost.localdomain systemd[1]: Started Redis persistent key-value database.
*/

6.Once you’ve confirmed that Redis is indeed running, test the setup with this command:
[root@localhost ~]#redis-cli ping
/*
PONG
*/

-- Step 2 — Binding Redis
[root@localhost ~]# vi /etc/redis.conf
/*
#bind 127.0.0.1
bind 192.168.159.167
*/

[root@localhost ~]# sudo systemctl restart redis.service
[root@localhost ~]# systemctl status redis.service
/*
? redis.service - Redis persistent key-value database
   Loaded: loaded (/usr/lib/systemd/system/redis.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/redis.service.d
           +-limit.conf
   Active: active (running) since Wed 2019-06-12 02:30:24 +0545; 19s ago
  Process: 7240 ExecStop=/usr/libexec/redis-shutdown (code=exited, status=0/SUCCESS)
 Main PID: 7254 (redis-server)
   CGroup: /system.slice/redis.service
           +-7254 /usr/bin/redis-server 192.168.159.167:6379

Jun 12 02:30:24 localhost.localdomain systemd[1]: Stopped Redis persistent key-value database.
Jun 12 02:30:24 localhost.localdomain systemd[1]: Starting Redis persistent key-value database...
Jun 12 02:30:24 localhost.localdomain systemd[1]: Started Redis persistent key-value database.
*/

[root@localhost ~]# redis-cli -h 192.168.159.167 ping
/*
PONG
*/

--Step 3 - Configuring a Redis Password
[root@localhost ~]# vim /etc/redis.conf
/*
# requirepass foobared
requirepass P@ssw0rd
*/

[root@localhost ~]# systemctl restart redis.service
[root@localhost ~]# systemctl status redis.service
/*
? redis.service - Redis persistent key-value database
   Loaded: loaded (/usr/lib/systemd/system/redis.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/redis.service.d
           +-limit.conf
   Active: active (running) since Wed 2019-06-12 03:25:45 +0545; 9s ago
  Process: 7948 ExecStop=/usr/libexec/redis-shutdown (code=exited, status=0/SUCCESS)
 Main PID: 7963 (redis-server)
   CGroup: /system.slice/redis.service
           +-7963 /usr/bin/redis-server 192.168.159.167:6379

Jun 12 03:25:45 localhost.localdomain systemd[1]: Stopped Redis persistent...
Jun 12 03:25:45 localhost.localdomain systemd[1]: Starting Redis persisten...
Jun 12 03:25:45 localhost.localdomain systemd[1]: Started Redis persistent...
Hint: Some lines were ellipsized, use -l to show in full.
*/

[root@localhost ~]# redis-cli -h 192.168.159.167
192.168.159.167:6379> set mykey 100
/*
(error) NOAUTH Authentication required.
*/
192.168.159.167:6379> auth P@ssw0rd
/*
OK
*/
192.168.159.167:6379> get mykey
/*
(nil)
*/
192.168.159.167:6379> set mykey 100
/*
OK
*/
192.168.159.167:6379> get mykey
/*
"100"
*/
192.168.159.167:6379> exit

[root@localhost ~]# redis-cli -h 192.168.159.167
192.168.159.167:6379> auth P@ssw0rd
/*
OK
*/
192.168.159.167:6379> get mykey
/*
"100"
*/
192.168.159.167:6379> del mykey
/*
(integer) 1
*/
192.168.159.167:6379> get mykey
/*
(nil)
*/
192.168.159.167:6379> exit

--Step 4 - To Enable redis-sentinel
[root@localhost ~]# systemctl status redis-sentinel
/*
? redis-sentinel.service - Redis Sentinel
   Loaded: loaded (/usr/lib/systemd/system/redis-sentinel.service; disabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/redis-sentinel.service.d
           +-limit.conf
   Active: inactive (dead)
*/
[root@localhost ~]# systemctl start redis-sentinel
[root@localhost ~]# systemctl enable redis-sentinel
/*
Created symlink from /etc/systemd/system/multi-user.target.wants/redis-sentinel.service to /usr/lib/systemd/system/redis-sentinel.service.
*/
[root@localhost ~]# systemctl status redis-sentinel
/*
? redis-sentinel.service - Redis Sentinel
   Loaded: loaded (/usr/lib/systemd/system/redis-sentinel.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/redis-sentinel.service.d
           +-limit.conf
   Active: active (running) since Wed 2019-06-12 02:37:01 +0545; 19s ago
 Main PID: 7353 (redis-sentinel)
   CGroup: /system.slice/redis-sentinel.service
           +-7353 /usr/bin/redis-sentinel *:26379 [sentinel]

Jun 12 02:37:01 localhost.localdomain systemd[1]: Starting Redis Sentinel...
Jun 12 02:37:01 localhost.localdomain systemd[1]: Started Redis Sentinel.
*/

