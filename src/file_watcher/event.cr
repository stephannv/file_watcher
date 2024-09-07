module FileWatcher
  enum EventType
    Added
    Changed
    Deleted
  end

  record Event, path : String, type : EventType
end
