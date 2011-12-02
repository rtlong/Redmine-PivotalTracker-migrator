class AgilezenPivotalMigrator

  def run
    az_stories.reverse.each do |a|
      story = { story_type: 'feature' }

      story[:name] = a.text.strip.gsub(/\*\*/, '*')
      story[:name].gsub!(/^(#{CONFIG[:user_roles].join("|")})/, '*\1*') if CONFIG[:user_roles].presence

      if a[:size].presence
        size = a[:size].is_a?(String) ? a[:size].split('+').first.to_f : a[:size]
        story[:estimate] = round_to_powers_of_2(size)
      end

      story[:description] = a.details.presence ? a.details.strip : ''
      story[:description] << "\n\n_Imported from AgileZen story ##{a.id}_"

      story[:labels] = a.tags.collect(&:text)

      s = tracker_project.stories.create( story )

      puts "[#{s.id}] #{s.name} #{s.estimate}"

      a.tasks.each do |t|
        next if /^\[QA\]/i.match(t.text)

        s.tasks.create description: t.text.strip.gsub(/\s*\[[\d.\+]+\]$/, '')

        puts "  - " << t.text
      end

      a.comments.each do |c|
        c = s.notes.create text: "[import: #{c.author.name} said @ #{c.createTime}] #{c.text}"
        puts c.text
      end
      puts "\n"
    end

  end



  def az_stories
    if @az_stories.nil?
      c = AgileZen::Client.new(:api_key => CONFIG[:agilezen][:key])
      @az_stories = c.project_stories(CONFIG[:agilezen][:project_id], with: 'everything').items
    end
    return @az_stories
  end

  def tracker_project
    if @tracker_project.nil?
      PivotalTracker::Client.token = CONFIG[:tracker][:key]
      @tracker_project = PivotalTracker::Project.find(CONFIG[:tracker][:project_id])
    end
    return @tracker_project
  end

  def round_to_powers_of_2(size)
    r = 0
    (0..3).each do |e|
      r = 2**e if size >= 2**e
    end
    return r
  end

end