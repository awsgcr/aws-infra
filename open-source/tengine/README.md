#### 二进制文件编译安装

准备Amazon Linux 2基础环境

```bash
$ df -h
Filesystem        Size  Used Avail Use% Mounted on
devtmpfs          4.0M     0  4.0M   0% /dev
tmpfs             1.9G     0  1.9G   0% /dev/shm
tmpfs             758M  8.5M  749M   2% /run
/dev/nvme0n1p1     50G  1.9G   49G   4% /
tmpfs             1.9G     0  1.9G   0% /tmp
/dev/nvme1n1      200G  1.5G  199G   1% /data
/dev/nvme0n1p128   10M  1.3M  8.7M  13% /boot/efi
tmpfs             379M     0  379M   0% /run/user/0
$ lsblk
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
nvme1n1       259:0    0  200G  0 disk /data
nvme0n1       259:1    0   50G  0 disk
├─nvme0n1p1   259:2    0   50G  0 part /
├─nvme0n1p127 259:3    0    1M  0 part
└─nvme0n1p128 259:4    0   10M  0 part /boot/efi
```

##### 安装基础依赖项

```bash
sudo yum install -y gcc gcc-c++ automake pcre-devel zlib-devel openssl-devel
```

##### 安装jemalloc依赖

让Tengine链接jemalloc库，运行时用jemalloc来分配和释放内存。

```bash
cd /tmp
curl -s -L https://github.com/jemalloc/jemalloc/releases/download/4.4.0/jemalloc-4.4.0.tar.bz2 -o jemalloc-4.4.0.tar.bz2 \
&&  tar xvf jemalloc-4.4.0.tar.bz2 \
&&  cp -r jemalloc-4.4.0 /usr/local/src/jemalloc \
&&  cd /usr/local/src/jemalloc \
&&  ./configure --prefix=/usr/local/jemalloc \
&&  make && make install
```

##### 安装zlib依赖

```bash
cd /tmp
curl -s -L http://www.zlib.net/fossils/zlib-1.2.11.tar.gz -o zlib-1.2.11.tar.gz \
&&  tar zxvf zlib-1.2.11.tar.gz \
&&  cp -r zlib-1.2.11 /usr/local/src/zlib \
&&  cd  /usr/local/src/zlib \
&&  ./configure --prefix=/usr/local/zlib \
&&  make && make install
```

##### 安装pcre依赖

```bash
cd /tmp
curl -s -L https://jaist.dl.sourceforge.net/project/pcre/pcre/8.43/pcre-8.43.tar.gz -o pcre-8.43.tar.gz \
&&  tar zxvf pcre-8.43.tar.gz \
&&  cp -r pcre-8.43 /usr/local/src/pcre \
&&  cd  /usr/local/src/pcre \
&&  ./configure --prefix=/usr/local/pcre \
&&  make && make install
```

##### 下载Tengine源代码

```bash
cd /tmp
mkdir -p /tmp/tengine \
&&  wget http://tengine.taobao.org/download/tengine-2.4.0.tar.gz \
&&  tar zxvf tengine-2.4.0.tar.gz
```

##### 创建nginx用户

```bash
useradd -s /sbin/nologin -M nginx
```

##### 配置编译选项

```bash
./configure \
    --prefix=/etc/nginx \
    --user=nginx \
    --group=nginx \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --with-pcre=/usr/local/src/pcre \
    --with-zlib=/usr/local/src/zlib \
    --with-jemalloc=/usr/local/src/jemalloc \
    --with-http_gzip_static_module \
    --with-http_sub_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --error-log-path=/data/log/nginx/error.log \
    --http-log-path=/data/log/nginx/access.log \
    --with-http_gunzip_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --add-module=./modules/ngx_http_upstream_check_module \
    --add-module=./modules/ngx_http_upstream_dynamic_module \
    --add-module=./modules/ngx_http_reqstat_module \
    --with-file-aio
```

##### 编译并安装

```bash
make && sudo make install
```

##### 设置目录属主属组

```bash
chown -R nginx:nginx /etc/nginx
```

##### 设置软连接

```bash
ln -sv /etc/nginx/sbin/nginx /usr/sbin/nginx
```

##### 启动服务

```bash
$ nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
$ nginx
$ netstat -tpln
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1680/sshd: /usr/sbi
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      69128/nginx: master
tcp6       0      0 :::22                   :::*                    LISTEN      1680/sshd: /usr/sbi
确认日志存储在EBS磁盘/data，而不是在Root根卷
$ pwd
/data/log/nginx
$ ll
total 4
-rw-r--r--. 1 root root   0 Dec 29 13:50 access.log
-rw-r--r--. 1 root root 120 Dec 29 13:47 error.log
[root@ip-10-80-4-20 nginx]#
```

##### 参考链接

https://www.cnblogs.com/evescn/p/17336281.html