namespace :cron do

  desc "TODO"
  task find_expired_plans: :environment do
    records = CommitedCredit.where 'date_from < ?', DateTime.now

    for record in records
      puts record.to_json
    end

  end

end
