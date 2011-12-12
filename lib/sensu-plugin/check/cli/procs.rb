#!/usr/bin/env ruby
#
# Processes Plugin
# ===
#
# This plugin checks to see if a given process is running.
#
# Copyright 2011 Sonian, Inc.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'

class Sensu::Plugin::Check::CLI::Procs < Sensu::Plugin::Check::CLI

  check_name 'procs'

  def get_procs
    `which tasklist`; $? == 0 ? `tasklist` : `ps aux`
  end

  def find_proc(procs, proc)
    procs.split("\n").find {|ln| ln.include?(proc) }
  end

  def find_proc_regex(procs, pat)
    procs.split("\n").find {|ln| ln =~ pat }
  end

  def run
    if name_args.size == 1
      proc = name_args.first
      if find_proc(get_procs, proc)
        ok "Process #{proc} is running"
      else
        warning "Process #{proc} is NOT running"
      end
    end
  end

end
