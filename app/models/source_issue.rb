class SourceIssue < ActiveRecord::Base
  include SecondDatabase
  set_table_name :issues

  belongs_to :author, :class_name => 'SourceUser', :foreign_key => 'author_id'
  belongs_to :assigned_to, :class_name => 'SourceUser', :foreign_key => 'assigned_to_id'
  belongs_to :status, :class_name => 'SourceIssueStatus', :foreign_key => 'status_id'
  belongs_to :tracker, :class_name => 'SourceTracker', :foreign_key => 'tracker_id'
  belongs_to :project, :class_name => 'SourceProject', :foreign_key => 'project_id'
  belongs_to :priority, :class_name => 'SourceEnumeration', :foreign_key => 'priority_id'
  belongs_to :category, :class_name => 'SourceIssueCategory', :foreign_key => 'category_id'
  belongs_to :fixed_version, :class_name => 'SourceVersion', :foreign_key => 'fixed_version_id'

  def self.migrate

    count = all.count
    ctr = 0
    x = 0.0
    start = Time.now.seconds_since_midnight

    all.each do |source_issue|

      ctr += 1
      x = 100.0*ctr/count
      dt = (Time.now.seconds_since_midnight - start).to_i
      eta = (dt*100/x - dt).to_i
      puts "..[issues][#{x.round 4}%][ETA: #{eta/60}m #{eta.modulo 60}s]"

      puts "- Migrating issue ##{source_issue.id}: #{source_issue.subject}"
      next if source_issue.project.nil?
      issue = Issue.create!(source_issue.attributes) do |i|

        i.project = Project.find_by_name(source_issue.project.name)
        i.author = User.find(RedmineMerge::Mapper.get_new_user_id(source_issue.author.id)) if i.author.blank?

        i.assigned_to = User.find(RedmineMerge::Mapper.get_new_user_id(source_issue.assigned_to.id)) if source_issue.assigned_to
        i.status = IssueStatus.find_by_name(source_issue.status.name)
        i.tracker = Tracker.find_by_name(source_issue.tracker.name)
        i.fixed_version_id = RedmineMerge::Mapper.get_new_version_id(source_issue.fixed_version_id)

        i.priority = IssuePriority.find_by_name(source_issue.priority.name)
        puts "-- Set issue priority #{i.priority}"
        i.category = IssueCategory.find_by_name(source_issue.category.name) if source_issue.category
        puts "-- Set category #{i.category}"
        if source_issue.fixed_version and version = Version.find(RedmineMerge::Mapper.get_new_version_id(source_issue.fixed_version.id))
          i.instance_variable_set :@assignable_versions, [version]
          i.fixed_version = version
          puts "-- Set fixed version #{i.fixed_version}"
        end
      end

      RedmineMerge::Mapper.add_issue(source_issue.id, issue.id)
    end
  end
end
