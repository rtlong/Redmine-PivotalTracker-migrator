require 'nokogiri'

module PivotalTracker
  class Story
    protected

    def to_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.story {
          xml.name "#{name}"
          xml.description "#{description}"
          xml.story_type "#{story_type}"
          xml.estimate "#{estimate}"
          xml.current_state "#{current_state}"
          xml.requested_by "#{requested_by}" if requested_by
          xml.owned_by "#{owned_by}"
          xml.labels "#{labels}"
          xml.project_id "#{project_id}"
          # See spec
          # xml.jira_id "#{jira_id}"
          # xml.jira_url "#{jira_url}"
          xml.other_id "#{other_id}"
          xml.integration_id "#{integration_id}"
          xml.created_at DateTime.parse(created_at.to_s).to_s if created_at
          xml.accepted_at DateTime.parse(accepted_at.to_s).to_s if accepted_at
          xml.deadline DateTime.parse(deadline.to_s).to_s if deadline
        }
      end
      return builder.to_xml
    end

  end
end