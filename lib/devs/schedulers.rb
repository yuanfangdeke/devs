require 'devs/schedulers/binary_heap_scheduler'
require 'devs/schedulers/sorted_list_scheduler'
require 'devs/schedulers/minimal_list_scheduler'
require 'devs/schedulers/ladder_queue_scheduler'

module DEVS
  class << self
    attr_accessor :scheduler
  end
  @scheduler = LadderQueueScheduler
end
