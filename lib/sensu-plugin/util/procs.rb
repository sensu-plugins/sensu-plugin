require 'sensu-plugin/check/cli'

module Sensu
  module Plugin
    module Util
      module Procs

        class << self
          def get_procs
            `which tasklist`; $? == 0 ? `tasklist` : `ps aux`
          end

          def find_proc(name)
            get_procs.split("\n").find {|ln| ln.include?(name) }
          end

          def find_proc_regex(pat)
            get_procs.split("\n").find {|ln| ln =~ pat }
          end
        end

      end
    end
  end
end
