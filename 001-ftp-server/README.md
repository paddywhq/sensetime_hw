# Simple FTP Server
## 环境配置
* 开发环境：Ubuntu 14.04.1
* 测试环境：Ruby 2.2.3
## 程序功能
* 启动方法：按照以下命令参数启动FTP Server
> Usage: 001-ftp-server/myftp.rb [options]
>   -p, --port=PORT                    listen port
>       --host=HOST                    binding address
>       --dir=DIR                      change current directory
>   -h                                 print help
* 实现命令：
  * USER/PASS
  * TYPE
  * PASV
  * LIST
  * CWD
  * PWD
  * RETR
  * STOR
* 日志记录：001-ftp-server/logfile.log
* 多线程/进程支持
## 程序实现
* 初始化部分：
  * $options：存server相关变量
  * option_parser: 解析cmd命令
  * $user_pass：存用户名及密码
  * $response：存回应客户端消息
  * $log：日志输出
* 命令执行部分：
  * pass_command：
    * 参数：user_name（用户名），command（命令），client（客户端）
    * 返回：是否登录成功
    * 实现：与$user_pass信息比对：成功返回true；失败返回false
  * user_command：
    * 参数：command（命令），client（客户端）
    * 返回：是否登录成功
    * 实现：与$user_pass信息比对：成功等待PASS命令，返回pass_command返回值；失败返回false
  * list_command：
    * 参数：command（命令），client（客户端）
    * 返回：无
    * 实现：利用PASV命令生成的端口，与客户端连接，发送当前目录下列表信息
  * cwd_command：
    * 参数：command（命令），client（客户端）
    * 返回：无
    * 实现：更新当前路径
  * pwd_command：
    * 参数：command（命令），client（客户端）
    * 返回：无
    * 实现：返回当前路径
  * retr_command：
    * 参数：command（命令），client（客户端）
    * 返回：无
    * 实现：利用PASV命令生成的端口，与客户端连接，发送二进制文件流
  * stor_command：
    * 参数：command（命令），client（客户端）
    * 返回：无
    * 实现：利用PASV命令生成的端口，与客户端连接，接受二进制文件流
  * pasv_command：
    * 参数：command（命令），client（客户端）
    * 返回：无
    * 实现：返回服务器IP和新端口
  * type_command：
    * 参数：command（命令），client（客户端）
    * 返回：无
    * 实现：判断是否为A或I
  * command_not_found
    * 参数：command（命令），client（客户端）
    * 返回：无
    * 实现：处理非法（未实现）命令
* 服务器启动：
  * 以命令参数新建服务器（默认：127.0.0.1:21 C:\）
  * 对于新连接客户端发送欢迎消息，等待USER命令
  * 对于已登录用户等待命令
