#!/usr/bin/env ruby
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options] {start|stop|restart|status|pid}"
  opts.separator ""

  opts.on('-e', '--environment', "rails-environment the scheduling runs in") do |environment|
    options[:rails_env] = environment || ENV['RAILS_ENV'] || 'production'
  end

  opts.on('--basebath', "basepath to the rails application") do |basepath|
    options[:basepath] = basepath || "/home/application/project/#{options[:rails_env]}/current"
  end

  opts.on('--log', "file to log all output to") do |log|
    options[:log] = log || "#{options[:basepath]}/log/#{options[:rails_env]}.scheduler.log"
  end

  opts.on('--filename', 'filename of the scheduler') do |filename|
   options[:scheduler_filename] = filename || 'tasks.rb'
  end

  opts.on('--scheduler', 'full path to scheduler') do |scheduler|
    options[:scheduler] = scheduler || "#{options[:basepath]}/config/#{options[:scheduler_filename]}"
  end

  opts.separator ""

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

def scheduler_pid
  @pid ||= begin
             # ps aux still gives the most reliable output
             # grep -v 'grep' return everything but grep in the ps output
             # egrep "..." returns the line with the scheduler
             # sed "s/search/replace/" return the second word (number in this case) or nothing
             pid = `ps aux | grep -v 'grep' | egrep "#{options[:rails_env]}.*#{options[:scheduler_filename]}\.rb" | sed 's/^\w*\W\+\(\w\+\).*$/\1/'`.to_i
             ( pid == 0 ) ? nil : pid
           end
end

def start_scheduler
  %x[ ruby #{options[:scheduler]} >>#{options[:log]} 2>&1 & ; disown -a -h ]
end

def kill_scheduler
  if scheduler_pid
    Process.kill('TERM', scheduler_pid)
  end
end

case ARGV[0]
when "start"
  start_scheduler
when "stop"
  kill_scheduler
when "restart"
  kill_scheduler
  start_scheduler
when "status"
  if scheduler_pid
    puts "Scheduler is active (#{scheduler_pid})"
  else
    puts "Scheduler is inactive"
  end
when "pid"
  puts scheduler_pid
end

exit 0
