# frozen_string_literal: true

module Karafka
  module Instrumentation
    module Vendors
      module Appsignal
        # Appsignal client wrapper
        # We wrap the native client so we can inject our own stub in specs when needed
        #
        # It also abstracts away the notion of transactions and their management
        #
        # @note This client is abstract, it has no notion of Karafka whatsoever
        class Client
          # Starts an appsignal transaction with a given action name
          #
          # @param action_name [String] action name. For processing this should be equal to
          #   consumer class + method name
          def start_transaction(action_name)
            transaction = ::Appsignal::Transaction.create(
              SecureRandom.uuid,
              ::Appsignal::Transaction::BACKGROUND_JOB,
              ::Appsignal::Transaction::GenericRequest.new({})
            )

            transaction.set_action_if_nil(action_name)
          end

          # Stops the current transaction (if any)
          def stop_transaction
            return unless transaction?

            ::Appsignal::Transaction.complete_current!
          end

          # Sets metadata on a current transaction (if any)
          #
          # @param metadata_hash [Hash] hash with metadata we want to set
          def metadata=(metadata_hash)
            return unless transaction?

            transaction = ::Appsignal::Transaction.current

            stringify_hash(metadata_hash).each do |key, value|
              transaction.set_metadata(key, value)
            end
          end

          # Increments counter with the given value and tags
          #
          # @param key [String] key we want to use
          # @param value [Integer] increment value
          # @param tags [Hash] additional extra tags
          def count(key, value, tags)
            ::Appsignal.increment_counter(
              key,
              value,
              stringify_hash(tags)
            )
          end

          # Sets gauge with the given value and tags
          #
          # @param key [String] key we want to use
          # @param value [Integer] gauge value
          # @param tags [Hash] additional extra tags
          def gauge(key, value, tags)
            ::Appsignal.set_gauge(
              key,
              value,
              stringify_hash(tags)
            )
          end

          # Sends the error that occurred to Appsignal
          #
          # @param error [Object] error we want to ship to Appsignal
          def send_error(error)
            # If we have an active transaction we should use it instead of creating a generic one
            # That way proper namespace and other data may be transferred
            #
            # In case there is no transaction, a new generic background job one will be used
            if transaction?
              transaction.set_error(error)
            else
              ::Appsignal.send_error(error) do |transaction|
                transaction.set_namespace(::Appsignal::Transaction::BACKGROUND_JOB)
              end
            end
          end

          # Registers the probe under a given name
          # @param name [Symbol] probe name
          # @param probe [Proc] code to run every minute
          def register_probe(name, probe)
            ::Appsignal::Minutely.probes.register(name, probe)
          end

          private

          # @return [Boolean] do we have a transaction
          def transaction?
            ::Appsignal::Transaction.current?
          end

          # @return [::Appsignal::Transaction, nil] transaction or nil if not started
          def transaction
            ::Appsignal::Transaction.current
          end

          # Converts both keys and values of a hash into strings
          # @param hash [Hash]
          # @return [Hash]
          def stringify_hash(hash)
            hash
              .transform_values(&:to_s)
              .transform_keys!(&:to_s)
          end
        end
      end
    end
  end
end
