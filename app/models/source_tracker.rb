class SourceTracker < ActiveRecord::Base
  include SecondDatabase
  set_table_name :trackers

  has_and_belongs_to_many :projects, :class_name => 'SourceProject', :join_table => 'projects_trackers', :foreign_key => 'tracker_id', :association_foreign_key => 'project_id'
  
  def self.migrate

    details = {} # tracker.id -> t.workflow_ids
    meat = {} # workflow.id => [attributes, {from.name, to.name, role.name}]

    models = [Tracker, IssueStatus, Role, Workflow]
    models.each {|m| m.establish_connection :source_redmine }

    Tracker.all.each {|t|
      details[t.id] = t.workflow_ids

      t.workflows.each {|w|
        #puts "..caching workflow ##{w.id}" 
        if w.new_status.nil? || w.old_status.nil? || w.role.nil?
          puts "..!! invalid workflow item: ##{w.id}"
          next
        end

        meat[w.id] = [w.attributes, 
          { :old_name => w.old_status.name, 
          :new_name => w.new_status.name, 
          :role_name => w.role.name }
          ]
      }
    }
    
    env = ENV["RAILS_ENV"]
    models.each {|m| m.establish_connection env.to_sym }

    all.each do |source_tracker|
      puts ".. " << source_tracker.name
      t = Tracker.find_by_name(source_tracker.name)
      if t.nil?
        t = Tracker.create!(source_tracker.attributes)
      else
        # one needs to think how to merge workflows with existing trackers. maybe just for roles that exist on source_redmine?
        # next # disabled, appropriate logic is below, based on roles that are or aren't migrated
      end

      # this should be refactored... it's not optimal at all :)
      count = {} # this is for checking whether there are any transitions, 2-D hash: tracket => role => count
      Workflow.count_by_tracker_and_role.each {|tra| 
        count[tra[0].name] = {}
        tra[1].each {|r| count[tra[0].name][r[0].name]=r[1]}
      }

      # Requires roles and issue statuses to be migrated
      details[source_tracker.id].each {|w| #workflow ids
        if meat[w].nil?
          puts "..!! this workflow cannot be migrated: ##{w}"
          next
        end

        # don't touch existing roles/workflows.
        tn = t.name #tracker name
        rn = meat[w][1][:role_name] #role name
        #puts "..validating #{tn} and #{rn} " 
        if count[tn][rn] != 0 
          # pair tracker/role is not empty. skip it!
          puts "..skipping #{tn} and #{rn} " 
          next
        end

        Workflow.create! meat[w][0] do |nw|
          nw.old_status = IssueStatus.find_by_name meat[w][1][:old_name]
          nw.new_status = IssueStatus.find_by_name meat[w][1][:new_name]
          nw.role = Role.find_by_name meat[w][1][:role_name]
          nw.tracker_id = t.id
        end
      }
    end
  end
end
