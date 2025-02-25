# frozen_string_literal: true

FactoryBot.define do
  factory :routing_topic, class: 'Karafka::Routing::Topic' do
    consumer_group { build(:routing_consumer_group) }
    name { 'test' }
    consumer { Class.new(Karafka::BaseConsumer) }
    kafka { {} }
    max_messages { 1000 }
    max_wait_time { 10_000 }
    subscription_group { SecureRandom.hex(6) }

    skip_create

    initialize_with do
      instance = new(name, consumer_group)

      instance.tap do |topic|
        topic.consumer = consumer
        topic.subscription_group = subscription_group
      end
    end
  end

  factory :pattern_routing_topic, parent: :routing_topic do
    transient do
      regexp { /xda/ }
      pattern { Karafka::Pro::Routing::Features::Patterns::Pattern.new(nil, regexp, ->(_) {}) }
    end

    skip_create

    initialize_with do
      instance = new(name, consumer_group)

      instance.tap do |topic|
        topic.consumer = consumer
        topic.subscription_group = subscription_group
      end

      pattern.topic = instance

      instance.patterns(
        active: true,
        type: :matcher,
        pattern: pattern
      )

      instance
    end
  end
end
