require "spec"
require "../src/file_watcher"
require "file_utils"

class TimeoutError < Exception; end

def with_timeout(time : Time::Span, &block)
  channel = Channel(Exception?).new

  spawn do
    block.call
    channel.send(nil)
  rescue error
    channel.send(error)
  end

  select
  when error = channel.receive?
    raise error if error
  when timeout(time)
    raise TimeoutError.new
  end
end

def create_file(file_name : String | Path)
  dir = File.dirname(file_name)

  FileUtils.mkdir_p(dir) unless Dir.exists?(dir)

  File.write(file_name, "")
end
