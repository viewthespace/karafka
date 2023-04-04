# frozen_string_literal: true

# Upon non-recoverable errors, Karafka should move forward skipping given message even if no
# marking happens for each batch.

class Listener
  def on_error_occurred(event)
    DT[:errors] << event
  end
end

Karafka.monitor.subscribe(Listener.new)

setup_karafka(allow_errors: true) do |config|
  config.max_messages = 10
  config.kafka[:'max.poll.interval.ms'] = 10_000
  config.kafka[:'session.timeout.ms'] = 10_000
end

class Consumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      mark_as_consumed(message)

      if message.offset == 1 || message.offset == 25
        DT[:firsts] << messages.first.offset

        raise StandardError
      end

      DT[0] << message.offset
    end
  end
end

draw_routes do
  consumer_group DT.consumer_group do
    topic DT.topics[0] do
      consumer Consumer
      long_running_job true
      dead_letter_queue topic: DT.topics[1], max_retries: 0
      manual_offset_management true
    end
  end
end

produce_many(DT.topics[0], DT.uuids(50))

start_karafka_and_wait_until do
  DT[:errors].size >= 2 && DT[0].count >= 48
end

duplicates = DT[:firsts] - [1, 25]

# Failing messages should not be there
assert !DT[0].include?(1)
assert !DT[0].include?(25)

# Failing messages that are not first in batch should cause some reprocessing
duplicates.each do |duplicate|
  next if duplicate + 1 == 1 || duplicate + 1 == 25

  assert_equal(1, DT[0].count { |nr| nr == (duplicate + 1) })
end

assert_equal 49, DT[0].last
assert_equal 48, DT[0].uniq.count
