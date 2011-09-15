class SourceTimeEntry < ActiveRecord::Base
  include SecondDatabase
  set_table_name :time_entries

  belongs_to :user, :class_name => 'SourceUser', :foreign_key => 'user_id'
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'
  belongs_to :issue, :class_name => 'SourceIssue', :foreign_key => 'issue_id'
  belongs_to :activity, :class_name => 'SourceEnumeration', :foreign_key => 'activity_id'
  

  def self.migrate
    
    count = all.count
    i = 0
    x = 0

    all.each do |source_time_entry|

      i+=1
      x = 100*i/count
      puts "..[#{x}%] #{source_time_entry.id} "
      
      if skip.include? source_time_entry.id
        next
      end

      TimeEntry.create!(source_time_entry.attributes) do |te|
        te.user = User.find(RedmineMerge::Mapper.get_new_user_id(source_time_entry.user.id))
        te.project = Project.find_by_name(source_time_entry.project.name)
        te.activity = TimeEntryActivity.find_by_name(source_time_entry.activity.name)
        # optional 
        te.issue = Issue.find_by_id(RedmineMerge::Mapper.get_new_issue_id(source_time_entry.issue.id)) if source_time_entry.issue_id
      end
    end
  end
end
