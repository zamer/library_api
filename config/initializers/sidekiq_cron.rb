if defined?(Sidekiq::Cron::Job)
  Sidekiq::Cron::Job.create(
    name: "SendDueRemindersJob - everyday 08:00",
    cron: "0 8 * * *",
    class: "SendDueRemindersJob",
    queue: "default",
    description: "Send reminders"
  )
end
