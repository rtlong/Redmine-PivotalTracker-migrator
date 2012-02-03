# encoding: UTF-8

class AgilezenPivotalMigrator

  def run
    az_stories.reverse.each do |a|
      s = { story_type: 'feature' }

      s[:name] = a.text.strip.gsub(/\*\*/, '*')
      s[:name].gsub!(/^(#{CONFIG[:user_roles].join("|")})/, '*\1*') if CONFIG[:user_roles].presence

      s[:name], extra_lines_from_name = s[:name].split("\n")

      if a[:size].presence
        if a[:size].is_a?(Integer)
          size = a[:size]
        else
          case a[:size].strip
          when /(?<hours>\d+)\s*hours?/i
            size = $~[:hours].to_i / 8 # round down to 8-hour days
          when /(?<days>\d+)\s*(?:days?)?/i
            size = $~[:days].to_i
          end
        end

        s[:estimate] = size.round_to_array(CONFIG[:tracker][:point_scale])
      end

      desc = []
      desc += [extra_lines_from_name, nil] if extra_lines_from_name
      desc << a.details.strip if a.details.presence
      desc += [nil] * 3 unless desc.blank?
      desc += [
        "*_Imported from AgileZen story ##{a.id}:_*",
        "https://agilezen.com/project/27016/story/#{a.id}",
        nil,
        "_Originally added on #{a.metrics.createTime.to_time.strftime('%d %h %Y, %H:%M%P')}_"
      ]
      desc << "Assignee: #{a.owner.name} <#{a.owner.email}>" if a.owner
      desc << "Was in the: *#{a.phase.name}* phase there"
      desc << "Size: #{a[:size]}"
      s[:description] = desc.join("\n")

      s[:labels] = a.tags.collect(&:name)

      s[:current_state] = (a.phase.name.match(/Backlog/i) or s[:estimate].nil?) ? 'unstarted' : 'started'

      s[:owned_by] = a.owner.name if a.owner.try(:name).try(:match, /Ryan|Maged/)

      # p s
      s = tracker_project.stories.create( s )
      if s.id.nil?
        puts "\n\nProblem saving this story!!"
        puts s.errors.errors
      else

        puts "[#{a.id} => #{s.id}] #{s.name} (#{s.estimate < 0 ? 'unestimated' : s.estimate.to_s})"

        if a.tasks.any?
          puts <<-EEE.strip_heredoc

             Tasks:
            ===============================
          EEE

          a.tasks.each do |t|
            next if /^\[QA\]/i.match(t.text)

            new_task = {
              description: t.text.strip.gsub(/\s*\[[\d.\+]+\]$/, ''),
              complete: t.status == 'complete'
            }
            s.tasks.create(new_task)

            puts "  · #{t.text}"
          end
        end
        if a.comments.any?
          puts <<-EEE.strip_heredoc

             Comments:
            ===============================
          EEE

          a.comments.each do |c|
            s.notes.create(
              text: "*#{c.author.name}:* #{c.text}",
              noted_at: c.createTime
            )

            puts <<-COMMENT.strip_heredoc
              [#{c.createTime} : #{c.author.name}]: "#{c.text}"
              ·.·.·.·.·.·.·.·.·.·.·.·.·.·.·.·.·.·.
            COMMENT
          end
        end

      end
      puts "\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n"

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


end