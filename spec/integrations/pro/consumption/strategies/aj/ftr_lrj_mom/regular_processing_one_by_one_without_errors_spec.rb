# frozen_string_literal: true

# Karafka should be able to just process all the jobs one after another
# Throttling may throttle but should not impact order or anything else

setup_active_job

setup_karafka

class Job < ActiveJob::Base
  queue_as DT.topic

  def perform(value)
    DT[0] << value
  end
end

draw_routes do
  consumer_group DT.consumer_group do
    active_job_topic DT.topic do
      max_messages 20
      long_running_job true
      throttling(limit: 10, interval: 2_000)
    end
  end
end

50.times { |value| Job.perform_later(value) }

start_karafka_and_wait_until do
  DT[0].size >= 50
end

assert_equal DT[0], (0..49).to_a
