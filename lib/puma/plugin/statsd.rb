# coding: utf-8, frozen_string_literal: true
require "json"
require "puma"
require "puma/plugin"
require 'datadog/statsd'

# Wrap puma's stats in a safe API
class PumaStats
  def initialize(stats)
    @stats = stats
  end

  def clustered?
    @stats.has_key?(:workers)
  end

  def count_value_for_key(key, default_value = 0)
    if clustered?
      @stats[:worker_status].reduce(0) { |acc, s| acc + s[:last_status].fetch(key, default_value) }
    else
      @stats.fetch(key, default_value)
    end
  end
end

Puma::Plugin.create do
  # We can start doing something when we have a launcher:
  def start(launcher)
    @launcher = launcher
    host = ENV.fetch("STATSD_HOST", nil)
    port = ENV.fetch("STATSD_PORT", 8125)
    
    if host
      @statsd_client = Datadog::Statsd.new(host, port, tags: environment_variable_tags)
      @launcher.events.debug "statsd: enabled (host: #{host})"

      register_hooks
    else
      @launcher.events.debug "statsd: not enabled (no STATSD_HOST env var found)"
    end
  end

  private

  # Send data to statsd every few seconds
  def stats_loop
    sleep 5
    loop do
      @launcher.events.debug "statsd: notify statsd"
      begin
        stats = ::PumaStats.new(fetch_stats)

        @statsd_client.batch do |s|
          s.gauge('puma.workers', stats.count_value_for_key(:workers, 1))
          s.gauge('puma.booted_workers', stats.count_value_for_key(:booted_workers, 1))
          s.gauge('puma.running', stats.count_value_for_key(:running))
          s.gauge('puma.backlog', stats.count_value_for_key(:backlog))
          s.gauge('puma.pool_capacity', stats.count_value_for_key(:pool_capacity))
          s.gauge('puma.max_threads', stats.count_value_for_key(:max_threads))
          s.gauge('puma.requests_count', stats.count_value_for_key(:requests_count))
        end
      rescue StandardError => e
        @launcher.events.error "! statsd: notify stats failed:\n  #{e.to_s}\n  #{e.backtrace.join("\n    ")}"
      ensure
        sleep 2
      end
    end
  end

  def register_hooks
    in_background(&method(:stats_loop))
  end

  if Puma.respond_to?(:stats_hash)
    def fetch_stats
      Puma.stats_hash
    end
  else
    def fetch_stats
      stats = Puma.stats
      JSON.parse(stats, symbolize_names: true)
    end
  end

  def environment_variable_tags
    # Tags are separated by spaces, and while they are normally a tag and
    # value separated by a ':', they can also just be tagged without any
    # associated value.
    #
    # Examples: simple-tag-0 tag-key-1:tag-value-1
    #
    tags = [
      "k8s_node_name:#{ENV['K8S_NODE_NAME']}",
      "k8s_pod_name:#{ENV['K8S_POD_NAME']}",
      "k8s_pod_namespace:#{ENV['K8S_POD_NAMESPACE']}",
      "environment:#{ENV["ENVIRONMENT"]}",
      "service:#{ENV["SERVICE_NAME"]}"
    ]

    if ENV.has_key?("STATSD_GROUPING")
      tags << "grouping:#{ENV['STATSD_GROUPING']}"
    end

    # Space-separated list of tags.
    if ENV.has_key?("EXTRA_TAGS")
      ENV["EXTRA_TAGS"].split(/\s+/).each do |t|
        tags << t
      end
    end

    # Return nil if we have no environment variable tags. This way we don't
    # send an unnecessary '|' on the end of each stat
    return nil if tags.empty?

    tags
  end
end
