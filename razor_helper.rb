# -*- encoding: utf-8 -*-
require 'tmpdir'
require 'shellwords'

# Collection of general helpers that get used in our tests.

def reset_database(where = agents)
  step 'Reset the razor database to a blank slate'
  on where, 'env TORQUEBOX_FALLBACK_LOGFILE=/dev/null ' +
    '/opt/puppet/bin/razor-admin -e production reset-database'
end

def razor(where, what, args = nil, options = {}, &block)
  case args
  when String then json = args
  when Hash   then json = args.to_json
  end

  # translate this to something nicer
  options[:exit] and options[:acceptable_exit_codes] = Array(options.delete(:exit))

  # This may never be used, but is cheap to generate.
  file = '/tmp/' + Dir::Tmpname.make_tmpname(['razor-json-input-', '.json'], nil)

  if json
    teardown { on where, "rm -f #{file}" }

    step "Create the JSON file containing the #{what} command on agents"
    create_remote_file where, file, json
  end

  where.each do |node|
    step "Run #{what} on #{node}"
    cmd = "razor -u http://#{node}:8080/api #{what} " +
      (json ? "--json #{file}" : args.shelljoin)

    output = on(node, cmd, options).output

    block and case block.arity
              when 0 then yield
              when 1 then yield node
              when 2 then yield node, output
              else raise "unknown arity #{block.arity} for razor helper!"
              end
  end
end
