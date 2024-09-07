require "./snapshot"
require "./event"

module FileWatcher
  class Watcher
    getter patterns : Enumerable(String | Path)
    getter match_option : File::MatchOptions
    getter follow_symlinks : Bool
    getter cache : Hash(String, Snapshot) = Hash(String, Snapshot).new
    getter interval : Time::Span

    def initialize(@patterns, @match_option, @follow_symlinks, @interval); end

    def start(&) : Nil
      start_cache

      loop do
        get_paths.each do |path|
          file_info = File.info(path)

          if snapshot = cache[path]?
            if snapshot.file_info.modification_time < file_info.modification_time
              yield Event.new(path, :changed)
              snapshot.file_info = file_info
            end
          else
            yield Event.new(path, :added)

            cache[path] = Snapshot.new(path, file_info)
          end
        end

        cache.reject! do |path, snapshot|
          unless File.exists?(path)
            yield Event.new(path, :deleted)
            true
          end
        end

        sleep interval
      end
    end

    private def start_cache : Nil
      get_paths.each do |path|
        cache[path] = Snapshot.new(path, File.info(path))
      end
    end

    private def get_paths : Array(String)
      Dir.glob(@patterns, match_option, follow_symlinks)
    end
  end
end
