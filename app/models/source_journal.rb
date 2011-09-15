class SourceJournal < ActiveRecord::Base
  include SecondDatabase
  set_table_name :journals

  belongs_to :journalized, :polymorphic => true
  belongs_to :issue, :class_name => 'SourceIssue', :foreign_key => :journalized_id

  def self.migrate

    all.each do |source_journals|

      puts "- Migrating journal ##{source_journals.id}..."
      if source_journals.issue.nil? # when migrating from really old redmine
        puts ".. [!!] nil issue: #{source_journals.journalized_id}"
        next
      end
      journal = Journal.create!(source_journals.attributes) do |j|
        j.issue = Issue.find(RedmineMerge::Mapper.get_new_issue_id(source_journals.issue.id))
        j.user = User.find(RedmineMerge::Mapper.get_new_user_id(source_journals.user_id))
      end

      RedmineMerge::Mapper.add_journal(source_journals.id, journal.id)
    end
  end
end
