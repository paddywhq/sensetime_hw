require 'optparse'

#SimpleRake
module SimpleRake

  #Task
  class Task

    attr_reader :name, :description, :prerequisites, :block

    def initialize name, description = '', prerequisites = [], block = nil
      @description = description
      @name = name
      @prerequisites = prerequisites
      @block = block
    end  #def initialize

  end  #class Task

  #parse and run Rakefile
  class Rakefile

    def initialize
      @description = ''
      @task_list = []
    end  #def initialize

    #desc command
    def desc description
      @description = description
    end  #def desc

    #task command
    def task name_prerequisites, &block
      case name_prerequisites
      when Symbol
        name = name_prerequisites
        prerequisites = []
      when Hash
        name_prerequisites.each do
          |key, value|
          name = key
          prerequisites = value.is_a?(Symbol) ? [value] : value
        end
      end
      @task_list << Task.new(name, @description, prerequisites, block)
      @description = ''
    end  #def task

    #sh command
    def sh command
      system command
    end  #def sh

    #-T list tasks
    def list_tasks
      @task_list.each do
        |task|
        puts "#{task.name}\t\t# #{task.description}" if task.name != :default
      end
    end  #def list_tasks

    #run
    def run_task current_task_name = :default, executed_tasks_list = {}
      if executed_tasks_list.has_key? current_task_name
        fail 'ERROR: Rakefile has RING!' if executed_tasks_list[current_task_name] == false
        return if executed_tasks_list[current_task_name] == true
      end
      executed_tasks_list[current_task_name] = false
      current_task = @task_list.find { |task| task.name == current_task_name }
      current_task.prerequisites.each do
        |task_name|
        run_task(task_name, executed_tasks_list)
      end
      current_task.block.call if current_task.block
      executed_tasks_list[current_task_name] = true
    end  #def run_task

  end  #class Rakefile

end  #module SimpleRake

#initialize in cmd
$options = {}

option_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: ./simplerake.rb [options] srake_file [task]'

  opts.on('-T', 'list tasks') do |value|
    $options[:FILE] = value
  end

  opts.on('-h', 'print help') do
    puts opts
    exit
  end
end.parse!

#start
file_name = ARGV[0]
rakefile = SimpleRake::Rakefile.new
rakefile.instance_eval(File.read(file_name))
if $options[:FILE]
  rakefile.list_tasks
else
  start_task = (ARGV[1] || 'default').to_sym
  rakefile.run_task(start_task)
end