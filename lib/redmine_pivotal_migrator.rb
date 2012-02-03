# encoding: UTF-8

class RedminePivotalMigrator

  def self.run
    redmine_stories.reverse.each do |redmine_story|
      puts "\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n"
      puts "#{redmine_story[:id]}. #{redmine_story[:subject]}"

      if redmine_story[:skip]
        puts "Skipping!"
        next
      end

      # if id = CONFIG[:id_map][redmine_story[:pivotal_story_id].to_i] then
      if id = redmine_story[:pivotal_story_id] then
        puts "Updating existing Pivotal story #{id}..."

        if existing_story = tracker_project.stories.find(id.to_i)
          s = existing_story.instance_values
          s.delete_if{|k,v| k.match(/id|url|created_at|project_id|errors|owned_by|requested_by/i) or v.nil? }
          s.symbolize_keys!
        else
          puts "Cannot find a Pivotal story with the ID: #{id}"
        end
      end

      s ||= Hash.new
      puts 'Creating a new Pivotal story...' if s.blank?

      # Set the Redmine ID
      s[:other_id] = redmine_story[:id]
      s[:integration_id] = CONFIG[:tracker][:redmine_integration_id]

      s[:story_type] ||= tracker_story_type(redmine_story)

      if s[:name].nil? then
        s[:name] = redmine_story[:subject].strip
        s[:name].gsub!(/^(#{CONFIG[:user_roles].join("|")})/, '*\1*') if CONFIG[:user_roles].presence
      end

      desc = []
      desc += [s[:description].strip, nil, '-----------', nil] if s[:description].presence
      if redmine_story[:description].presence
        desc << redmine_story[:description].strip
        desc += [nil] * 3
      end
      desc += [
        "*_Imported from eSpace's Redmine, story ##{redmine_story[:id]} at #{Time.now.strftime('%d %h %Y, %H:%M%P')}:_*",
        [CONFIG[:redmine_issue_url],redmine_story[:id]].join('/'),
        nil,
        'What follows are the details from Redmine _as of import-time_, here for historical reasons, only:',
        nil,
        "*Added:* #{redmine_story[:created].to_time.strftime('%d %h %Y, %H:%M%P')} by #{redmine_story[:author]}",
        "*Updated:* #{redmine_story[:updated].to_time.strftime('%d %h %Y, %H:%M%P')}",
        "*Assignee:* #{redmine_story[:assignee]}",
        "*Status:* #{redmine_story[:status]}",
        "*Priority:* #{redmine_story[:priority]}",
        "*Started:* #{redmine_story[:started]}",
        "*Due:* #{redmine_story[:due_date]}",
        "*Done:* #{redmine_story[:percent_done]}%"
      ]
      s[:description] = desc.join("\n")

      s[:current_state] = tracker_story_state(redmine_story) || s[:current_state] || :unstarted

      unless s[:current_state].match(/unstarted|unscheduled/) or s[:story_type].match(/bug|chore/)
        s[:estimate] = 0 unless s[:estimate] and s[:estimate] >= 0
      end

      s[:owned_by] = redmine_story[:assignee] if redmine_story[:assignee].try(:match, /Ryan|Maged/i)
      # s[:owned_by] = redmine_story[:assignee] if redmine_story[:assignee].try(:match, /Ryan/i)


      # p s
      if existing_story
        # so we don't see errors because the user who created the story is no longer a member of the account
        existing_story.requested_by = nil

        story = existing_story.update(s)

      else
        story = tracker_project.stories.create( s )

      end

      if story.errors.errors.any?
        puts "\n\nProblem saving this story!!"
        puts story.errors.errors
        p s, story
        raise
      else
        puts "Created story with ID: #{story.id}"

      end
    end
  end

  private

  def self.tracker_story_type(redmine_story)
    case redmine_story[:tracker].downcase.to_sym
    when :bug
      :bug
    when :story
      :feature
    when :enhancement
      :feature
    end
  end

  def self.tracker_story_state(redmine_story)
    case redmine_story[:status].downcase.gsub(/\s+/,'_').to_sym
    when :new
      :unscheduled
    when :duplicate
      nil # will fall back to current value, then to :unstarted
    when :feedback
      :unstarted
    when :postponed
      :unscheduled
    when :resolved
      :delivered
    when :closed
      :delivered
    when :ready_for_testing
      :delivered
    when :verified
      :delivered
    when :reopened
      :started
    end
  end

  def self.redmine_stories
    if @redmine_stories.nil?
      @redmine_stories = []
      CSV.foreach(CONFIG[:redmine][:csv_file], headers: true) do |row|
        @redmine_stories << row.to_hash.symbolize_keys
      end
    end
    return @redmine_stories
  end

  def self.tracker_project
    if @tracker_project.nil?
      PivotalTracker::Client.token = CONFIG[:tracker][:key]
      @tracker_project = PivotalTracker::Project.find(CONFIG[:tracker][:project_id])
    end
    return @tracker_project
  end


end