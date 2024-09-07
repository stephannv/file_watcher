module FileWatcher
  class Snapshot
    getter path : String
    property file_info : File::Info

    def initialize(@path, @file_info); end
  end
end
