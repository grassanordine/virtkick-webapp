class TrackableJob < BaseJob
  def initialize progress_id
    @progress = Progress.find(progress_id)
    @progress_id = progress_id
  end

  def success job
    @progress.update! finished: true
  end

  def failure job, e
    message = ''
    if e.is_a? SafeException or !Rails.env.production?
      message = e.respond_to?(:errors) ? e.errors.first : e.message
    else
      message = 'System error occured, our engineers will be notified, sorry!'
    end
    @progress.update! \
      finished: true,
      error: message
    super # parent will notify Bugsnag and print exception
  end

  def self.perform_later user, *args
    progress = Progress.new
    progress.user_id = user.is_a?(Integer) ? user : user.id
    progress.save!

    job = self.new progress.id
    job.delay.perform *args

    progress.id
  end
end
