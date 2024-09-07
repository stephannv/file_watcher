require "./file_watcher/watcher"

module FileWatcher
  VERSION = "0.1.0"

  def self.watch(
    *patterns : String | Path,
    match_option : File::MatchOptions = File::MatchOptions.glob_default,
    follow_symlinks : Bool = false,
    interval : Time::Span = 1.second,
    &block : Event -> _
  ) : Nil
    watch([*patterns] of String | Path, match_option: match_option, follow_symlinks: follow_symlinks, interval: interval) do |event|
      yield event
    end
  end

  def self.watch(
    patterns : Enumerable,
    match_option : File::MatchOptions = File::MatchOptions.glob_default,
    follow_symlinks : Bool = false,
    interval : Time::Span = 1.second,
    &block : Event -> _
  ) : Nil
    Watcher.new(
      patterns,
      match_option: match_option,
      follow_symlinks: follow_symlinks,
      interval: interval
    ).start do |event|
      yield event
    end
  end
end
