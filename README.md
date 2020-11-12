# Puma Statsd Plugin

[Puma][puma] integration with [statsd](statsd), using the 
[dogstatsd-ruby](dogstatsd-ruby) client for easy tracking 
of key metrics that puma can provide:

* puma.workers
* puma.booted_workers
* puma.running
* puma.backlog
* puma.pool_capacity
* puma.max_threads
* puma.requests_count (**puma 5.0.0**)

  [puma]: https://github.com/puma/puma
  [statsd]: https://github.com/etsy/statsd
  [dogstatsd-ruby]: https://github.com/DataDog/dogstatsd-ruby

## Installation

Add this gem to your Gemfile with puma and then bundle:

```ruby
gem "puma"
gem "puma-plugin-statsd"
```

Add it to your puma config:

```ruby
# config/puma.rb

bind "http://127.0.0.1:9292"

workers 1
threads 8, 16

plugin :statsd
```

## Usage

Ensure you have an environment variable set that points to a statsd host, then boot your puma app as usual.  Optionally you may specify a port (default is 8125).

```
STATSD_HOST=127.0.0.1 bundle exec puma
```

```
STATSD_HOST=127.0.0.1 STATSD_PORT=9125 bundle exec puma
```

### Runtastic Tags

The following tags are reported using the ENV variables available in Runtastic's ruby service images.

* `"k8s_node_name:#{ENV['K8S_NODE_NAME']}"`
* `"k8s_pod_name:#{ENV['K8S_POD_NAME']}"`
* `"k8s_pod_namespace:#{ENV['K8S_POD_NAMESPACE']}"`
* `"environment:#{ENV["ENVIRONMENT"]}"`
* `"service:#{ENV["SERVICE_NAME"]}"`

### EXTRA_TAGS

`EXTRA_TAGS`: Set this to a space-separated list of tags.

For example, you could set this environment variable to set the following tags:

```bash
export EXTRA_TAGS="env:test simple-tag-0 tag-key-1:tag-value-1"
bundle exec rails server
```

### STATSD_GROUPING

`STATSD_GROUPING`: add a `grouping` tag to the metrics, with a value equal to
the environment variable value. This is particularly helpful in a kubernetes
deployment where each pod has a unique name but you want the option to group
metrics across all pods in a deployment. Setting this on the pods in a
deployment might look something like:

```yaml
env:
  - name: STATSD_GROUPING
    value: deployment-foo
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/runtastic/puma-plugin-statsd.

## Testing the data being sent to statsd

Start a pretend statsd server that listens for UDP packets on port 8125:

    ruby devtools/statsd-to-stdout.rb

Start puma:

    STATSD_HOST=127.0.0.1 bundle exec puma devtools/config.ru --config devtools/puma-config.rb

Throw some traffic at it, either with curl or a tool like ab:

    curl http://127.0.0.1:9292/
    ab -n 10000 -c 20 http://127.0.0.1:9292/

Watch the output of the UDP server process - you should see statsd data printed to stdout.

## Acknowledgements

This gem is a fork of the excellent [puma-plugin-statsd][puma-plugin-statsd] by James Healy.

  [puma-plugin-statsd]: https://github.com/yob/puma-plugin-statsd

Other puma plugins that were helpful references:

* [puma-heroku](https://github.com/evanphx/puma-heroku)
* [tmp-restart](https://github.com/puma/puma/blob/master/lib/puma/plugin/tmp_restart.rb)

The [puma docs](https://github.com/puma/puma/blob/master/docs/plugins.md) were also helpful.

## License

The gem is available as open source under the terms of the [MIT License][license].

  [license]: http://opensource.org/licenses/MIT
