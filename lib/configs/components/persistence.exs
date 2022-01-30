[
  {fn -> Paygate.Infrastructure.Repo end, config.persistence == "db"},
  {
    fn ->
      {
        Infrastructure.Repository.MemoryRepository,
        config.root.repository_entity
      }
    end,
    config.persistence == "memory"
  },
  {
    fn ->
      {
        Events.WriteBuffer,
        config.root.buffer_writer
      }
    end,
    config.persistence != "none"
  }
]
