require 'sinatra'

=begin
# ENV vars
## Startup behaviors
### READY_MODE
* "normal" (Default) : the ready endpoint responds with 200 after 30 seconds from app start
* "fast" : the ready endpoint responds with 200 immediately
* "never" : the /ready endpoint remains responding 500

### CONSUMED_CPU_MODE
* "minimal" (Default) : uses only enough CPU to fulfill requests
* "full" : uses a constant 100%
* "random" : uses a random amount of CPU between 0% and 100%

### CONSUMED_MEMORY_MODE
* "minimal" (Default) : uses only needed RAM
* "unlimited" : increases the amount of memory used indefinitely until OOM kill

ready_mode = ENV["READY_MODE"] || 'normal'
puts "Ready mode is: #{ready_mode}"
=end

start_time = Time.now

$ready_mode           = ENV["READY_MODE"]           || "normal"
$consumed_cpu_mode    = ENV["CONSUMED_CPU_MODE"]    || "minimal"
$consumed_memory_mode = ENV["CONSUMED_MEMORY_MODE"] || "minimal"

puts "READY_MODE = #{$ready_mode}"
puts "CONSUMED_CPU_MODE = #{$consumed_cpu_mode}"
puts "CONSUMED_MEMORY_MODE = #{$consumed_memory_mode}"

def startup
  full_cpu if $consumed_cpu_mode == "full"
  random_cpu if $consumed_cpu_mode == "random"
  eat_memory if $consumed_memory_mode == "unlimited"
end

set :bind, '0.0.0.0'

def full_cpu
  puts 'creating a 100% cpu thread'
  Thread.new do
    while true do
    end
  end
end

def random_cpu
  puts 'doing random cpu usage'
  granularity_seconds = 1 / 10
  Thread.new do
    loop do
      t = Time.now.to_f

      Thread.new do
        r = Random.rand * granularity_seconds
        while Time.now.to_f < t + r do
          #no-op
        end
      end

      sleep granularity_seconds
    end
  end
end

def eat_memory
  puts "eating memory"
  Thread.new do
    m = []
    while true do
      m.append 'munch!'
    end
  end
end

def kill_me
  puts "killing process"
  Thread.new do
    pid = Process.pid
    system 'kill', pid.to_s
  end
end

def braindead
  puts "going braindead"
  Thread.new do
    Thread.list.each {|th|
      if th.to_s.include? "reactor"
        puts "killing #{th.to_s}"
        th.kill
      end
    }
  end
end

get '/' do
  routes = []
  Sinatra::Application.routes["GET"].each do |route|
    routes << route[0].to_s
  end
  routes.join "<br>"
end

get '/cpu' do
  random_cpu
  'I feel crazy!'
end

get '/fullcpu' do
  full_cpu
  'Ramp it up!'
end

get '/memory' do
  eat_memory
  'munch munch munch'
end

get '/kill' do
  kill_me
  'What a world! What a world!'
end

get '/braindead' do
  braindead
  "I'm gone"
end

get '/alive' do
  "I'm doing science and I'm still alive (since #{startTime.inspect})"
end

get '/ready' do
  if $ready_mode == "fast" || start_time < Time.now - 30 && $ready_mode != "never"
    'Thunder cats are go!'
  else
    status 500
    "I'm not ready yet"
  end
end

startup