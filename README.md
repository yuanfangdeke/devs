# DEVS - Discrete Event Specification System

[![Dependency Status](https://gemnasium.com/romain1189/devs.png)](https://gemnasium.com/romain1189/devs)
[![Build Status](https://secure.travis-ci.org/romain1189/devs.png?branch=master)](http://travis-ci.org/romain1189/devs)

DEVS abbreviating Discrete Event System Specification is a modular and hierarchical formalism for modeling and analyzing general systems that can be discrete event systems which might be described by state transition tables, and continuous state systems which might be described by differential equations, and hybrid continuous state and discrete event systems. DEVS is a timed event system.

## Installation

Add this line to your application's Gemfile:

    gem 'devs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install devs

## Documentation

The following API documentation is available :

* [YARD API documentation](http://www.rubydoc.info/github/romain1189/devs/master/frames)

## Usage

    require 'devs'

    DEVS.simulate do
      duration 50

      atomic do
        name :traffic_light
        add_output_port :out

        init do
          @state = :red
          self.sigma = 0
        end

        time_advance { self.sigma }

        output do
          post(@state, output_ports.first)
        end

        internal_transition do
          case @state
          when :red
            @state = :green
            self.sigma = 5
          when :green
            @state = :orange
            self.sigma = 20
          when :orange
            @state = :red
            self.sigma = 2
          end
        end
      end
    end

For more examples, see the examples folder

## Suggested Reading

* Bernard P. Zeigler, Herbert Praehofer, Tag Gon Kim. *Theory of Modeling and Simulation*. Academic Press; 2 edition, 2000. ISBN-13: 978-0127784557

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
