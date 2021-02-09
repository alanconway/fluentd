#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'fluent/plugin/input'

module Fluent::Plugin
  class TailInput < Fluent::Plugin::Input

    class WriteWatcher

      def initialize(log)
        @notify_count = 0
        @log = log
        @map = {}
      end

      # :ino inode number of current file
      # :size of current file
      # :accumulated accumulated size of previous files for this path
      Entry = Struct.new(:ino, :size, :accumulated)

      def on_notify(path, stat)
        info = @map[path]
        if !info
          @log.error "FIXME #{path} new file"
          info = Entry.new(nil, 0, 0)
        end
        # Accumulate last size if file changed (no stat, new inode or truncated)
        if !stat || info.ino != stat.ino || stat.size < info.size
          info.accumulated += info.size
          info.size = 0
          @log.error "FIXME #{path} file change, accumulated #{info.accumulated}"
        end
        info.ino, info.size = stat.ino, stat.size if stat

        @notify_count += 1
        if @notify_count> 100
          @notify_count = 0
          @log.error "FIXME #{path} size #{info.size + info.accumulated}"
        end
        @map[path] = info
      end
    end
  end
end
