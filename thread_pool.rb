require 'thread'

# Work item to be executed in thread pool
class ThreadPoolJob
  attr_accessor :handler
  attr_accessor :params

  def initialize(*params, &block)
    @params = params
    @handler = block
  end
end


# Launches a specified number of threads on instantiation,
# assigning work to them as it arrives
class ThreadPool

  # Encapsulate each thread pool thread in object
  class ThreadPoolJobRunner
    attr_accessor :time_started

    def initialize(thread_pool)
      @thread_pool = thread_pool
      @timeout_lock = Mutex.new
      @thread_lock  = Mutex.new
    end

    def run
      @thread_lock.synchronize {
        @thread = Thread.new {
          until @thread_pool.terminate
            @timeout_lock.synchronize { @time_started = nil }
            work = @thread_pool.next_job
            @timeout_lock.synchronize { @time_started = Time.now }
            work.handler.call *work.params unless work.nil?
          end
        }
      }
    end

    def check_timeout(timeout)
      @timeout_lock.synchronize {
        if !@time_started.nil? && Time.now - @time_started > timeout
          stop
          run
        end
      }
    end

    def stop
      @thread_lock.synchronize {
        if @thread.alive?
          @thread.kill
          @thread.join
        end
      }
    end
  end

  # Create a thread pool with a specified number of threads
  def initialize(num_threads, args = {})
    @num_threads = num_threads
    @timeout     = args[:timeout]
    @job_runners = []
    @job_runners_lock = Mutex.new
    @terminate = false
    @terminate_lock = Mutex.new

    @work_queue  = Queue.new

    0.upto(@num_threads) { |i|
      runner = ThreadPoolJobRunner.new(self)
      @job_runners << runner
      runner.run
    }

    # optional timeout thread
    unless @timeout.nil?
      @timeout_thread = Thread.new {
        until terminate
          sleep @timeout
          @job_runners_lock.synchronize {
            @job_runners.each { |jr|
              jr.check_timeout(@timeout)
            }
          }
        end
      }
    end
  end
  end
