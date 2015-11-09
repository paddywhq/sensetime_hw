# SRake DSL

## 环境配置

* 开发环境：Ubuntu 14.04.1
* 测试环境：Ruby 2.2.3

## 程序功能

* 启动方法：按照以下命令参数启动SRake DSL
```
Usage: ./simplerake.rb [options] srake_file [task]
  -T                                 list tasks
  -h                                 print help
```
* 支持语法：
  * desc 'some description' 设置当前task的描述，将出现在simplerake -T中
  * task 支持task，task名字的类型都是Symbol
  * sh 'echo hello' 运行指定的Shell命令
  * 当用户不指定目标task时，自动运行default目标
  * 如果用户给出的Rakefile中任务依赖有环，给出报错信息

## 程序实现

* module SimpleRake：

  * class Task：
    * 类变量：
      * @name：task名
      * @description：task描述（默认为空字符串）
      * @prerequisites：先完成task（默认为空数组）
      * @block：task代码块（默认为nil）
    * 类函数：
      * initialize：
        * 参数：name（task名），description（task描述），prerequisites（先完成task），block（task代码块）
        * 实现：构造函数，初始化类变量

  * class Rakefile
    * 类变量：
      * @description：当前读到的描述（默认为空字符串），用于存即将读到task的描述
      * @task_list：task列表（默认为空数组），用于存rakefile中的所有task
    * 类函数：
      * initialize：
        * 参数：无
        * 实现：构造函数，初始化类变量
      * desc：
        * 参数：description（当前读到的描述）
        * 实现：存入@description
      * task：
        * 参数：name_prerequisites（task名和先完成task），&block（task代码块）
        * 实现：将name_prerequisites拆为name和prerequisites，新构造Task存入@task_list，后清空@description
      * sh：
        * 参数：command（命令）
        * 实现：运行command
      * list_tasks：
        * 参数：无
        * 实现：对@task_list中每个非default的task输出task名和task描述
      * run_task：
        * 参数：current_task_name（当前需运行的task名），executed_tasks_list（已运行过的或正等待运行的task名）
        * 实现：若current_task_name在executed_tasks_list中
                  若为正等待运行的task，有环报错
                  若为已运行过的task，退出
                将current_task_name加入executed_tasks_list中，设为正等待运行的task
                从@task_list中找出current_task_name对应的current_task
                运行每个current_task的先完成task
                运行current_task的代码块
                将current_task_name加入executed_tasks_list中，设为已运行过的task

* 程序启动：
  * 查看是否包含-T或-h
  * 新建SimpleRake::Rakefile类，读取并解析文件
  * 若包含-T调用list_tasks输出信息；若不包含-T调用run_task运行文件
